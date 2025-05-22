FROM ubuntu:22.04 AS base

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

RUN apt update -y
RUN apt upgrade -y 
RUN apt install -y openjdk-8-jdk
RUN apt install -y ssh
RUN apt install sudo

ENV HADOOP_HOME=/usr/local/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV PATH=$PATH:/usr/local/zookeeper/bin/

ENV TEZ_HOME=/usr/local/tez
ENV PATH=$PATH:$TEZ_HOME/bin

RUN addgroup hadoop 
RUN adduser --disabled-password --ingroup hadoop hadoop

ADD https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz /tmp
RUN tar -xzf /tmp/hadoop-3.3.6.tar.gz -C /usr/local/
RUN mv /usr/local/hadoop-3.3.6 $HADOOP_HOME
RUN chown -R hadoop:hadoop $HADOOP_HOME
ADD https://downloads.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz /tmp
RUN tar -xzf /tmp/apache-zookeeper-3.8.4-bin.tar.gz -C /usr/local/
RUN mv /usr/local/apache-zookeeper-3.8.4-bin /usr/local/zookeeper
RUN chown -R hadoop:hadoop /usr/local/zookeeper


RUN echo 'hadoop ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER hadoop
WORKDIR /home/hadoop
RUN ssh-keygen -t rsa -P "" -f /home/hadoop/.ssh/id_rsa
RUN cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys
RUN chmod 600 /home/hadoop/.ssh/authorized_keys

COPY hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh
COPY core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
COPY mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
COPY yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
COPY workers $HADOOP_HOME/etc/hadoop/workers
COPY zoo.cfg /usr/local/zookeeper/conf/zoo.cfg  
RUN mkdir /usr/local/zookeeper/data
COPY start.sh /home/hadoop/start.sh
RUN sudo chmod +x /home/hadoop/start.sh
ENTRYPOINT [ "/home/hadoop/start.sh" ]

FROM base AS hbase

ENV HBASE_HOME=/usr/local/hbase
ENV PATH=$HBASE_HOME/bin:$PATH

USER root

# Copy the HBase binary tarball into the container
ADD https://archive.apache.org/dist/hbase/2.4.9/hbase-2.4.9-bin.tar.gz /usr/local/

RUN tar -xvzf /usr/local/hbase-2.4.9-bin.tar.gz -C /usr/local && \
    mv /usr/local/hbase-2.4.9 /usr/local/hbase && \
    rm /usr/local/hbase-2.4.9-bin.tar.gz && \
    chown -R hadoop:hadoop /usr/local/hbase
COPY start-hbase.sh /home/hadoop/start-hbase.sh
RUN chmod +x /home/hadoop/start-hbase.sh

USER hadoop

# Copy hbase-site.xml config
COPY hbase-site.xml $HBASE_HOME/conf/hbase-site.xml

# Copy Hadoop common libs to HBase lib
RUN cp $HADOOP_HOME/share/hadoop/common/lib/* $HBASE_HOME/lib/

WORKDIR /home/hadoop

ENTRYPOINT ["/home/hadoop/start-hbase.sh"]