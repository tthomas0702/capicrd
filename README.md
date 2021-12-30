# capicrd

Scripts to capture icrd_child pcap files on BIG-IP.
The icrd_child handles BIG-IP REST calls that go to /mgmt/tm and /mgmt/net. It can spawn up to 3 instances, and they are they can be torn down and replaced periodically. This script keeps track of ephemeral ports used and starts a tcpdump on the loopback interface. When the user stops the script, it will create a new pcap file by filtering the original capture to just the ephemeral port used by icrd_child during the running and create a new pcap file.
From the technique developed in the script I created a BASH function that can be pasted in the command line. I plan to use that in a KB artcle for t-shooting.
