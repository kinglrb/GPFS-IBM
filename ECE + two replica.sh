# ECE+two replica
Two replica需2个recovery group和1个仲裁节点nodec.
#创建两组rg
rg1(n1,n2,n3,n4,n5,n6)，创建操作顺序(rg2同rg1)：创建node class、configure server、create rg；
# 创建文件系统顺序：
在rg1和rg2上define vdiskset、create vdiskset，创建文件系统：-r 2 -m 2是两份replica

# 1.删除文件系统和vdisk-set
#查询挂载
/usr/lpp/mmfs/bin/mmlsmount all -L
#卸载
/usr/lpp/mmfs/bin/mmumount gpfs1 -a
#删除filesystem
/usr/lpp/mmfs/bin/mmvdisk filesystem delete --file-system gpfs1 --confirm
/usr/lpp/mmfs/bin/mmvdisk filesystem list
#删除vdiskset
/usr/lpp/mmfs/bin/mmvdisk vdiskset delete --vdisk-set all
/usr/lpp/mmfs/bin/mmvdisk vdiskset list
#删除vdiskset定义
/usr/lpp/mmfs/bin/mmvdisk vdiskset undefine --vdisk-set vs_1 --confirm
/usr/lpp/mmfs/bin/mmvdisk vdiskset list

# 重新定义和创建vdiskset及文件系统
# 2.quorum  node设置 
#需在n1,n2,n3,n4,n5,n6这6个node里面设置三个quorum node，其他是非quorum的
mmchnode --quorum -N n1,n2,n3; 
mmchnode --non-quorum -N n4,n5,n6
#需在n7,n8,n9,n10,n11,n12这6个node里面设置三个quorum node，其他是非quorum的
mmchnode --quorum -N n7,n8,n9; 
mmchnode --non-quorum -N n10,n11,n12
# 仲裁节点nodeC需要设置成quorum node
nodeC mmchnode --quorum -N nodeC

# 3.创建系统
# 创建node class(n1,n2...为IP地址)
mmvdisk nc create --node-class nc_1 -N n1,n2,n3,n4,n5,n6  
mmvdisk nc create --node-class nc_2 -N n7,n8,n9,n10,n11,n12
# configure server
mmvdisk server configure --nc nc_1
mmvdisk server configure --nc nc_2
mmshutdown -a
mmstartup -a 
# create rg(mmvdisk rg create -h命令帮助)
mmvdisk rg create --rg rg_1 --nc nc_1 -v no
mmvdisk rg create --rg rg_2 --nc nc_2 -v no
# -v指verify，-v no重新塑造,不去pre-check gpfs的log/configuration是否已经存在某个rg
	# recovery-group也有master，master是选举选出来的.查看rg master(结果中，root指rg master server所在的节点)
	mmvdisk rg list --rg rg_1 --server
	mmvdisk rg list --rg rg_2 --server 
	# fs manager可能cache了文件系统属性信息，作为文件系统锁服务器,等等(待确认)
# 在rg1和rg2上define vdiskset
mmvdisk vdiskset define --vdisk-set VdiskSet --recovery-group rg_1,rg_2 --code 4+2P --block-size 4M --set-size 50%
# create vdiskset
mmvdisk vdiskset create --vdisk-set VdiskSet
# 创建文件系统：-r 2 -m 2两份replica
mmvdisk filesystem create --file-system gpfs1 --vdisk-set VdiskSet --mmcrfs -r 2 -m 2

# 4.仲裁节点添加desconly的disk
# 仲裁节点上/tmp/nsd写入(nodec:仲裁节点名，/dev/sdc：仲裁节点里的盘):
vi /tmp/nsd 
%nsd:
servers=nodec
nsd=nodec_sdc
usage=descOnly
device=/dev/sdc
failuregroup=3
#创建nsd
2. /usr/lpp/mmfs/bin/mmcrnsd -F /tmp/nsd -v no
#将gpfs纳入仲裁管辖？
3. /usr/lpp/mmfs/bin/mmadddisk gpfs1 -F /tmp/nsd -v no

# 配置config参数
mmchconfig unmountOnDiskFail=yes -N nodeC
# 在仲裁节点执行
touch  /var/mmfs/etc/ignoreAnyMount.gpfs1

# 5.mount文件系统,然后创建文件验证两份replica(仲裁节点外,任意节点执行)
# 成功标志：
	# metadata replication: 2 max 2
	# data replication:     2 max 2
mmmount gpfs1 -a
cp /etc/hosts /gpfs/gpfs1/test1
mmlsattr -L /gpfs/gpfs1/test1
	# file name:            /gpfs/gpfs1/test1
	# metadata replication: 2 max 2
	# data replication:     2 max 2
	# immutable:            no
	# appendOnly:           no
	# flags:
	# storage pool name:    system
	# fileset name:         root
	# snapshot name:
	# creation time:        Tue Dec 24 12:22:18 2019
	# Misc attributes:      ARCHIVE
	# Encrypted:            no
	
# ----------------------------------------------特殊问题处理------------------------------------------------------------------
#文件系统创建完成后，两组文件系统使用量相差很多，一组使用率接近100%：文件系统挂载后，内部会分配allocation map，格式化gpfs文件系统，3-5分钟格式化完成，会恢复正常	
grep gpfs1 /var/adm/ras/mmfs.log.latest 
# 分别在这两个节点执行
mmdf gpfs1
# 查询文件系统目录大小
du -sh /gpfs/gpfs1/
# lsof(list openfiles)，查看使用/gpfs/gpfs1的进程。如果有进程使用/gpfs/gpfs1，会影响df -h
lsof /gpfs/gpfs1

# 已分组系统重新划分(更新节点)：最好删除和重建recovery-group
# 查询cluster的master(或者manager)节点
mmlsmgr 
# 修改master/manager节点角色?
mmchmgr

# 查询当前版本
mmdiag | grep "GPFS build"

# 集群运行中，某节点关机，重启后，需要
# 在该机器上执行启动：
/usr/lpp/mmfs/bin/mmstartup
# 在任意节点查看状态(关机的机器应为active)：
/usr/lpp/mmfs/bin/mmgetstate -a 
# 所有节点active后查询rg：如果所有DA(Declustered Array)的background task都是“scrub”，则可以正常开展业务。
/usr/lpp/mmfs/bin/mmvdisk recoverygroup list --recovery-group rg_1 --declustered-array
/usr/lpp/mmfs/bin/mmvdisk recoverygroup list --recovery-group rg_2 --declustered-array
# 理论上DA(Declustered Array)的background task为“rebalance”或者“scrub”状态都可开展业务，但是状态为“scrub”更加安全

# 安装5.0.4.0包两种方法：
rpm -ivh 
./spectrumscale

# 单集群掉电后，如果fault tolerance足够(1 node + 1 pdisk),重装一个节点即可
mmvdisk recoverygroup list --recovery-group rg_1 --fault-tolerance -Y | mmyfields diskGroupFaultTolerance
# 如果一组节点全部坏掉或者仲裁节点坏掉，以及恢复之后，数据恢复步骤：IBM

# ------------------------------------------------------------灾备一步步安装-------------------------------
# 集群配置为I2-PF，不支持普通IO9盘创建。普通I2盘，不是I2-PF盘的配置。实例模板在这个集群不支持。
# I2/和I2-PF互斥，其余可以的。直通的NVMe不能再被普通spoold(普通I2)管理。系列三规格太小
# 测试环境：集群12个节点，6个rg_1 nc_1。# node盘大小及数量都一样
# 查看集群.
mmlscluster  
# 在新node上create node class,把n7到n12更改为6个node
mmvdisk nc create --node-class nc_2 -N n7,n8,n9,n10,n11,n12  
# 少包gpfs.gnr.support-scaleout-1.0.0-1.noarch.rpm执行失败，所有scale-out节点都要安装gpfs.gnr.support-scaleout*.rpm
mmvdisk  server configure --nc nc_2
rpm -qa  | grep gpfs
# rpm包位置
/usr/lpp/mmfs/5.0.x.x/gpfs_rpms

# 查询盘能不能被GNR(GPFS Native RAID)发现
mmvdisk server list --disk-topology

mmvdisk server list --node-class nc_2 --disk-topology
# 如needs attention列显示no,说明disk已经被GNR发现
mmvdisk server list --disk-topology  -N  all
	#  node                                       needs    matching
	# number  server                            attention   metric   disk topology
	# ------  --------------------------------  ---------  --------  -------------
	#      1  mestor01.gpfs.net                 no          100/100  ECE 5 HDD

mmvdisk  server configure --nc nc_2
mmshutdown -a
mmstartup -a
#节点全active
mmgetstate -a 

#check
mmvdisk server list --nc nc_2       

mmvdisk rg create --rg rg_2 --nc nc_2 -v no

mmlsnsd

mmvdisk vdiskset define --vdisk-set VdiskSet --recovery-group rg_1,rg_2 --code 4+2P --block-size 4M --set-size 50%
mmvdisk vdiskset create --vdisk-set VdiskSet

mmvdisk filesystem create --file-system gpfs1 --vdisk-set VdiskSet --mmcrfs -r 2 -m 2

mmvdisk vdiskset delete --vdisk-set all

mmvdisk vdiskset define --vdisk-set vs_1 --recovery-group rg_2
mmvdisk vdiskset define --vdisk-set vs_1 --recovery-group rg_2 --code 4+2P --block-size 4M --set-size 50%

mmdefs gpfs1 -p

mmvdisk vdiskset delete --vdisk-set VdiskSet
mmvdisk vdiskset undefine --vdisk-set VdiskSet
#卸载
mmumount gpfs1 -a

echo $?

mmgetstate -a

# 新node需配通ssh passwordless
# 删除vdiskset
/usr/lpp/mmfs/bin/mmumount gpfs1 -a
/usr/lpp/mmfs/bin/mmvdisk filesystem delete --file-system gpfs1 --confirm
/usr/lpp/mmfs/bin/mmvdisk vdiskset delete --vdisk-set all
/usr/lpp/mmfs/bin/mmvdisk vdiskset undefine --vdisk-set vs_1 --confirm

#vdiskset定义及创建
mmvdisk vdiskset define --vdisk-set VdiskSet --recovery-group rg_1,rg_2 --code 4+2P --block-size 4M --set-size 50%
mmvdisk vdiskset create --vdisk-set VdiskSet
#创建文件系统
mmvdisk filesystem create --file-system gpfs1 --vdisk-set VdiskSet --mmcrfs -r 2 -m 2

# 添加仲裁节点nodec及安装所有rpm包
# 仲裁节点上/tmp/nsd写入(nodec:仲裁节点名，/dev/sdc：仲裁节点的盘,注意：/dev/sdc不能是系统盘):
vi /tmp/nsd
%nsd:
# servers=主机名
servers=nodec
# 主机名+sdc
nsd=nodec_sdc
usage=descOnly
device=/dev/sdc
failuregroup=3
#  在仲裁节点上执行
/usr/lpp/mmfs/bin/mmcrnsd -F /tmp/nsd -v no
/usr/lpp/mmfs/bin/mmadddisk gpfs1 -F /tmp/nsd -v no
# ece two replica完成
--------------------------------------------------------------------------------------------------------------------------------------
# DR测试方式
A站点所有节点全部下电(天基上批量关机：ecs的io9集群关机)

# 使用远程连接，不同区域集群可以相互访问
使用mmvdisk删除RG和NC，删除流程跟创建完全相反
# 单站点，如用户数据已写入，不能删除file system。部署单站点，mmvdisk创建文件系统时，使用[--failure-groups  NodeClass=FG[,NodeClass=FG...]] 选项，将单站点的节点都划分到一个FG里。扩充站点时，就不用删除文件系统了。

# 先添加节点，然后创建rg和vdiskset，再把vdiskset加到fs里，加的时候把新的vdiskset指定另外一个fg，大致步骤
# 创建单站点：
1.  mmvdisk nc create --node-class nc_1 -N n1,n2,n3,n4,n5,n6  
2.  mmvdisk server configure --nc nc_1
3.  mmshutdown -a
4.  mmstartup -a 
5.  mmvdisk rg create --rg rg_1 --nc nc_1 -v no
6.  mmvdisk vdiskset define --vdisk-set VdiskSet1 --recovery-group rg_1 --code 4+2P --block-size 4M --set-size 100%
7.  mmvdisk vdiskset create --vdisk-set VdiskSet1
# 8.  mmvdisk filesystem create --file-system gpfs1 --vdisk-set VdiskSet1 --failure-groups rg_1=1 --mmcrfs -r 2 -m 2
# 只有一个站点时，mmvdisk无法将一个站点的所有结点指定到一个failure group里。只能等第二个站点加进来后再修改failure group，然后再同步两个站点之间的数据：
8.  mmvdisk filesystem create --file-system gpfs1 --vdisk-set VdiskSet1 

# 加入第二个站点：
1.  mmaddnode -N n7,n8,n9,n10,n11,n12
2.  mmvdisk nc create --node-class nc_2 -N n7,n8,n9,n10,n11,n12
3.  mmvdisk server configure --nc nc_2
4.  mmshutdown -N n7,n8,n9,n10,n11,n12
5.  mmstartup -N n7,n8,n9,n10,n11,n12
6.  mmvdisk rg create --rg rg_2 --nc nc_2 -v no
7.  mmvdisk vdiskset define --vdisk-set VdiskSet2 --recovery-group rg_2 --code 4+2P --block-size 4M --set-size 100%
8.  mmvdisk vdiskset create --vdisk-set VdiskSet2
# 9.  mmvdisk filesystem add --file-system gpfs1 --vdisk-set VdiskSet2 --failure-groups rg_2=2
# 一个vs只能属于一个fs
9.  mmvdisk filesystem add --file-system gpfs1 --vdisk-set VdiskSet2
10.  mmvdisk filesystem change --file-system gpfs1 --failure-groups nc_1=1,nc_2=2
11.  mmrestripefs gpfs1 -r

# 加入仲裁站点
1.  mmaddnode -N n13
2.  create NSD description file /tmp/nsd for the discOnly disk 
3.  mmcrnsd -F /tmp/nsd -v no
4.  /usr/lpp/mmfs/bin/mmadddisk gpfs1 -F /tmp/nsd -v no
5.  mmchconfig unmountOnDiskFail=yes -N nodeC
# 6.  在仲裁节点执行 
touch  /var/mmfs/etc/ignoreAnyMount.gpfs1

# 同步两个站点之间的数据
mmchfs gpfs1 -r 2 -m 2
mmrestripefs gpfs1 -R

# 注意与ECE+two replica在操作过程上的差异
在ECE环境里，mmvdisk封装了mmcrnsd/mmcrfs等命令，可用mmvdisk创建/删除/查看vdiskset(类似于NSD)、recovery group、文件系统、node class等

mmcrfs创建时就启用双副本，两个站点都启动了才能用。mmchfs后面修改成双副本。单站点时，只有一个rg，只能等第二个站点起来后同步双副本
------------------------------------------------------------------------------------
# gpfs扩容
对已经添加的名为gpfs的文件系统扩容
# 查看文件系统设备名
ls /dev/gpfs
# 1、添加新节点
# mmaddnode -N g4:client
mmaddnode -N g4:manager
# 2、对新节点授权license
# mmchlicense client --accept -N g4
mmchlicense server --accept -N g4
# 3、将新节点的磁盘添加到nsd中
# 编辑
vi addnsdfile.cfg
%pool: pool=system blockSize=512K layoutMap=cluster
%pool: pool=datapool blockSize=2M layoutMap=cluster writeAffinityDepth=1 blockGroupFactor=256
%nsd: device=/dev/vdb servers=g4 nsd=datansd04 usage=dataOnly pool=datapool
# %nsd:nsd=cfs_ibm01_ndisk9 device=/dev/sdb servers=ibm01 usage=dataAndMetadata  failureGroup=101 pool=system
# 添加nsd
mmcrnsd -F  addnsdfile.cfg
# 4、启动g4节点
mmstartup -N g4
# 5、扩容文件系统，将新增的nsd添加到文件系统中
mmadddisk gpfs -F addnsdfile.cfg
# 6、平衡数据
mmrestripefs gpfs -b
-------------------------------------------------------------------------------------