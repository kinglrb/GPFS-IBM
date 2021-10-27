# ------------------------------------------------------------------故障恢复测试-------------------------------
#虚拟机操作
for ip in `cat pcIPlist`
do
	echo $ip
    #获取VM名称列表
	ssh $ip "vmname=`virsh list|awk 'NR==3{print $2}'`;echo $vmname" >> vmNMlist
	# virsh shutdown $vmname 
	# sleep 8s
	# virsh start $vmname
done

#批量关机
for ip in `cat aIPlist`
do
	echo $ip
	ssh $ip "shutdown -h now"
done
# --------------------------------------------------------------------------------------
#主站点故障恢复.开启存储服务，确认状态，执行数据恢复
cat primarySiteRecovery.sh
#!/usr/bin/sh
mmgetstate -a
#启动主站
mmstartup -N 192.168.1.246,192.168...
sleep 1m
mmgetstate -a
# 数据自行恢复
mmchdisk gpfs1 start -a

# 备站点故障(主站停服)恢复
	cat backupRecovery.sh
	#!/usr/bin/sh
	mmgetstate -a
	mmdsh -N 192.168.1.246,192.168... "/usr/lpp/mmfs/bin/mmshutdown"
	mmchnode --nonquorum -N 192.168.2.14,192.168... --force
	mmfsctl gpfs1 exclude -d "192.168.2.14;192.168..."
	mmstartup -N 192.168.1.246,192.168...
	mmmount all -N 192.168.1.246,192.168...
	mmgetstate -a
# 主站单站恢复操作
#关闭主站系统(node.list为主站点所有节点列表)
mmdsh -N node.list /usr/lpp/mmfs/bin/mmshutdown 
mmchnode --nonquorum -N <备站点quorum节点列表+仲裁节点> --force
#如系统有节点未关闭，执行mmshutdown -a
# 排除备站点磁盘(”gpfs1nsd;gpfs2nsd”备站点NSD列表+仲裁节点NSD)
mmfsctl <fsname> exclude -d “gpfs1nsd;gpfs2nsd” 
#启动主站
mmstartup -N node.list
# 主站点挂载文件系统
mmmount <fsName> -N node.list
#备站和仲裁物理恢复上电，恢复系统
# 关掉所有节点GPFS
mmshudown 
mmstartup -N 主站点所有节点
mmchnode --quorum -N 仲裁节点 
mmstartup -N 仲裁节点
mmchnode --quorum -N quorum节点
mmstartup -N 备站点所有节点
# 卸载文件系统
mmumount <fsName> -a
#加入所有磁盘”gpfs1nsd;gpfs2nsd;gpfs5nsd”备站点NSD列表+仲裁节点NSD
mmfsctl <fsName> include -d “gpfs1nsd;gpfs2nsd;gpfs5nsd” 
#文件系统全挂载
mmmount <fsName> -N 主站点所有节点+备站点所有节点
#磁盘同步
mmchdisk <fsName> start -a
#ECE数据恢复
mmrestripefs <fsName> -b

cat changeRole
#!/usr/bin/sh
mmchnode --nonquorum -N vmNMlist --force
cat nsd_in.sh
#!/usr/bin/sh
mmfsctl gpfs1 include -d "磁盘组清单"
cat nsd_ex.sh
#!/usr/bin/sh
mmfsctl gpfs1 exclude -d "磁盘组清单"
# ---------------------------------------------------------------测试脚本-------------------------------------------------------------------
cat DRtest.sh
#!/usr/bin/sh

#read a
#echo "DR主站全故障测试恢复"
start_date=`date "+%Y-%m-%d %H:%M:%S"`
exe_date=`date "+%Y%m%d%H%M%S"`
echo "Start time:${start_date}"

#script -f -t 2>${a}.time -a ${a}.his
cd /usr/lpp/mmfs/bin/
mmgetstate -a
echo "文件系统状态正常"
sleep 20s
mmlscluster
echo "集群状态正常"
sleep 20s
cd /gpfs/gpfs1/test2/
du -sh ./*
pwd
cat test2_990
#rm -rf /gpfs/gpfs1/test2/*
ls /gpfs/gpfs1/test2/|wc -l
#ls
echo "test2目录验证成功"
sleep 20s
#cd /root/gpfs-test
#sh bin/creatFile.sh > log/file_test1_${exe_date}.log 2>&1
cd /gpfs/gpfs1/test1/
du -sh ./*
pwd
ls |wc -l
echo "文件数量正常"
#sleep 30s
#du -sh ./*
cat test1_990
echo "test1测试文件验证正常"
end_date=`date "+%Y-%m-%d %H:%M:%S"`
echo "End time: ${end_date}"
echo "文件测试完成"

#  生成测试文件
cat testStart.sh
#!/usr/bin/sh
read a
#  开启命令录制
script -f -t 2>${a}.time -a ${a}.his
start_date=`date "+%Y-%m-%d %H:%M:%S"`
exe_date=`date "+%Y%m%d%H%M%S"`
echo "Start time:${start_date}"
#查看状态
/usr/lpp/mmfs/bin/mmgetstate -a
# 调用test1_fg，生成测试文件
sh -x ./bin/creatFile.sh > ./log/fileCreat_test1_${exe_date}.log 2>&1
#删除原数据，执行数据创建脚本
cat bin/creatFile.sh  
#!/usr/bin/sh
rm -rf /gpfs/gpfs1/test1/*
for i in `seq 1 1000`
do
	echo "test" > /gpfs/gpfs1/test1/test1_${i}
	# sleep 0.5s
done


# 统计文件数，调用contentCheck.sh判断文件内容，查找有错文件
cat dataVerify.sh
#!/usr/bin/sh
cmp_date=`date "+%Y%m%d%H%M%S"`

file_count=`ls /gpfs/gpfs1/test1 | wc -l`
echo -e "files: ${file_count}\t${cmp_date}"

for i in `seq 1 1000`
do
    cat /gpfs/gpfs1/test1/test1_${i} | ./bin/contentCheck.sh > ./log/cmp_test1_${cmp_date}.log 2>&1
done
grep -i -n "error" ./log/cmp_test1_${cmp_date}.log
#判断文件内容是否正确
cat contentCheck.sh
#!/usr/bin/sh
read a
if [ ${a} != "test" ]
then
	echo -e  "error: ${a} is not test"
fi

#关机
cat ancIPnm|awk 'NR==1{print $2}'

for ip in `cat aIPlist`
do
	echo $ip
	ssh $ip "shutdown -h now"
done

virsh start $vmname
sleep 5s
virsh list

#!/bin/bash
str="a b --n d"
array=($str)
length=${#array[@]}
echo $length


do
    echo ${array[$i]}
done


iplist=`cat ancIPnm|awk '{print $1}'`
echo $iplist
len=${#iplist[@]}
echo $len

for ((i=1; i<$len; i++))
do
    echo $i
	ip=${iplist[$i]}
	echo $ip
	# let 'i+=1'
	# ssh $ip "shutdown -h now"
done




echo "开始DR主站全故障测试"
echo "文件系统状态正常"
echo "集群状态正常"
echo "旧测试文件已删除"
echo "本次测试文件已生成"
echo "测试生成文件正常"
echo "准备主站全关机"

#  开启命令录制，查看状态，调用test1_fg
cat DRtest1_2start.sh
#!/bin/bash
start_date=`date "+%Y-%m-%d %H:%M:%S"`
exe_date=`date "+%Y%m%d%H%M%S"`
echo "Start time:${start_date}"

#script -f -t 2>DRtest1.time -a DRtest1.his
cd /usr/lpp/mmfs/bin/
mmgetstate -a
echo "主站点文件系统故障，备站点文件系统正常"
sleep 25s
mmlscluster
echo "主站点文件系统故障，备站点文件系统正常"
echo "符合测试预期"
sleep 25s
cd /gpfs/gpfs1/test1/
du -sh ./
pwd
ls |wc -l
cat test1_990
echo "备站点文件正常"
sleep 25s
rm -rf /gpfs/gpfs1/test2/*
cd /gpfs/gpfs1/test2/
ls |wc -l
echo "备站点原测试文件删除完毕"
for i in `seq 1 1000`
do
    echo "test" > /gpfs/gpfs1/test2/test2_${i}cm
done
du -sh ./
pwd
ls |wc -l
cat test2_990
echo "备站点测试文件生成正常"
end_date=`date "+%Y-%m-%d %H:%M:%S"`
echo "End time: ${end_date}"
echo "备站点文件生成、两次验证完毕，准备重启主站点"



# 统计文件数，调用test_cf.sh判断文件内容，查找有错文件
cat cmp_test1.sh
#!/usr/bin/sh

start_date=`date "+%Y-%m-%d %H:%M:%S"`
echo "Start date: ${start_date}"

cmp_date=`date "+%Y%m%d%H%M%S"`

file_count=`ls /gpfs/gpfs1/test1 | wc -l`
echo -e "files: ${file_count}\t${cmp_date}"

for i in `seq 1 1000`
do
        cat /gpfs/gpfs1/test1/test1_${i} | ./bin/test_cf.sh > ./log/cmp_test1_${cmp_date}.log 2>&1
done
grep -i -n "error" ./log/cmp_test1_${cmp_date}.log
end_date=`date "+%Y-%m-%d %H:%M:%S"`
echo "End date: ${end_date}"

cat test_cf.sh
#!/usr/bin/sh
read a
if [ ${a} != "test" ]
then
        echo -e  "error: ${a} is not test"
fi
# -------------------------------------------------------------------------------------------------------------------
#虚拟机开机
cat startVM.sh
#!/bin/sh
#***************************************************************#
pc_ip=()
vm_addr=(vmnm1 vmnm2...)
#A主站
# pc_ip=(10.35.1.30 10.35...)
# vm_addr=(vmnm1 vmnm2...)

for ((i=0;i<${#pc_ip[@]};i++))
do
    echo "Start: Start ${pc_ip[i]}"
ssh ${pc_ip[i]} << remotessh
virsh start ${vm_addr[i]}.2750.175
exit
remotessh
    echo "End: Start ${pc_ip[i]}"
done

#虚拟机关闭
cat powerOffVM.sh
#!/bin/sh
pc_ip=(10.36.2.16 10.36...)
vm_addr=(vmnm1 vmnm2...)
#A主站
# pc_ip=(10.35.1.30 10.35...)
# vm_addr=(vmnm1 vmnm2...)
for ((i=0;i<${#pc_ip[@]};i++))
do
    echo "Start: Stop ${pc_ip[i]}"
ssh ${pc_ip[i]} << remotessh
virsh shutdown ${vm_addr[i]}.2750.175
exit
remotessh
    echo "End: Stop ${pc_ip[i]}"
done

#添加单节点
cat addSingleNode.sh
#!/usr/bin/sh
read -p "Please input your module : 1 is " -a ipadd
for (( i=0;i<${#ipadd[@]};i++ ))
do
echo ${ipadd[i]}
ssh ${ipadd[i]} << remotessh
mmbuildgpl
exit
remotessh

mmaddnode -N ${ipadd[i]} --accept
mmchlicense server --accept -N all
mmlscluster
mmgetstate -a
mmstartup -a
mmgetstate -a
done

#添加多节点
cat addNodes.sh
#!/usr/bin/sh

read -p "" -a ipall

for ((i=0;i<${#ipall[@]};i++))
do
echo "Connect to ${ipall[i]}"
ssh ${ipadd[i]} << remotessh
mmbuildgpl
exit
remotessh
done

mmcrcluster -N nodeDesc.client -A
mmchlicense server --accept -N all
mmlscluster
mmgetstate -a
mmstartup -a
mmgetstate -a
mmchcluster -C DebbyTest
# 文件系统参数优化
mmchconfig maxMBpS=24000,verbsRdmaSend=yes,workerThreads=1024,pagepool=485G,readReplicaPolicy=local,unmountOnDiskFail=meta,restripeOnDiskFailure=yes,nsdThreadsPerQueue=10,nsdMinWorkerThreads=48,prefetchAggressivenessWrite=0,prefetchAggressivenessRead=2,nsdInlineWriteMax=1000000,nsdSmallThreadRatio=2,nsdThreadsPerDisk=16
mmshutdown -a
mmstartup -a
mmgetstate -a
mmlsconfig

mmvdisk nodeclass create --node-class pc_1 -N all
mmvdisk server configure --node-class pc_1
mmshutdown -a
mmstartup -a
mmgetstate -a
mmvdisk recoverygroup create --recovery-group rg1 --node-class pc1 -v no
mmvdisk nodeclass list
mmlsrecoverygroup
mmlsnodeclass

mmvdisk vs list --vs all
mmvdisk recoverygroup create --recovery-group rg_1 --node-class pc_1 -v no
mmvdisk vdiskset list --vdisk-set all
mmvdisk vs define --vs vs_1 --rg rg_1 --code 4+2p --bs 4M --ss 100% --da DA1 --nsd-usage dataAndMetadata --sp system
mmvdisk vs create --vs vs_1
mmvdisk fs create --fs gpfs1 --vs vs_1
mmvdisk fs list
mmmount all -a
mmlsmount all -L
df -h


cat path.gpfs
# /etc/profile

# System wide environment and startup programs, for login setup
# Functions and aliases go in /etc/bashrc

# It's NOT a good idea to change this file unless you know what you
# are doing. It's much better to create a custom.sh shell script in
# /etc/profile.d/ to make custom changes to your environment, as this
# will prevent the need for merging in future updates.

export PATH="$PATH:/usr/lpp/mmfs/bin"

pathmunge () {
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
    esac
}


if [ -x /usr/bin/id ]; then
    if [ -z "$EUID" ]; then
        # ksh workaround
        EUID=`/usr/bin/id -u`
        UID=`/usr/bin/id -ru`
    fi
    USER="`/usr/bin/id -un`"
    LOGNAME=$USER
    MAIL="/var/spool/mail/$USER"
fi

# Path manipulation
if [ "$EUID" = "0" ]; then
    pathmunge /usr/sbin
    pathmunge /usr/local/sbin
else
    pathmunge /usr/local/sbin after
    pathmunge /usr/sbin after
fi

HOSTNAME=`/usr/bin/hostname 2>/dev/null`
HISTSIZE=1000
if [ "$HISTCONTROL" = "ignorespace" ] ; then
    export HISTCONTROL=ignoreboth
else
    export HISTCONTROL=ignoredups
fi

export PATH USER LOGNAME MAIL HOSTNAME HISTSIZE HISTCONTROL

# By default, we want umask to get set. This sets it for login shell
# Current threshold for system reserved uid/gids is 200
# You could check uidgid reservation validity in
# /usr/share/doc/setup-*/uidgid file
if [ $UID -gt 199 ] && [ "`/usr/bin/id -gn`" = "`/usr/bin/id -un`" ]; then
    umask 002
else
    umask 022
fi

for i in /etc/profile.d/*.sh /etc/profile.d/sh.local ; do
    if [ -r "$i" ]; then
        if [ "${-#*i}" != "$-" ]; then
            . "$i"
        else
            . "$i" >/dev/null
        fi
    fi
done

unset i
unset -f pathmunge



cat hostname.sh
#!/usr/bin/sh

ins_date=`date "+%Y%m%d%H%M%S"`

cat ./gpfs-cfg/gpfs-server-A.cfg | sh -x ./bin/gpfs_hosts.sh > ./log/gpfs_hosts_${ins_date}.log
cat ./gpfs-cfg/gpfs-server-B.cfg | sh -x ./bin/gpfs_hosts.sh > ./log/gpfs_hosts_${ins_date}.log
cat ./gpfs-cfg/gpfs-client-B.cfg | sh -x ./bin/gpfs_hosts.sh > ./log/gpfs_hosts_${ins_date}.log
cat ./gpfs-cfg/gpfs-client-B.cfg | sh -x ./bin/gpfs_hosts.sh > ./log/gpfs_hosts_${ins_date}.log

grep -i -n 'error' ./log/gpfs_hosts_${ins_date}.log
grep -i -n 'fail' ./log/gpfs_hosts_${ins_date}.log



cat ins_gpfs.sh
#!/usr/bin/sh
# Created by Sundalei at 24/12/2019
# Author: SunDaLei
# UpdateDate: 24/12/2019
# Description: CPFS install,basic config,install all node,install add node
# Argument: base,all,add

ins_date=`date "+%Y%m%d%H%M%S"`

if [ $1 == 'base' ]
then
        echo "CPFS Basic Config -- All Node"
        cat ./config/gpfs-all.cfg | sh -x ./bin/gpfs_base.sh > ./log/gpfs_base_${ins_date}.log 2>&1
        echo "End: CPFS Basic Config -- All Node"
        echo "CPFS Basic Config: error"
        grep -i -n 'error' ./log/gpfs_base_${ins_date}.log
        grep -i -n 'fail' ./log/gpfs_base_${ins_date}.log
elif [ $1 == 'all' ]
then
        echo "Start: CPFS Basic Config --All Node"
        cat ./config/gpfs-all.cfg | sh -x ./bin/gpfs_base.sh > ./log/gpfs_base_${ins_date}.log 2>&1
        echo "End: CPFS Basic Config -- All Node"
        echo "CPFS Basic Config: error"
        grep -i -n 'error' ./log/gpfs_base_${ins_date}.log
        grep -i -n 'fail' ./log/gpfs_base_${ins_date}.log

        echo "Start: CPFS Install -- All Node"
        cat ./config/gpfs-all.cfg | sh -x ./bin/gpfs_all.sh > ./log/gpfs_all_${ins_date}.log 2>&1
        echo "End: CPFS Install -- All Node"
        echo "CPFS Install All: error"
        grep -i -n 'error' ./log/gpfs_all_${ins_date}.log
        grep -i -n 'fail' ./log/gpfs_all_${ins_date}.log
elif [ $1 == 'add' ]
then
        echo "Start: CPFS Basic Config -- All Node"
        cat ./config/gpfs-all.cfg | sh -x ./bin/gpfs_base.sh > ./log/gpfs_base_${ins_date}.log 2>&1
        echo "End: CPFS Basic Config -- All Node"
        echo "CPFS Basic Config: error"
        grep -i -n 'error' ./log/gpfs_base_${ins_date}.log
        grep -i -n 'fail' ./log/gpfs_base_${ins_date}.log
        echo "Start: CPFS Install -- Add Node"
        cat ./config/gpfs-add.cfg | sh -x ./bin/gpfs_add.sh > ./log/gpfs_add_${ins_date}.log 2>&1
        echo "End: CPFS Install -- Add Node"
        echo "CPFS Install Add: error"
        grep -i -n 'error' ./log/gpfs_add_${ins_date}.log
        grep -i -n 'fail' ./log/gpfs_add_${ins_date}.log
elif [ $1 == 'upgrade' ]
then
        echo "Start: CPFS Upgrade"
        cat ./config/gpfs-upgrade.cfg | sh -x ./bin/gpfs_upgrade.sh > ./log/gpfs_upgrade_${ins_date}.log 2>&1
        echo "End: CPFS Upgrade"
        echo "CPFS Upgrade: error"
        grep -i -n 'error' ./log/gpfs_upgrade_${ins_date}.log
        grep -i -n 'fail' ./log/gpfs_upgrade_${ins_date}.log
else
        echo "$1 is error argument,Please input base,all,add or upgrade."
fi


cat gpfs_base.sh
#!/usr/bin/sh

echo "Clear Config File"
rm -rf ./gpfs-cfg/ssh/*.ssh
rm -rf ./gpfs-cfg/host/*.host

read -p "Please input GPFS node IP :" -a ipaddr

for (( i=0;i<${#ipaddr[@]};i++ ))
do
echo "Remote Copy Script"
scp ./bin/host.sh root@${ipaddr[i]}:/root
scp ./bin/node.sh root@${ipaddr[i]}:/root

echo "Connect to ${ipaddr[i]}"
ssh ${ipaddr[i]}        << remotessh
if [ -d gpfs-cfg ]
then
        rm -rf gpfs-cfg/*.*
else
        mkdir gpfs-cfg
fi
./host.sh > ./gpfs-cfg/${ipaddr[i]}.host
./node.sh > ./gpfs-cfg/${ipaddr[i]}.node
cat /root/.ssh/id_rsa.pub > ./gpfs-cfg/${ipaddr[i]}.ssh
exit
remotessh
scp root@${ipaddr[i]}:/root/gpfs-cfg/${ipaddr[i]}.ssh ./gpfs-cfg/ssh
scp root@${ipaddr[i]}:/root/gpfs-cfg/${ipaddr[i]}.host ./gpfs-cfg/host
scp root@${ipaddr[i]}:/root/gpfs-cfg/${ipaddr[i]}.node ./gpfs-cfg/node
done

echo "Collect Config"
cat ./gpfs-cfg/host/host.module ./gpfs-cfg/host/*.host > ./gpfs-cfg/host.gpfs
cat ./gpfs-cfg/ssh/*.ssh > ./gpfs-cfg/ssh.gpfs
cat ./gpfs-cfg/node/*.node > ./gpfs-cfg/node.gpfs

for (( i=0;i<${#ipaddr[@]};i++ ))
do
echo "Remote Copy Config File"
scp ./gpfs-cfg/*.gpfs root@${ipaddr[i]}:/root/gpfs-cfg
scp ./gpfs-cfg/gpfs-rpm-4.1.tar root@${ipaddr[i]}:/root/gpfs-cfg

echo "Connect to ${ipaddr[i]}"
ssh ${ipaddr[i]}        << remotessh

echo "Set SSH Key"
cat ./gpfs-cfg/ssh.gpfs > ./.ssh/authorized_keys

echo "Set Hosts"
cat ./gpfs-cfg/host.gpfs > /etc/hosts

echo "Set PATH"
cat ./gpfs-cfg/path.gpfs > /etc/profile
source /etc/profile
# cat ./gpfs-cfg/yum.gpfs > yum.gpfs

echo "Install GPFS_RPM"
tar -xvf ./gpfs-cfg/gpfs-rpm-4.1.tar
rpm -ivh ./gpfs-rpm-4.1/gpfs.base-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.adv-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.compression-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.crypto-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.docs-5.0.4-1.noarch.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gnr.base-1.0.0-0.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gnr-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gnr.support-scaleout-1.0.0-1.noarch.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gskit-8.0.50-86.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gpl-5.0.4-1.noarch.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gss.pmcollector-5.0.4-1.el7.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gss.pmsensors-5.0.4-1.el7.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.java-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gui-5.0.4-1.noarch.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.license.ec-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.msg.en_US-5.0.4-1.noarch.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.nfs-ganesha-2.7.5-ibm053.02.el7.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.nfs-ganesha-gpfs-2.7.5-ibm053.02.el7.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.nfs-ganesha-utils-2.7.5-ibm053.02.el7.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.pm-ganesha-10.0.0-1.el7.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/sg3_utils-libs-1.37-18.el7_7.1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/sg3_utils-1.37-18.el7_7.1.x86_64.rpm

echo "Check rpm install"
rpm -qa | grep gpfs. | sort
rpm -qa | grep sg3

echo "Check NVME List"
nvme list

echo "Execute systemctl"
./sysctl.sh

echo "Close firewalld"
systemctl disable firewalld

echo "Execute mmnetverify to check net"
mmnetverify --configuration-file ./gpfs-cfg/node.gpfs

exit
remotessh
done



cat gpfs_hosts.sh
#!/usr/bin/sh

read -p "Please input node ip: " -a iphost

for (( i=1;i<${#iphost[@]};i++))
do
echo -e "\n"${iphost[i]}"\t"${iphost[0]}${i} > ./gpfs-cfg/gpfs.hosts
scp ./gpfs-cfg/gpfs.hosts root@${iphost[i]}:/root
ssh ${iphost[i]}        << remotessh
hostnamectl set-hostname ${iphost[0]}${i}
cat gpfs.hosts >> /etc/hosts
rm -rf gpfs.hosts
exit
remotessh
done


cat gpfs_upgrade.sh
#!/usr/bin/sh

read -p "Please input CPFS node IP:" -a ipaddr

for (( i=0;i<${#ipaddr[@]};i++}))
do
scp ./gpfs-cfg/ECE_5.0.4.1.tar root@${ipaddr[i]}:/root/gpfs-cfg
scp ./gpfs-cfg/gpfs-rpm-4.1.tar root@${ipaddr[i]}:/root/gpfs-cfg
ssh root@${ipaddr[i]}   << remotessh
tar -xvf ./gpfs-cfg/ECE_5.0.4.1.tar
chmod 755 ./ECE_5.0.4.1/*
echo "1" | ./ECE_5.0.4.1/Spectrum_Scale_Erasure_Code-5.0.4.1-x86_64-Linux-install
exit
remotessh
done

mmoumount gpfs1 -a
mmshutdown -a

for (( i=0;i<${#ipaddr[@]};i++))
do
ssh root@${ipaddr[i]}   << remotessh
rpm -qa | grep gpfs | xargs rpm -e
tar -xvf ./gpfs-cfg/gpfs-rpm-4.1.tar
rpm -ivh ./gpfs-rpm-4.1/gpfs.base-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.adv-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.compression-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.crypto-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.docs-5.0.4-1.noarch.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gnr.base-1.0.0-0.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gnr-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gnr.support-scaleout-1.0.0-1.noarch.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gskit-8.0.50-86.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gpl-5.0.4-1.noarch.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gss.pmcollector-5.0.4-1.el7.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gss.pmsensors-5.0.4-1.el7.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.java-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.gui-5.0.4-1.noarch.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.license.ec-5.0.4-1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.msg.en_US-5.0.4-1.noarch.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.nfs-ganesha-2.7.5-ibm053.02.el7.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.nfs-ganesha-gpfs-2.7.5-ibm053.02.el7.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.nfs-ganesha-utils-2.7.5-ibm053.02.el7.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/gpfs.pm-ganesha-10.0.0-1.el7.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/sg3_utils-libs-1.37-18.el7_7.1.x86_64.rpm
rpm -ivh ./gpfs-rpm-4.1/sg3_utils-1.37-18.el7_7.1.x86_64.rpm

mmbuildgpl
exit
remotessh
done

mmstartup -a
sleep 1m
mmgetstate -a
# --------------------------------------------------------------------------------