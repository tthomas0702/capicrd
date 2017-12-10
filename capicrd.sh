#!/bin/bash

# ver 0.0.7
# Script for getting tcpudmp of icrdcap.sh  traffic on ephemeral ports

shopt -s -o nounset
declare -rx SCRIPT=${0##*/}

showUsage() {
    echo "$SCRIPT "
    echo ""
    echo "Capture all traffic on lo interface and then fitler down a pcap file on the icrd_child ports"
    echo "    -r|--remove - removes the wide open capture file of all lo traffic, default is to leave it"
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            showUsage
            ;;
        -r|--remove)
            remove_open_cap=1
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
capture_pid=$!
echo "tcpdump pid is $capture_pid"

# Start a loop waitign for user to end. Check for new port in loop
while true ; do
    read -t 10 -p  "please enter "x" <ENTER> to quite " x ;
    echo ""
     if [[ $x == "x" ]];
        then
            # kill tcpdump
            echo -e "killing tcpdump $capture_pid"
            kill $capture_pid 
            # break out of loop
            break ; 
                
     fi  ;
    # do stuff here while waiting for user to end
    port_check=`netstat -lnp | grep icrd_child | cut -d ':' -f2 | cut -d " " -f1`
    echo -e "port_list \n$port_list"
    echo -e "port_check \n$port_check"
    
    echo -e "checking ports..."
    # Check if port in port_check are in port_list, if not add to port_list
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
# Create a filter based on the port_list ports

#echo $port_list

# create array of ports so I can tell when on the last port in array
declare -a port_array
filter_ports=""
port_array=( $port_list )
pos=$(( ${#port_array[*]} - 1 ))
last=${port_array[$pos]}

# format list with "or" in between ports
for PORT in "${port_array[@]}"; do 
    if [[ $PORT == $last ]]
    then
        #echo "$PORT is the last" 
        filter_ports="$filter_ports$PORT "
        break
    else 
        #echo "$PORT"
        filter_ports="$filter_ports$PORT or "
    fi 
done 

#echo "filter_ports is $filter_ports"
display_filter="port ( $filter_ports )"
echo -e "tcpdump diplay filter: $display_filter"

# Filter orignal wide open loopback capture to just icrd_child ports
tcpdump -r /var/tmp/icrdcap.tmp.pcap $display_filter -w /var/tmp/final.pcap 

######## 
# to do ... create better file name above and delete loopback file, give ending message showing file created
#######
