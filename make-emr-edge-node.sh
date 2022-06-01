#!/bin/sh

# Run the below commands as root
if [ "$USER" != "root" ]; then
  echo "Run me with root user!"
  exit 1
fi

showUsage() {
  printHeading "[ MAKE EMR EDGE NODE SCRIPTS ] USAGE"

  echo "# 说明：初始化（只需执行一次）, 安装基础软件包，emr基础app, 配置emr repo, 创建hadoop用户, 创建必要文件夹"
  echo "$0 init [PEM_FILE_PATH] [MASTER_NODE_IP]"
  echo

  echo "# 说明：制作hadoop客户端"
  echo "$0 make-hadoop-client [PEM_FILE_PATH] [MASTER_NODE_IP]"
  echo

  echo "# 说明：制作spark客户端"
  echo "$0 make-spark-client [PEM_FILE_PATH] [MASTER_NODE_IP]"
  echo

  echo "# 说明：制作hive客户端"
  echo "$0 make-hive-client [PEM_FILE_PATH] [MASTER_NODE_IP]"
  echo

  echo "# 说明：制作hbase客户端"
  echo "$0 make-hbase-client [PEM_FILE_PATH] [MASTER_NODE_IP]"
  echo

  echo "# 说明：制作oozie客户端"
  echo "$0 make-oozie-client [PEM_FILE_PATH] [MASTER_NODE_IP]"
  echo

  echo "# 说明：制作hudi客户端"
  echo "$0 make-hudi-client"
  echo

  echo "# 说明：制作sqoop客户端"
  echo "$0 make-sqoop-client"
  echo
}

printHeading() {
  title="$1"
  paddingWidth=$((($(tput cols) - ${#title}) / 2 - 3))
  printf "\n%${paddingWidth}s" | tr ' ' '='
  printf "  $title  "
  printf "%${paddingWidth}s\n\n" | tr ' ' '='
}

init() {
  pemFile="$1"
  masterNode="$2"
  chmod 600 "$pemFile"
  makeYumRepo "$pemFile" "$masterNode"
  yum -y install vim wget zip unzip expect tree htop iotop nc telnet lrzsz openssl-devel emrfs emr-ddb emr-goodies emr-kinesis emr-s3-select emr-scripts
  makeHadoopUser "$pemFile"
  makeDir
  makeJdk
  echo "Plase REBOOT!!"
}

makeUser() {
  # add group if not exists
  user="$1"
  group="$2"

  egrep "^$group\:" /etc/group >&/dev/null
  if [ "$?" != "0" ]; then
    groupadd "$group"
    echo "Group: $group is added."
  fi

  # add user if not exists and set password
  egrep "^$user\:" /etc/passwd >&/dev/null
  if [ "$?" != "0" ]; then
    useradd -g "$group" "$user"
    echo "User: $user is added."
  fi
  # enable all users of bdp group can as hdfs.
  echo "$user ALL = (ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/hadoop
}

makeHadoopUser() {
  makeUser "hadoop" "hadoop"
  mkdir -p /home/$user/.ssh
  chown $user:$group /home/$user/.ssh
  chmod 700 /home/$user/.ssh
  cp $pemFile /home/$user/.ssh/id_isa
  chown $user:$group /home/$user/.ssh/id_isa
  chmod 600 /home/$user/.ssh/id_isa
}

makeYumRepo() {
  pemFile="$1"
  masterNode="$2"
  scp -o StrictHostKeyChecking=no -i $pemFile hadoop@$masterNode:/etc/yum.repos.d/emr-apps.repo .
  mv emr-apps.repo /etc/yum.repos.d/emr-apps.repo
  scp -o StrictHostKeyChecking=no -i $pemFile hadoop@$masterNode:/etc/yum.repos.d/emr-platform.repo .
  mv emr-apps.repo /etc/yum.repos.d/emr-platform.repo
  scp -o StrictHostKeyChecking=no -i $pemFile hadoop@$masterNode:/var/aws/emr/repoPublicKey.txt .
  mkdir -p /var/aws/emr/
  mv repoPublicKey.txt /var/aws/emr/repoPublicKey.txt
}

makeDir() {
  mkdir -p /mnt/s3
  chmod 777 -R /mnt/s3
  mkdir -p /mnt/tmp
  chmod 777 -R /mnt/tmp
}

makeJdk() {
  yum -y install java-1.8.0-openjdk
  tee /etc/profile.d/java.sh <<EOF
export JAVA_HOME=/etc/alternatives/jre
export PATH=$JAVA_HOME/bin:$PATH
EOF
}

makeHadoopClient() {
  pemFile="$1"
  masterNode="$2"
  yum -y install hadoop-client hadoop-lzo
  rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -i $pemFile" hadoop@$masterNode:'/etc/hadoop/conf/*' /etc/hadoop/conf
}

makeHiveClient() {
  pemFile="$1"
  masterNode="$2"
  yum -y install tez hive hive-hcatalog
  rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -i $pemFile" hadoop@$masterNode:'/etc/hive/conf/*' /etc/hive/conf
  rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -i $pemFile" hadoop@$masterNode:'/etc/hive-hcatalog/conf/*' /etc/hive-hcatalog/conf
  rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -i $pemFile" hadoop@$masterNode:'/etc/tez/conf/*' /etc/tez/conf
  mkdir -p /var/log/hive/user
  chmod 777 -R /var/log/hive/user
}

makeSparkClient() {
  pemFile="$1"
  masterNode="$2"
  yum -y install spark-core spark-python spark-datanucleus emr-goodies-spark spark-external hudi-spark
  rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -i $pemFile" hadoop@$masterNode:'/etc/spark/conf/*' /etc/spark/conf
  echo "spark.hadoop.yarn.timeline-service.enabled false" | tee -a /etc/spark/conf/spark-defaults.conf
  mkdir -p /var/log/spark/user
  chmod 777 -R /var/log/spark/user
}

makeHBaseClient() {
  pemFile="$1"
  masterNode="$2"
  yum -y install hbase
  rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -i $pemFile" hadoop@$masterNode:'/etc/hbase/conf/*' /etc/hbase/conf
  mkdir -p /var/log/hbase
  chmod 777 -R /var/log/hbase
}

makeHudiClient() {
  yum -y install hudi
}

makeSqoopClient() {
  yum -y install sqoop
}

makeOozieClient() {
  pemFile="$1"
  masterNode="$2"
  yum -y install oozie # if install oozie-client only, oozie user won't create automatically.
  rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -i $pemFile" hadoop@$masterNode:'/etc/oozie/conf/*' /etc/oozie/conf
  mkdir -p /var/log/oozie
  chmod 777 -R /var/log/oozie
}

case $1 in
  init)
    shift
    init "$@"
    ;;
  make-hadoop-user)
    shift
    makeHadoopUser "$@"
    ;;
  make-hadoop-client)
    shift
    makeHadoopClient "$@"
    ;;
  make-hive-client)
    shift
    makeHiveClient "$@"
    ;;
  make-spark-client)
    shift
    makeSparkClient "$@"
    ;;
  make-hbase-client)
    shift
    makeHBaseClient "$@"
    ;;
  make-oozie-client)
    shift
    makeOozieClient "$@"
    ;;
  make-hudi-client)
    makeHudiClient
    ;;
  make-sqoop-client)
    makeSqoopClient
    ;;
  help)
    showUsage
    ;;
  *)
    showUsage
    ;;
esac
