#!/bin/bash 

# Start SSH service (required for cluster communication)
sudo service ssh start 

# Check if this is a master node
if hostname | grep -q 'master'
then 
    # Start JournalNode (for HA)
    hdfs --daemon start journalnode 
    
    # Configure and start ZooKeeper
    ID=$(hostname | tail -c 2)
    echo $ID > /usr/local/zookeeper/data/myid 
    zkServer.sh start
    
    # Format HDFS if this is master1 (primary namenode)
    if [ $ID -eq 1 ]
    then
        hdfs namenode -format
        hdfs zkfc -formatZK
    else
        # For standby namenode, wait until the primary NameNode is healthy
        while true; do
        hdfs haadmin -checkHealth nn1
        if [ $? -eq 0 ]; then
            echo "Primary NameNode is healthy. Proceeding with bootstrap."
            break
        else
            echo "Primary NameNode is not healthy. Retrying in 5 seconds."
            sleep 5
        fi
        done    
        hdfs namenode -bootstrapStandby    
    fi
    
    # Start master services
    hdfs --daemon start namenode
    hdfs --daemon start zkfc
    yarn --daemon start resourcemanager  # Fixed: yarn command instead of hdfs

    # Give services time to stabilize
    sleep 20
else
    # Worker node services
    hdfs --daemon start datanode
    yarn --daemon start nodemanager  # Fixed: yarn command instead of hdfs
fi      

# Keep container running
sleep infinity