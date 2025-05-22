export HADOOP_OS_TYE=${HADOOP_OS_TYPE:-$(uname -s)}
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:$TEZ_HOME/*:$TEZ_HOME/lib/*"