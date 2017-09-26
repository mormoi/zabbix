#!/bin/bash
function zabbix_fault_tolerant() {
	if [ $? -eq 0 ];then
		echo -e "\033[35m [ok] \033[0m"
	else 
		echo -e "\033[33m [error] \033[0m"
			exit
	fi
}
cp -r /usr/local/zabbix/etc /tmp/
cp -r /usr/local/zabbix/script/ /tmp/
rm -rf /usr/local/zabbix/
cd /tmp/
useradd zabbix
if [ -f /tmp/zabbix-3.2.6.tar.gz ];then
	echo -e "\033[35m [ok] \033[0m"
else
	wget http://180.96.27.66:4567/ZBX-install/zabbix-2.4.2.tar.gz
	zabbix_fault_tolerant
fi
tar fvxz /tmp/zabbix-3.2.6.tar.gz
zabbix_fault_tolerant
cd /tmp/zabbix-3.2.6/
./configure --prefix=/usr/local/zabbix --enable-agent
zabbix_fault_tolerant
make
zabbix_fault_tolerant
make install
zabbix_fault_tolerant
cp -fr /tmp/zabbix-3.2.6/misc/init.d/fedora/core/zabbix_agentd /etc/init.d/
sed -i "s#BASEDIR=/usr/local#BASEDIR=/usr/local/zabbix#" /etc/init.d/zabbix_agentd
chmod 755 /etc/init.d/zabbix_agentd
rm -rf /usr/local/zabbix/etc
mv /tmp/etc /usr/local/zabbix/
mv /tmp/script /usr/local/zabbix/
chkconfig --level 345 zabbix_agentd on
chown zabbix:zabbix /usr/local/zabbix/ -R
/etc/init.d/zabbix_agentd start
