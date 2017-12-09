# capicrd

Scripts to capture icrd_child pcap files on BIG-IP.

The icrd_child handles BIG-IP REST calls that go to /mgmt/tm and /mgmt/net. It can spawn up to 3 instances, and they are they can be torn down and replaced periodically. This is a script to keep track of ephemeral ports used and start a tcpdump on the loopback interface. When user stop script it will create a new pcap file by filtering the original capture to just the ephemeral port used by icrd_child during the running and create a new pcap file from that. 

Another goal is to try and create a one-liner that can be cut and pasted to do the same this as the script. 
