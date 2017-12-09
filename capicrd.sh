#!/bin/bash

# ver 0.0.5
# Script for getting tcpudmp of icrdcap.sh  traffic on ephemeral ports

shopt -s -o nounset
declare -rx SCRIPT=${0##*/}

showUsage() {
    echo "$SCRIPT "
    echo ""
    echo "Will capture all traffic on lo interface ans then fitler down a pcap file on the icrd_child ports"
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            showUsage
            ;;
        *)
            echo "Unknown option: $1"
            showUsage
            ;;
    esac
    shift
done

# create starting icrd_child port list
port_list=`netstat -lnp | grep icrd_child | cut -d ':' -f2 | cut -d " " -f1`
echo -e "starting port_list\n$port_list"

# start capure on loopback
echo "starting capture..."
tcpdump -s0 -ni lo -w /var/tmp/icrdcap.tmp.pcap &>err.log &

capture_pid=`ps aux | grep icrdcap.tmp.pcap | grep -v grep | awk '{print $2}'`
echo "tcpdump pid is $capture_pid"

# check for new ports
while true ; do
    read -t 10 -p  "please enter "x" <ENTER> to quite " x ;
    echo ""
     if [[ $x == "x" ]];
        then
            # kill tcpdump
            kill $capture_pid 
            # break out of loop
            break ; 
                
     fi  ;
# do stuff here while waiting for user to end
port_check=`netstat -lnp | grep icrd_child | cut -d ':' -f2 | cut -d " " -f1`
echo -e "port_list \n$port_list"
echo -e "port_check \n$port_check"
    
echo -e "checking ports..."
# This works
    for n in $port_check; do
        if [[ $port_list == *"$n"* ]]
        then
            :
        else
            echo -e "Adding port $n to port_list"
            port_list="$port_list $n"
        fi    
    done
done
# at this point I need to create a filter based on the port_list and then filter the orgiginal tcpdump down to 
# just the TCP icrd_child ports
echo $port_list




