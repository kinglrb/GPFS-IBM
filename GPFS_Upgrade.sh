# GPFS Upgrade Steps
# 先解压ece的包:/usr/lpp/mmfs/5.0.4.1
./Spectrum_Scale_Erasure_Code-5.0.4.1-x86_64-Linux-install
# 1 在集群umount文件系统
mmumount gpfs1 -a
# 2 shutdown所有机器(Shutting down GPFS daemons,包括强力卸载force unmount of GPFS file systems)
mmshutdown -a
# 3 在所有node上删除gpfs rpm包 
mmdsh -N all rpm -qa  | grep gpfs | xargs rpm -e 
# 或ssh 每个node
rpm -qa  | grep gpfs | xargs rpm -e   
# 4 确保所有node上5.0.4.0的gpfs包删除 
rpm -qa  | grep gpfs
# 5 到解压目录下(这个可以给每个node上copy一份rpm包)
cd /usr/lpp/mmfs/5.0.4.1/gpfs_rpms
# 6 所有node上安装rpm及mmbuildgpl. (注意：把5.0.3.1换成目录下的包)
# rpm -ivh gpfs.adv-5.0.3-1.x86_64.rpm gpfs.base-5.0.3-1.x86_64.rpm gpfs.compression-5.0.3-1.x86_64.rpm gpfs.crypto-5.0.3-1.x86_64.rpm gpfs.docs-5.0.3-1.noarch.rpm gpfs.gnr-5.0.3-1.x86_64.rpm gpfs.gnr.base-1.0.0-0.x86_64.rpm gpfs.gnr.support-scaleout-1.0.0-0.noarch.rpm gpfs.gpl-5.0.3-1.noarch.rpm gpfs.gskit-8.0.50-86.x86_64.rpm gpfs.gui-5.0.3-1.noarch.rpm gpfs.java-5.0.3-1.x86_64.rpm gpfs.license.ec-5.0.3-1.x86_64.rpm gpfs.msg.en_US-5.0.3-1.noarch.rpm 
# 5.0.4-1
rpm -ivh gpfs.adv-5.0.4-1.x86_64.rpm gpfs.base-5.0.4-1.x86_64.rpm gpfs.compression-5.0.4-1.x86_64.rpm gpfs.crypto-5.0.4-1.x86_64.rpm gpfs.docs-5.0.4-1.noarch.rpm gpfs.gnr-5.0.4-1.x86_64.rpm gpfs.gnr.base-1.0.0-0.x86_64.rpm gpfs.gnr.support-scaleout-1.0.0-0.noarch.rpm gpfs.gpl-5.0.4-1.noarch.rpm gpfs.gskit-8.0.50-86.x86_64.rpm gpfs.gui-5.0.4-1.noarch.rpm gpfs.java-5.0.4-1.x86_64.rpm gpfs.license.ec-5.0.4-1.x86_64.rpm gpfs.msg.en_US-5.0.4-1.noarch.rpm 
# 在所有node上执行
mmbuildgpl 
# 7 启动
mmstartup -a 
# 8 保证node是active
mmgetstate -a 

# 注意：谨慎操作.小版本升级一般不需要执行以下步骤升级集群版本
# 9 把集群的配置升级到最新(注意：升级不可逆 执行前先确认)
mmchconfig release=LATEST
# 10 把文件系统升级到最新(注意:升级不可逆,  执行前先确认)
mmchfs FileSystem -V full


# nmdsh当作系统sh使用，做批量操作(mmdsh -N all "cmd")，mmdsh命令要用引号引起来，单双引号都行,否则操作很危险。如cmd内部有单引号，可以mmdsh -N all "cmd";如命令内部有双引号，可以mmdsh -N all ‘cmd’;如命令是一个满足Shell语言变量名命名原则的字符串，那可以不加任何引号
