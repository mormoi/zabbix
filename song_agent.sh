#!/bin/bash

function zabbix_fault_tolerant() {
	if [ $? -eq 0 ];then
		echo -e "\033[35m [ok] \033[0m"
	else 
		echo -e "\033[33m [error] \033[0m"
			exit
	fi
}

yum install gcc g++ -y
zabbix_fault_tolerant

cd /usr/local/src/
useradd zabbix
if [ -f /tmp/zabbix-2.4.2.tar.gz ];then
	echo -e "\033[35m [ok] \033[0m"
else
	wget http://180.96.27.66:4567/ZBX-install/zabbix-2.4.2.tar.gz
	zabbix_fault_tolerant
fi
tar fvxz /tmp/zabbix-2.4.2.tar.gz
zabbix_fault_tolerant
cd /usr/local/src/zabbix-2.4.2/
./configure --prefix=/usr/local/zabbix --enable-agent
zabbix_fault_tolerant
make
zabbix_fault_tolerant
make install
zabbix_fault_tolerant
chown zabbix:zabbix /usr/local/zabbix/ -R
cp -fr /usr/local/src/zabbix-2.4.2/misc/init.d/fedora/core/zabbix_agentd /etc/init.d/
chmod 755 /etc/init.d/zabbix_agentd
sed -i "s#BASEDIR=/usr/local#BASEDIR=/usr/local/zabbix#" /etc/init.d/zabbix_agentd
echo "nameserver 202.106.0.20" >> /etc/resolv.conf
\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "####NTP Time#####" >> /var/spool/cron/root
echo "*/10 * * * * ntpdate cn.pool.ntp.org" >> /var/spool/cron/root
setenforce 0
ntpdate cn.pool.ntp.org
hwclock -w
cat <<? >>/etc/services
zabbix-agent      10050/tcp                   #ZabbixAgent 
zabbix-agent      10050/udp                   #ZabbixAgent 
zabbix-trapper    10051/tcp                     #Zabbix-trapper
zabbix-trapper    10051/udp                    #ZabbixTrappe
?
eth=`ifconfig eth0 | awk '/inet addr/{print $2}' | awk -F "." '{print $3"."$4}'`

sed -i 's@Server=127.0.0.1@Server=172.16.4.8@' /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i "s@Hostname=Zabbix server@Hostname=PK-XY-Host${eth}@" /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i "s/ServerActive\=127.0.0.1/ServerActive\=172.16.4.8:10051/" /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i "s@# Timeout=3@Timeout=30@" /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i "s/# UnsafeUserParameters=0/UnsafeUserParameters=1/" /usr/local/zabbix/etc/zabbix_agentd.conf
echo "Include=/usr/local/zabbix/etc/userparams/zabbix_agentd.userparams.conf" >> /usr/local/zabbix/etc/zabbix_agentd.conf
mkdir -p /usr/local/zabbix/etc/userparams
touch /usr/local/zabbix/etc/userparams/zabbix_agentd.userparams.conf
mkdir -p /usr/local/zabbix/script
#wget http://180.96.27.66:4567/ZBX-install/script/istream -O /usr/local/zabbix/script/istream
#wget http://180.96.27.66:4567/ZBX-install/script/RM2000 -O /usr/local/zabbix/script/RM2000
#wget http://180.96.27.66:4567/ZBX-install/script/disk-health.sh -O /usr/local/zabbix/script/disk-health.sh
#wget http://180.96.27.66:4567/ZBX-install/zabbix_agentd.userparams.conf -O /usr/local/zabbix/etc/userparams/zabbix_agentd.userparams.conf
/etc/init.d/iptables stop
chkconfig --level 345 iptables off
chkconfig --level 345 zabbix_agentd on
chown zabbix:zabbix /usr/local/zabbix/ -R

/etc/init.d/zabbix_agentd start
