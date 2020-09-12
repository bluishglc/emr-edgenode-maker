
# 脚本使用方法

**关于该脚本的详细介绍，请参考作者博客文章：[如何制作一个AWS EMR客户端节点（ Client Node / Edge Node / Gateway Node )]（https://laurence.blog.csdn.net/article/details/108529087）**

检出后需要先给shell文件`make-emr-edge-node.sh`添加可执行属性：

```bash
chmod a+x make-emr-edge-node.sh
```

然后可以通过help选项查看使用方式：

```bash
sudo ./make-emr-edge-node.sh help

==================  [ MAKE EMR EDGE NODE SCRIPTS ] USAGE  ==================

# 说明：初始化（只需执行一次）, 安装基础软件包，emr基础app, 配置emr repo, 创建hadoop用户, 创建必要文件夹
./make-emr-edge-node.sh init [PEM_FILE_PATH] [MASTER_NODE_IP]

# 说明：制作hadoop客户端
./make-emr-edge-node.sh make-hadoop-client [PEM_FILE_PATH] [MASTER_NODE_IP]

# 说明：制作spark客户端
./make-emr-edge-node.sh make-spark-client [PEM_FILE_PATH] [MASTER_NODE_IP]

# 说明：制作hive客户端
./make-emr-edge-node.sh make-hive-client [PEM_FILE_PATH] [MASTER_NODE_IP]

# 说明：制作hbase客户端
./make-emr-edge-node.sh make-hbase-client [PEM_FILE_PATH] [MASTER_NODE_IP]

# 说明：制作oozie客户端
./make-emr-edge-node.sh make-oozie-client [PEM_FILE_PATH] [MASTER_NODE_IP]

# 说明：制作hudi客户端
./make-emr-edge-node.sh make-hudi-client

# 说明：制作sqoop客户端
./make-emr-edge-node.sh make-sqoop-client

```

关于脚本的使用方式，如下几点需要注意：

1. 由于脚本中大量操作需要使用root权限，所以必须以root用户或sudo方式运行脚本，否则脚本会给出错误提示
2. 命令行中只涉及两个参数：
- [PEM_FILE_PATH] ：你的AWS账号的PEM文件，执行脚本需要使用该秘钥文件登入Master节点拷贝配置文件；
- [MASTER_NODE_IP]：你的Master节点IP或域名
3. 在执行`make-*-client`操作前，需要先执行`init`操作（仅一次即可）