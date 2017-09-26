#!/bin/bash
function zabbix_fault_tolerant() {
        if [ $? -eq 0 ];then
			echo -n "$LINENO "
                echo -e "\033[35m [ok] \033[0m"
        else
                echo -e "\033[33m [error] \033[0m"
			echo -n "$LINENO "
                        exit
        fi
}
mkdir -p /usr/local/zabbix
groupadd zabbix
useradd -g zabbix zabbix
yum install -y gcc make cmake mysql-server mysql-devel php php-gd php-devel php-mysql php-bcmath php-ctytpe php-xml php-xmlreader php-xlmwriter php-session php-net-socket php-mbstring php-gettext httpd net-snmp curl curl-devel net-snmp net-snmp-devel perl-DBI libxml libxml2-devel
zabbix_fault_tolerant 
if [ -f /root/zabbix-2.4.2.tar.gz ];then
        echo -e "\033[35m [ok] \033[0m"
else
        wget http://180.96.27.66:4567/ZBX-install/zabbix-2.4.2.tar.gz
fi
cd
tar fvxz /root/zabbix-2.4.2.tar.gz
zabbix_fault_tolerant 
if [ -d /root/fping-3.8 ];then
	cd /root/fping-3.8
else
	wget --limit-rate 500k http://www.fping.org/dist/fping-3.8.tar.gz
	zabbix_fault_tolerant 
	tar zxvf fping-3.8.tar.gz && cd fping-3.8
	zabbix_fault_tolerant 
fi
./configure && make && make install
zabbix_fault_tolerant 
chown root:zabbix /usr/local/sbin/fping
zabbix_fault_tolerant 
chmod 710 /usr/local/sbin/fping 
zabbix_fault_tolerant 
chmod ug+s /usr/local/sbin/fping
zabbix_fault_tolerant 
service mysqld start
zabbix_fault_tolerant 
zabbix_fault_tolerant 
mysql -uroot  <<EOF
create database zabbix character set utf8;
grant all on zabbix.* to zabbix@localhost identified by '123456';
FLUSH PRIVILEGES;
use zabbix;
EOF
zabbix_fault_tolerant 
cd /root/zabbix-2.4.2/database/mysql
zabbix_fault_tolerant 
mysql -uzabbix -p123456 zabbix < schema.sql
zabbix_fault_tolerant
#sed -i 's@Server=10.111.32.157@Server=192.168.9.12@' /usr/local/zabbix/etc/zabbix_agentd.conf
cd /root/zabbix-2.4.2
./configure  --enable-agent --enable-proxy --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2 --prefix=/usr/local/zabbix
make && make install
zabbix_fault_tolerant 
#########################################lai.sh#####################################
#!/bin/bash
sed -i 's@Server=127.0.0.1@Server=10.111.32.157@' /usr/local/zabbix/etc/zabbix_proxy.conf
sed -i 's@Hostname=Zabbix proxy@Hostname=testproxy@' /usr/local/zabbix/etc/zabbix_proxy.conf
sed -i 's@DBUser=root@DBUser=zabbix@' /usr/local/zabbix/etc/zabbix_proxy.conf
sed -i 's@DBName=zabbix_proxy@DBName=zabbix@' /usr/local/zabbix/etc/zabbix_proxy.conf
cat <<? >>/usr/local/zabbix/etc/zabbix_proxy.conf
DBPassword=123456
ProxyLocalBuffer=24
ProxyOfflineBuffer=24
ConfigFrequency=300
DataSenderFrequency=3
StartPollers=20
StartIPMIPollers=2
StartPollersUnreachable=2
StartTrappers=10
StartPingers=15
StartHTTPPollers=3
StartVMwareCollectors=3
VMwareCacheSize=40M
StartSNMPTrapper=1
CacheSize=100M
StartDBSyncers=6
HistoryCacheSize=100M
HistoryTextCacheSize=200M
Timeout=30
LogSlowQueries=3000
AllowRoot=1
?
sed -i 's@Server=127.0.0.1@Server=10.111.32.157@' /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i 's@ServerActive=127.0.0.1@ServerActive=10.111.32.157@' /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i 's@Hostname=Zabbix server@Hostname=testproxy@' /usr/local/zabbix/etc/zabbix_agentd.conf
cat <<? >>/usr/local/zabbix/etc/zabbix_agentd.conf
RefreshActiveChecks=60 
MaxLinesPerSecond=800
Timeout=30
AllowRoot=1
UnsafeUserParameters=1
?
cat <<? >>/etc/services
zabbix-agent      10050/tcp                   #ZabbixAgent 
zabbix-agent      10050/udp                   #ZabbixAgent 
zabbix-trapper    10051/tcp                     #Zabbix-trapper
zabbix-trapper    10051/udp                    #ZabbixTrappe
?
cp -fr /root/zabbix-2.4.2/misc/init.d/fedora/core/zabbix_agentd /etc/init.d/
chmod 755 /etc/init.d/zabbix_agentd
sed -i "s#BASEDIR=/usr/local#BASEDIR=/usr/local/zabbix#" /etc/init.d/zabbix_agentd
echo "nameserver 202.106.0.20" >> /etc/resolv.conf
\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "####NTP Time#####" >> /var/spool/cron/root
echo "*/10 * * * * ntpdate cn.pool.ntp.org" >> /var/spool/cron/root
setenforce 0
ntpdate cn.pool.ntp.org
hwclock -w
mkdir -p /usr/local/zabbix/script
cat <<? >> /usr/local/zabbix/script/proxy-restart.sh
ps -ef | awk '/zabbix-[p]roxy/{print $2}' |xargs kill -9
sleep 3
/usr/local/zabbix-proxy/sbin/zabbix_proxy
/etc/init.d/zabbix_agentd start
?
/etc/init.d/iptables stop
chkconfig --level 345 iptables off
chkconfig --level 345 zabbix_agentd on
chown zabbix:zabbix /usr/local/zabbix/ -R
/usr/local/zabbix/sbin/zabbix_proxy
/etc/init.d/zabbix_agentd start
