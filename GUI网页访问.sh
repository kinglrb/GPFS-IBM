# 网页访问:
dtcenter上申请vip,绑定需访问gui服务所在ecs的端口，然后在本地浏览器访问vip
SLB配置：443端口(协议tcp)
# gui地址
https://<GUIip>
#登录默认用户名密码
guiadmin
Admin123


GPFS GUI的文档：https://www.ibm.com/support/knowledgecenter/STXKQY_5.0.4/com.ibm.spectrum.scale.v5r04.doc/bl1ins_quickrefforgui.htm
# GPFS的GUI不能安装在ECE的RG server上，需部署在GPFS集群节点，但不能是挂盘的ECE RG节点
# 所有节点能访问collector的IP、port就能汇报信息，每台设备sensor须保持运行状态
#用mmperfmon指定collector，pmcollector启动。更改GUI主机时，需使用mmperfmon命令修改collector节点。GUI和collector需要在一个节点，如果硬件资源足够，gui可以放在仲裁节点
period采集频率，单位：秒

# GUI节点gpfsgui, pmcollector两服务重启
systemctl stop gpfsgui
psql postgres postgres -c "drop schema fscc cascade;"
systemctl start gpfsgui 
#gui日志
/var/log/cnlog/mgtsrv/gpfsgui_trc.log

# 节点health检查
/usr/lpp/mmfs/gui/cli/lsnode -v

# capacity应正常显示
# NAS workload部分，SMB和NFS的performance，集群没配，忽略
# mmmsgqueue执行失败，环境没有配置，忽略

# GUI节点GPFS日志
/var/adm/ras/mmfs.log.latest
# 池查询
mmlspool /dev/gpfs1 all -L -Y

#配置查询
mmperfmon config show
# config show查配置，用mmperfmon改配置
mmperfmon query usage
# collector上执行，显示所有节点的cpu信息
mmperfmon query compareNodes cpu_system

# 修改GPFS performance monitor配置：
mmperfmon config update GPFSPool.restrict=gui_node(GUIhostname)
# 稍待pool查询测试
echo "get metrics gpfs_pool_free_dataKB last 10 bucket_size 300" | /opt/IBM/zimon/zc 127.0.0.1 
echo "get metrics gpfs_pool_total_dataKB last 10 bucket_size 300" | /opt/IBM/zimon/zc 127.0.0.1
# 修改fileset问题的配置
mmperfmon config update GPFSFileset.restrict=gui_node(GUIhostname)
#fs_inode
echo "get metrics gpfs_fs_inode_used last 10 bucket_size 1" | /opt/IBM/zimon/zc 127.0.0.1
#mem,cpu
echo " get metrics mem_active, cpu_idle  last 10 bucket_size 1 " | /opt/IBM/zimon/zc 127.0.0.1