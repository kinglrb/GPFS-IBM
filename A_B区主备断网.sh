# 关闭主备交换机端口7、8
# telnet登录交换机：
telnet IP：PORT1
telnet IP：PORT2
# 密码 

#执行关闭
system-view
interface Ten-GigabitEthernet 1/0/7
shutdown
interface Ten-GigabitEthernet 1/0/8
shutdown
# 开启端口(shutdown改成undo shutdown)
undo shutdown

pc的bond0给down掉，断网影响小。断交换机端口，属脑裂场景故障

# 断网操作
#登录
(telnet IP PORT1和PORT2 密码:)
1.关闭主备2台交换机互联端口(7\8)
system-view
interface Ten-GigabitEthernet 1/0/7
shutdown
interface Ten-GigabitEthernet 1/0/8
shutdown
# 查看端口：
display interface brief      

# 恢复操作
2.开启主备2台交换机互联端口(7\8)
system-view
interface Ten-GigabitEthernet 1/0/7
undo shutdown

interface Ten-GigabitEthernet 1/0/8
undo shutdown
# 查看端口情况：
display interface brief