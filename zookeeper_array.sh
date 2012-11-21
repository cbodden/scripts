#!/bin/bash

####
#
# zookeeper mntr to array
# array values :
# (0) - zk_version
# (1) - zk_avg_latency
# (2) - zk_max_latency
# (3) - zk_min_latency
# (4) - zk_packets_received
# (5) - zk_packets_sent
# (6) - zk_outstanding_requests
# (7) - zk_server_state
# (8) - zk_znode_count
# (9) - zk_watch_count
# (10) - zk_ephemerals_count
# (11) - zk_approximate_data_size
# (12) - zk_open_file_descriptor_count
# (13) - zk_max_file_descriptor_count
# (14) - zk_followers			- only exposed by the Leader
# (15) - zk_synced_followers		- only exposed by the Leader
# (16) - zk_pending_syncs		- only exposed by the Leader
#
####

NETCAT=`which nc`
PORT=2181
SERVER="${1}"
TEMP=/tmp/zktmp.$$
INFO=/tmp/zkinfotmp.$$

#### you should not have to change anything below this line ####

if [[ -z ${NETCAT} ]]; then
    echo "netcat not installed"
    exit 1
fi

if [[ -z ${1} ]]; then
    echo "must include a server to check"
    exit 1
fi

echo 'mntr' | ${NETCAT} ${SERVER} ${PORT} >> ${INFO}
X=0
for array in `awk -F" " '{print $1";"$2}' $INFO`; do
    ARRAYVALUE1=`echo $array | tr ";" " " | awk '{ print $1 }'`
    ARRAYVALUE2=`echo $array | tr ";" " " | awk '{ print $2 }'`
    ZK[$X]=`echo $ARRAYVALUE1 $ARRAYVALUE2`
    X=$(( $X + 1 ))
done
    
echo ${ZK[0]}
echo ${ZK[1]}
echo ${ZK[2]}
echo $X array items
rm -f /tmp/zktmp.$$ && rm -f /tmp/zkinfotmp.$$
