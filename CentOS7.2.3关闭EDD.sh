# CentOS7.2.3关闭EDD
#EDD不关，无法PING到新机和SSH连接

# EDD:Enhanced Disk Drive服务，支持操作系统在多盘系统中准确识别BOOT磁盘。需要BIOS和操作系统都提供相应支持，它和总线类型和磁盘接口类型紧密相关。
#CentOS7.2/7.3中EDD缺省打开，在有NVMe的系统上，可能会导致HANG死。因此在系统盘不是NVMe盘的系统上可以考虑安全关闭。
如果系统盘是NVMe，关闭会导致系统识别盘故障么？

https://www.cnblogs.com/lin1/p/5776280.html

#登录pc，查物理机中所有虚拟机，不带属性，只能查运行中的
virsh list --all

# 登录进入pc
pc_ip=10.
# 2、在 ops1环境 ssh 连接查询pc的IP
ssh $pc_ip
# 3、保存VM的配置文件：
# 查询 <vm-name>,注意vm-name中i-l(L)字母
virsh list 
vmname=`virsh list|awk 'NR==3{print $2}'`
echo $vmname
# 搜索/etc/passwd有root关键字的所有行并打印第2行第7列awk -F: '/root/ NR==2{print $7}' /etc/passwd
#保存配置,注意覆写>
	# virsh dumpxml <vm-name> > vm-name-with-nvme.xml
	# virsh dumpxml <vm-name> > vm-name.xml
virsh dumpxml $vmname > vm-name-with-nvme.xml
virsh dumpxml $vmname > vm-name.xml
# 4、修改配置信息
# 删除所有直通盘的配置信息：hostdev
vi vm-name.xml
 # <hostdev mode='subsystem' type='pci' managed='yes'>
      # </hostdev>

#关闭VM
	# virsh shutdown <vm-name>
# virsh shutdown $vmname
# 查询VM是否关闭
# virsh list 
# 如未关闭.查询PID
	# ps -ef | grep qemu | grep <vm-name> 
# ps -ef | grep qemu | grep $vmname
# 强制关闭
PID=`ps -ef | grep qemu | grep $vmname|awk 'NR==1{print $2}'`
echo $PID
# kill -9 <pid of QEMU>
kill -9 $PID
virsh list 
#重定义并重启
	# virsh undefine <vm-name>
	# virsh define vm-name.xml
	# virsh start <vm-name>
	# virsh list
virsh undefine $vmname
virsh define vm-name.xml
virsh start $vmname
sleep 5s
virsh list



# 进入VM操作
# 1、修改 GRUB
# vi /etc/default/grub
	# 在含有5200n8hang的"最后",添加“edd=off”。
cat /etc/default/grub
sed -i s/"115200n8 noibrs"/"115200n8 noibrs edd=off"/ /etc/default/grub
cat /etc/default/grub
# 2、更新GRUB
sudo grub2-mkconfig -o /etc/grub2.cfg
# 3、重启VM
reboot



# 进入pc操作，恢复root直通盘配置信息
vmname=`virsh list|awk 'NR==3{print $2}'`
echo $vmname
	# virsh shutdown <vm-name>
	# virsh undefine <vm-name>
	# virsh define vm-name-with-nvme.xml
	# virsh start <vm-name>
	# virsh list
virsh shutdown $vmname 
sleep 5s
virsh undefine $vmname
virsh define vm-name-with-nvme.xml
virsh start $vmname
sleep 5s
virsh list
# 此时，可进入VM，NVMe盘已挂载。

# 如VM不能重启,记录报错,方便排查
mkdir -p /var/run/pync/1 domain_kernel_logs
# 添加随机重启
# vi /etc/rc.local
	# sudo mkdir -p xxxx




# sed '/{/{:a;N;/}/!ba;/n/d}'  #删除n所在的{}
# sed '/{/{:a;N;/}/!ba;/n/d}'  #删除n所在的{}

cat vm-name.xml > vm-name-test
# cat vm-name-test | sed "/<hostdev mode=/,/</hostdev>/s/.*//g"
      # <hostdev mode='subsystem' type='pci' managed='yes'>
        # <driver name='vfio'/>
        # <source>
          # <address domain='0x0000' bus='0x61' slot='0x00' function='0x0'/
# >
        # </source>
        # <tdcfeature confpath='/guest/vmname/conf/42866-15
# 395.conf' id='xvdb' attachns='on'/>
        # <alias name='hostdev0'/>
        # <address type='pci' domain='0x0000' bus='0x00' slot='0x06' functi
# on='0x0'/>
      # </hostdev>	