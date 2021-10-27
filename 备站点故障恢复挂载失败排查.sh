# 备站点故障，主站点挂载文件系统失败
# 系统恢复,逐项检查

mmgetstate -a
# Node number  Node name        GPFS state
# -------------------------------------------
       # 1      vmnm            active
vmm
mmlscluster
# GPFS cluster information
# ========================
  # GPFS cluster name:         DebbyTest.vmnm
  # GPFS cluster id:           125
  # GPFS UID domain:           DebbyTest.vmnm
  # Remote shell command:      /usr/bin/ssh
  # Remote file copy command:  /usr/bin/scp
  # Repository type:           CCR

 # Node  Daemon node name         IP address     Admin node name          Designation
# ------------------------------------------------------------------------------------
   # 1   vmnm                    192.168.2.14       vmnm                quorum-manager-perfmon


mmvdisk nc  list --nc nc_1
# node class  recovery groups  member nodes
# ----------  ---------------  ------------
# nc_1        rg_1             vmnm,

# node class  recovery groups  member nodes
# ----------  ---------------  ------------
# nc_2        rg_2             vmnm,

mmlsfs all
# File system attributes for /dev/gpfs1:
# ======================================
# flag                value                    description
# ------------------- ------------------------ -----------------------------------
 # -f                 8192                     Minimum fragment (subblock) size in bytes
 # -i                 4096                     Inode size in bytes
 # -I                 32768                    Indirect block size in bytes
 # -m                 2                        Default number of metadata replicas
 # -M                 2                        Maximum number of metadata replicas
 # -r                 2                        Default number of data replicas
 # -R                 2                        Maximum number of data replicas
 # -j                 scatter                  Block allocation type
 # -D                 nfs4                     File locking semantics in effect
 # -k                 all                      ACL semantics in effect
 # -n                 32                       Estimated number of nodes that will mount file system
 # -B                 4194304                  Block size
 # -Q                 none                     Quotas accounting enabled
                    # none                     Quotas enforced
                    # none                     Default quotas enabled
 # --perfileset-quota No                       Per-fileset quota enforcement
 # --filesetdf        No                       Fileset df enabled?
 # -V                 22.00 (5.0.4.0)          File system version
 # --create-time      Wed Dec 25 10:32:38 2019 File system creation time
 # -z                 No                       Is DMAPI enabled?
 # -L                 33554432                 Logfile size
 # -E                 Yes                      Exact mtime mount option
 # -S                 relatime                 Suppress atime mount option
 # -K                 whenpossible             Strict replica allocation option
 # --fastea           Yes                      Fast external attributes enabled?
 # --encryption       No                       Encryption enabled?
 # --inode-limit      68671488                 Maximum number of inodes
 # --log-replicas     0                        Number of log replicas
 # --is4KAligned      Yes                      is4KAligned?
 # --rapid-repair     Yes                      rapidRepair enabled?
 # --write-cache-threshold 0                   HAWC Threshold (max 65536)
 # --subblocks-per-full-block 512              Number of subblocks per full block
 # -P                 system                   Disk storage pools in file system
 # --file-audit-log   No                       File Audit Logging enabled?
 # --maintenance-mode No                       Maintenance Mode enabled?
 # -d                 
 # -A                 yes                      Automatic mount option
 # -o                 none                     Additional mount options
 # -T                 /gpfs/gpfs1              Default mount point
 # --mount-priority   0                        Mount priority

mmlsdisk gpfs1 -L
# disk         driver   sector     failure holds    holds                                    storage
# name         type       size       group metadata data  status        availability disk id pool         remarks
# ------------ -------- ------ ----------- -------- ----- ------------- ------------ ------- ------------ ---------
# RG001LG001VS001 nsd         512           1 Yes      Yes   ready         up                 1 system        desc

# vmnm_nvme1n1 nsd         512           3 No       No    ready         up                25 system        desc
# Number of quorum disks: 3
# Read quorum value:      2
# Write quorum value:     2

mmvdisk rg list --rg rg_1 --lg --vdisk
# log group  user vdisks  log vdisks  server
# ---------  -----------  ----------  ------
# root                 0           1  vmnm
# LG001                1           1  vmnm

                    # declustered array                                          block size and
# vdisk                 and log group    activity  capacity  RAID code        checksum granularity  remarks
# ------------------  -------  --------  --------  --------  ---------------  ---------  ---------  -------
# RG001LG001LOGHOME   DA1      LG001     normal    2048 MiB  4WayReplication      2 MiB       4096  log home
# RG001LG012VS001     DA1      LG012     normal    2794 GiB  4+2p                 4 MiB     32 KiB

# 确认状态OK，写入数据检验
mmlsdisk gpfs1 -L
# disk         driver   sector     failure holds    holds                                    storage
# name         type       size       group metadata data  status        availability disk id pool         remarks
# ------------ -------- ------ ----------- -------- ----- ------------- ------------ ------- ------------ ---------
# RG001LG001VS001 nsd         512           1 Yes      Yes   ready         up                 1 system        desc
# vmnm_nvme1n1 nsd         512           3 No       No    ready         up                25 system        desc
# Number of quorum disks: 3
# Read quorum value:      2
# Write quorum value:     2

# 查看config
mmfsadm dump config|grep unmountOnDiskFail
# 修改config
unmountOnDiskFail no

测试(一个site(nc_1或nc_2)和tibreaker node)down
# 备站下电
mmgetstate -a
# site B都进入arbitrating：电源关闭后状态全unknow，稍待状态改变

# 查状态报错
mmgetstate -a
# 此时不可执行
mmshutdown -a

# 在没有shutdown的所有节点(主站点)分别执行mmshutdown
mmgetstate 
 # Node number  Node name        GPFS state
# -------------------------------------------
       # 7      client27-ib0     arbitrating
mmshutdown
# Wed Jan  1 21:45:09 PST 2020: mmshutdown: Starting force unmount of GPFS file systems
# Wed Jan  1 21:45:14 PST 2020: mmshutdown: Shutting down GPFS daemons
mmgetstate
# 单节点查询，应有状态
 # Node number  Node name        GPFS state
# -------------------------------------------
       # 9      client29-ib0     down

# 节点都关闭后,4节点去掉quorum(名称可从mmlscluster拷贝,可用IP)
mmchnode --nonquorum -N vmnm, --force
提示输入：yes

# 活着的节点上执行，down site(rg1的vdisk)的vdisk都exclude掉
mmfsctl gpfs1 exclude -d "RG001LG001VS001;"

mmlscluster
# 启动:没有关机的节点(主站点节点)
mmstartup -N node.list