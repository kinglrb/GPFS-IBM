#部署要求
主A6备B6仲裁B1
14、16、6.17  #暂不执行
# 客户端不用装gpfs文件系统和恢复组
# 检查各节点网络联通性：只需要在集群任意一台执行即可
mmnetverify --configuration-file nodelist.client

# 查询结果中，列表nodename需要改成当前节点name
./spectrumscale node list
#使用语句改
./spectrumscale node clear

#添加节点，在主
mmaddnode -N IP,IPlist  
#不执行，启动报错。新加入节点执行，使节点可查看集群信息
mmbuildgpl
#启动
mmstartup -a
#集群状态查询
mmgetstate -a
#状态查询时，不显示文首报警信息
mmchlicense server --accept -N all
# -------------------------------------------------------------------------------------------------------------------------------
# 基于cpfs-image 镜像创建的实例

ssh 118.36.0.215
# B01上操作，yum配置在A01(192.168.1.246)
# 配置YUM源
cd /root
vim centos-local.repo
	[centos-local]
	name=centos-local
	baseurl=http://192.168.1.246:/
	gpgcheck=0
	enabled=1
#推送配置文件
# IP=192.168.1.250
# scp centos-local.repo $IP:/etc/yum.repos.d/



sfIP=192.168.1.250
ssh $sfIP
# 新节点操作
#变量
B01IP=192.168.2.14
echo $B01IP
nm=a05

# 备份YUM源
cd /etc/yum.repos.d/
rename .repo .repo.bak *
#拉取yum配置
cd ~
pwd
scp  root@$B01IP:/root/centos-local.repo /etc/yum.repos.d/
# scp  root@$B01IP:/etc/yum.repos.d/centos-local.repo /etc/yum.repos.d/
# 清除YUM缓冲
yum clean all
# 列出可用的YUM源
yum repolist

# 获取节点IP、hostname
nameIP=`hostname -i`" "`hostname`
echo $nameIP > $nm.host
cat $nm.host
#汇总
scp $nm.host root@$B01IP:/root/cpfs-host

# 节点密钥(改为nodelist方式先拉后推再群发更好)：
ssh-keygen -t rsa
cat /root/.ssh/id_rsa.pub > $nm.ssh
cat $nm.ssh
# 汇总
scp $nm.ssh root@$B01IP:/root/cpfs-ssh/

# nodelist
sfIP=`hostname -i`
ndIP="node"" "$sfIP
echo $ndIP
scp  root@192.168.2.14:/root/nodelist.client /root
# cat nodelist.client
echo $ndIP >> nodelist.client
cat nodelist.client
scp  nodelist.client root@192.168.2.14:/root/

# 循环IP
scp  root@192.168.2.14:/root/ip_list /root
echo $sfIP >> ip_list
cat ip_list
scp  ip_list root@192.168.2.14:/root/

# 修改sshd配置文件
# vi /etc/ssh/ssh_config
	# 将 StrictHostKeyChecking 改为 no
sed -i s/"#   StrictHostKeyChecking ask"/"StrictHostKeyChecking no"/ /etc/ssh/ssh_config
awk -F: '/StrictHostKeyChecking/' /etc/ssh/ssh_config



ssh 118.36.0.215
#master操作B01
nm=a05
sfIP=192.168.1.250
# 修改"/etc/hosts"
cd /root/cpfs-host
ls
cat $nm.host 
cat $nm.host >> host.cpfs
cat host.cpfs
cat host.cpfs > /etc/hosts
cat /etc/hosts
#钥匙
cd /root/cpfs-ssh/
ls
cat $nm.ssh 
cat $nm.ssh >> ssh.cpfs
cat ssh.cpfs
cat ssh.cpfs > /root/.ssh/authorized_keys
cat /root/.ssh/authorized_keys
# 钥匙及host分别传至各节点
cd ~
# scp cpfs-host/host.cpfs   root@$sfIP:/root/
# scp cpfs-ssh/ssh.cpfs   root@$sfIP:/root/
# awk ‘BEGIN{for(i=1; i<=10; i++) print i}’
	# function forPush() {
		# for line in `cat /root/$ip_list`
		# do
		  # echo $line
		# done
	# }
	# forPush ip_list

for ip in `cat ip_list`
do
	echo $ip
	scp /root/.ssh/authorized_keys   root@$ip:/root/.ssh/authorized_keys
	scp /etc/hosts   root@$ip:/etc/hosts  
	scp /root/ip_list root@$ip:/root/
	scp /root/nodelist.client root@$ip:/root/
done



ssh $sfIP
# 节点操作
#变量
B01IP=192.168.2.14
echo $B01IP
nm=a05
	# 免密
	# cat ssh.cpfs > .ssh/authorized_keys
	# cat .ssh/authorized_keys
	# cat host.cpfs > /etc/hosts
	# cat /etc/hosts
# 重启sshd
service sshd restart

# 检查NVMe磁盘
nvme list

# 检查和安装GPFS依赖包
# 拉取依赖包
scp  root@192.168.2.14:/root/gpfs_rpm.tar.gz /root/
#解压
cd ~
pwd
tar -xvf gpfs_rpm.tar.gz
#安装
cd  gpfs_rpm
	# rpm -ivh gpfs.adv-5.0.4-0.x86_64.rpm
	# rpm -ivh gpfs.base-5.0.4-0.x86_64.rpm
	# rpm -ivh gpfs.gskit-8.0.50-86.x86_64.rpm
	# rpm -ivh gpfs.nfs-ganesha-2.7.5-ibm053.00.el7.x86_64.rpm
	# rpm -ivh gpfs.nfs-ganesha-gpfs-2.7.5-ibm053.00.el7.x86_64.rpm
	# rpm -ivh gpfs.nfs-ganesha-utils-2.7.5-ibm053.00.el7.x86_64.rpm
	# rpm -ivh gpfs.gss.pmcollector-5.0.4-0.el7.x86_64.rpm
	# rpm -ivh gpfs.gss.pmsensors-5.0.4-0.el7.x86_64.rpm
	# rpm -ivh gpfs.pm-ganesha-10.0.0-1.el7.x86_64.rpm
	# rpm -ivh gpfs.java-5.0.4-0.x86_64.rpm gpfs.gui-5.0.4-0.noarch.rpm
	# rpm -ivh gpfs.gpl-5.0.4-0.noarch.rpm
	# rpm -ivh gpfs.license.ec-5.0.4-0.x86_64.rpm
	
	# rpm -ivh sg3_utils-libs-1.37-18.el7_7.1.x86_64.rpm
	# rpm -ivh sg3_utils-1.37-18.el7_7.1.x86_64.rpm

# rpm -ivh gpfs.adv* gpfs.base* gpfs.gskit* gpfs.nfs* gpfs.gss* gpfs.pm* gpfs.java* gpfs.gpl* gpfs.license* sg3_utils-libs* sg3_utils-1.37*
rpm -qa | grep gpfs
rpm -qa | grep sg3

# 6、配置NTP服务（搭个ntp server）（不需要操作）
# 7、执行 mor.py 和 mor_overview.py 脚本（precheck 部分，不需要操作）
# 8、执行网络预检查（precheck 部分，不需要操作）
# 9、设置 sysctl 参数
cd ~
./sysctl.sh

# 10、安装 ECE(与rpm安装等效)
sfIP=`hostname -i`
echo $sfIP
cd /usr/lpp/mmfs/5.0.4.0/installer/
./spectrumscale setup -s $sfIP -st ece

# 11、设置PATH变量
# vi /etc/profile
	# 在开头部分加入:export PATH="$PATH:/usr/lpp/mmfs/bin"
	# touch test
	# sed -i '/\/etc\/profile/a\export PATH="$PATH:\/usr\/lpp\/mmfs\/bin"' test
# sed -i '/\/etc\/profile/a\export PATH="$PATH:\/usr\/lpp\/mmfs\/bin' /etc/profile
scp root@192.168.1.250:/root/profile.bak /root/
mv /etc/profile /etc/profile.bak
cp /root/profile.bak /etc/profile
head -20 /etc/profile
source /etc/profile


# 12、 检查各节点网络联通性(任意节点检查)
# 配置结点文件 "nodelist.client"
# vi nodelist.client
	# 格式：node ip
	# ndIP="node"" "$sfIP
	# echo $ndIP
	# scp  root@192.168.2.14:/root/nodelist.client /root
	# cat nodelist.client
	# echo $ndIP >> nodelist.client
	# cat nodelist.client
	# scp  nodelist.client root@192.168.2.14:/root/
# 检查网络连通性
mmnetverify --configuration-file nodelist.client

# 13、显示群集(定义文件hosts?中)节点列表
cd /usr/lpp/mmfs/5.0.4.0/installer/
./spectrumscale node list
./spectrumscale node clear
# ------------------------------------------------client安装结束--------
# 14、安装 gpfs 包、创建 gpfs 群集并创建 ECE 恢复组
./spectrumscale install 1 --skip no-ece-check
# 直到缺少安装kafka依赖包失败，无需安装。



# 15、创建集群()
#添加节点，在已加入集群中的任何节点执行
# mmaddnode -N IP,IPlist
mmaddnode -N $sfIP  --accept

#新节点执行
#编译gpfs内核.新加入节点执行，使节点可查看集群信息.不执行，启动报错。
mmbuildgpl
#授权后，状态查询时，不显示文首报警信息
mmchlicense server --accept -N all
#启动
mmstartup -a
#集群状态查询
mmgetstate -a
	# mmcrcluster -N nodenodeDesc.client -A
	# mmchlicense server --accept -N all
	# mmlscluster
	# mmgetstate -a
	# mmstartup -a
	# mmgetstate -a
	# 修改集群名称
	# mmchcluster -C ClusterName 
	
# 16、创建恢复组
	# ./spectrumscale recoverygroup clear
	# ./spectrumscale recoverygroup define -rg rg_1 -nc nc_1 -N al
	# mmvdisk nodeclass create --node-class nc_1 -N all
	# mmvdisk server configure --node-class nc_1
	# mmshutdown -a
	# mmstartup -a
	# mmgetstate -a
	# 等待所有node变成active
	# mmvdisk recoverygroup create --recovery-group rg1 --node-class nc1 -v no
	# mmvdisk nodeclass list
	# mmlsrecoverygroup
	# mmlsnodeclass
	
# 17、参数调优
# （1）配置参数
mmchconfig maxMBpS=24000
mmchconfig verbsRdmaSend=yes
mmchconfig workerThreads=1024
mmchconfig pagepool=485G
mmchconfig readReplicaPolicy=local
mmchconfig unmountOnDiskFail=meta
mmchconfig restripeOnDiskFailure=yes
mmchconfig nsdThreadsPerQueue=10
mmchconfig nsdMinWorkerThreads=48
mmchconfig prefetchAggressivenessWrite=0
mmchconfig prefetchAggressivenessRead=2
mmchconfig nsdInlineWriteMax=1000000
mmchconfig nsdSmallThreadRatio=2
mmchconfig nsdThreadsPerDisk=16
#一次调优
mmchconfig maxMBpS=24000,verbsRdmaSend=yes,workerThreads=1024,pagepool=485G,readReplicaPolicy=local,unmountOnDiskFail=meta,restripeOnDiskFailure=yes,nsdThreadsPerQueue=10,nsdMinWorkerThreads=48,prefetchAggressivenessWrite=0,prefetchAggressivenessRead=2,nsdInlineWriteMax=1000000,nsdSmallThreadRatio=2,nsdThreadsPerDisk=16
# （2）重启生效
mmshutdown -a
mmstartup -a
# 状态需要全active
mmgetstate -a 
mmlsconfig

# 6.17 安装 gpfs 文件系统
# 先添加节点，然后创建rg和vdiskset，再把vdiskset加到fs里，加的时候把新的vdiskset指定一个fg
mmvdisk vs list --vs all
mmvdisk recoverygroup create --recovery-group rg_1 --node-class nc_1 -v no
mmvdisk vdiskset list --vdisk-set all
mmvdisk vs define --vs vs_1 --rg rg_1 --code 4+2p --bs 4M --ss 100% --da DA1 --nsd-usage dataAndMetadata --sp system
mmvdisk vs create --vs vs_1
mmvdisk fs create --fs gpfs1 --vs vs_1
mmvdisk fs list
mmmount all -a
mmlsmount all -L
df -h
# ------------------------------------------------------------------------------------------------------------------------