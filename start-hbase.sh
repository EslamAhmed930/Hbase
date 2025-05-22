#!/bin/bash

if [[ $HOSTNAME == hm* ]]; then
    sleep 10
    if ! hdfs dfs -test -d /hbase; then
        hdfs dfs -mkdir -p /hbase
        hdfs dfs -chown -R hadoop:hadoop /hbase
    fi
  $HBASE_HOME/bin/hbase master start &

elif [[ $HOSTNAME == hr* ]]; then
    sleep 10
    hdfs --daemon start datanode
    yarn --daemon start nodemanager
    $HBASE_HOME/bin/hbase-daemon.sh start regionserver &

fi

     
sleep infinity 