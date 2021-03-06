#!/bin/bash

# ver 0.1.0
# Script for getting tcpudmp of icrdcap.sh  traffic on ephemeral ports

shopt -s -o nounset
declare -rx SCRIPT=${0##*/}
remove_open_cap=0

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

# Start a loop waiting for user to end. Check for new port in loop
# if user enters "x" break out of loop and stop tcpdump
while true ; do
    read -t 10 -p  "Enter "x" <ENTER> to quite " x ;
    echo ""
     if [[ $x == "x" ]];
        then
            echo -e "killing tcpdump pid $capture_pid"
            kill $capture_pid 
            break ; 
     fi  ;
    # check for new ports while in loop
    port_check=`netstat -lnp | grep icrd_child | cut -d ':' -f2 | cut -d " " -f1`
    echo -e "\nAll ports used: \n$port_list"
    echo -e "Current ports in use: \n$port_check"
    
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

# now that out of loop filter wide open capture based on ports used
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

display_filter="port ( $filter_ports )"
echo -e "tcpdump diplay filter: $display_filter"
capture_name="/var/tmp/icrd_`date +"%F-%H_%M_%S"`.pcap"
tcpdump -r /var/tmp/icrdcap.tmp.pcap $display_filter -w $capture_name &>>err.log & 

if (( $remove_open_cap == 1 )); then
    echo -e "removing wide open loopback cpap file /var/tmp/icrdcap.tmp.pcap"
    rm -i /var/tmp/icrdcap.tmp.pcap
    echo -e "Final file created:\n $capture_name\n"
else
    echo -e "Files created:\n/var/tmp/icrdcap.tmp.pcap\n$capture_name\n"
fi


