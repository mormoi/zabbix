#!/usr/bin/expect -f
###Fuction:Automatic interaction###

set timeout -1
set ip [lindex $argv 0]
set password [lindex $argv 1]
set dir1  [lindex $argv 2]
set dir2  [lindex $argv 3]
###Support Multi-Command###

spawn ssh -q -o StrictHostKeyChecking=no root@$ip
expect {
          "(yes/no)"  {
                         send "yes\r";exp_continue }
          "password:" {
                         send "$password\r"}
}
expect {
          "#*"        {
#                        send "nohup sh /root/$dir1 &\r "
#                       send "ambari-agent restart\r "
                       send "df -h\r "
                         send "logout\r"  }
}

expect eof
