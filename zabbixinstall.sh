#!/bin/bash
#encoding:utf8

#######################################################################################################################################
#  Load  global variable 
#######################################################################################################################################
            
#######################################################################################################################################
#  Config  script variable 
#######################################################################################################################################

zabbix_source_code="./zabbix-3.2.6.tar.gz"
zabbix_source_code_unzip_directory="./zabbix-3.2.6/"
zabbix_deploy_directory="/oma/deploy/zabbix/"
zabbix_initial_setup_directory="${zabbix_deploy_directory}zabbix-3.2.6/"
zabbix_server_setup_directory="/usr/local/zabbix-server/"

zabbix_database_username="zabbix"
zabbix_database_password="zabbixmysql"

######################################################################################################################################
######### Definition Script Function 
######################################################################################################################################

#######################################

function  check_yn_input {

if  echo  "$2"  | grep  -q    '^[YyNn]$'
then
    yn_input_status=ok
else
    yn_input_status=error
fi


while   [ "$yn_input_status" ==  "error"  ]
do
        echo  "Invalid input. Only y/Y/n/N is permitted" 

        read   -p  "Please correct it and try again      :"      $1

        yn=`  eval echo "$"${1}  `

        if  echo  "$yn"  | grep  -q    '^[YyNn]$'
        then
            yn_input_status=ok
        else
            yn_input_status=error
        fi
done

}

#######################################

function  previous_command_result_error_interactive_choose {

back_value=` echo $?  `
if  [ "$back_value"  == "0" ]
then
    cmd_continue=yes
else
	echo  -e   "[\033[31merror\033[0m],  previous command execute error"
	read  -p   "previous command execute error,  Input Y/y continue  , Input  N/n to exit all  :"      input_confirm
	check_yn_input  input_confirm   $input_confirm
	if  [   "$input_confirm"  ==  "y"  ]   ||  [   "$input_confirm"  ==  "Y"  ]
	then
	    cmd_continue=yes
	else
	    exit       
	fi    
fi

}

#######################################

function check_yum_availability() {
echo
echo "############################################################################"
echo -e "Check yum-availability before install software -----------------------------\n"
yum info httpd
previous_command_result_error_interactive_choose
if  [ "$cmd_continue"  !=  "yes" ]
then
    echo  -e "\n[\033[31merror\033[0m],Check yum-availability failed, exit !-----------------------------\n"   
    exit 
else
	echo  -e "\n[\033[32mok\033[0m],Check yum-availability success! ---------------\n"
    echo "############################################################################"
	sleep 3s
	echo	
fi	  
}

#######################################

function install_base_package() {
echo
echo "############################################################################"
echo "install OS-based package ---------------------------------------------------"
yum -y install gcc  net-snmp-devel net-snmp net-snmp-utils OpenIPMI-devel curl-devel perl-DBI  libxml2  libxml2-python libxml2-devel libcurl-devel
previous_command_result_error_interactive_choose
echo "package installation completed ---------------------------------------------"
echo "############################################################################"
echo
}

#######################################

function install_mysql() {
echo
echo "############################################################################"
echo "install mysql --------------------------------------------------------------"
yum -y install mysql mysql-server mysql-devel mysql-connector-odbc mysql-bench
previous_command_result_error_interactive_choose
echo "mysql installation completed -----------------------------------------------"
echo "############################################################################"
echo
}

#######################################

function  disable_selinux {
 
sed -i '/SELINUX=/d  '      /etc/selinux/config  
echo "SELINUX=disabled"   >>   /etc/selinux/config  
setenforce 0          
 
}

#######################################

function install_httpd() {
echo
echo "############################################################################"
echo "install httpd --------------------------------------------------------------"
yum -y install httpd
previous_command_result_error_interactive_choose
echo "httpd installation completed -----------------------------------------------"
echo "############################################################################"
echo
}

#######################################

function install_php() {
echo
echo "############################################################################"
echo "install php ----------------------------------------------------------------"
yum -y install  php php-mysql php-gd php-bcmath php-xml php-mbstring php-snmp
previous_command_result_error_interactive_choose
echo "php installation completed -------------------------------------------------"
echo "############################################################################"
echo
}

#######################################

function install_zabbix() {
echo
echo "############################################################################"
echo "install zabbix -------------------------------------------------------------"
groupadd zabbix 
previous_command_result_error_interactive_choose
useradd -g zabbix zabbix
previous_command_result_error_interactive_choose
mkdir -p ${zabbix_deploy_directory}
tar -zxvf  $zabbix_source_code  
previous_command_result_error_interactive_choose
mv  ${zabbix_source_code_unzip_directory}   ${zabbix_deploy_directory}
previous_command_result_error_interactive_choose
cd ${zabbix_initial_setup_directory}   
previous_command_result_error_interactive_choose
./configure --enable-server --enable-agent --with-mysql --with-net-snmp --with-libcurl --enable-proxy --with-libxml2 --prefix="${zabbix_server_setup_directory}" 
previous_command_result_error_interactive_choose
make install 
previous_command_result_error_interactive_choose
cd ${zabbix_initial_setup_directory}frontends/ 
previous_command_result_error_interactive_choose
cp -a php /var/www/
previous_command_result_error_interactive_choose
cd /var/www/ 
previous_command_result_error_interactive_choose 
mv php zabbix
previous_command_result_error_interactive_choose
chown -R zabbix:zabbix zabbix
previous_command_result_error_interactive_choose
chown -R zabbix:zabbix ${zabbix_server_setup_directory}
previous_command_result_error_interactive_choose
cat >> /var/www/zabbix/conf/zabbix.conf.php << "EOF"
<?php
// Zabbix GUI configuration file
global $DB;
$DB["TYPE"]    = 'MYSQL';
$DB["SERVER"]   = 'localhost';
$DB["PORT"]    = '3306';
$DB["DATABASE"]   = 'zabbix';
$DB["USER"]    = '$zabbix_database_username';
$DB["PASSWORD"]   = '$zabbix_database_password';
// SCHEMA is relevant only for IBM_DB2 database
$DB["SCHEMA"]   = '';
$ZBX_SERVER    = 'localhost';
$ZBX_SERVER_PORT  = '10051';
$ZBX_SERVER_NAME  = '';
$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
EOF
previous_command_result_error_interactive_choose
setfacl -R -m g:apache:rwx /var/www/zabbix/
previous_command_result_error_interactive_choose
echo "zabbix installation completed ----------------------------------------------"
echo "############################################################################"
echo
}

#######################################

function config_zabbix(){
echo
echo "#######################################################################"
echo "reset /etc/services ---------------------------------------------------"
cat >> /etc/services << "EOF"
zabbix-agent 10050/tcp Zabbix Agent
zabbix-agent 10050/udp Zabbix Agent
zabbix-trapper 10051/tcp Zabbix Trapper
zabbix-trapper 10051/udp Zabbix Trapper
EOF
previous_command_result_error_interactive_choose
sed -i '/^LogFile=/d ; /^DBUser=/d ; /DBPassword=/d ;  /AlertScriptsPath=/d ;  /FpingLocation=/d  '     "${zabbix_server_setup_directory}"etc/zabbix_server.conf  
previous_command_result_error_interactive_choose
echo "LogFile="${zabbix_server_setup_directory}"zabbix_server.log"   >>   "${zabbix_server_setup_directory}"etc/zabbix_server.conf
previous_command_result_error_interactive_choose
echo "DBUser=$zabbix_database_username"  >>   "${zabbix_server_setup_directory}"etc/zabbix_server.conf
previous_command_result_error_interactive_choose
echo "DBPassword=$zabbix_database_password"  >>   "${zabbix_server_setup_directory}"etc/zabbix_server.conf
previous_command_result_error_interactive_choose
echo "AlertScriptsPath="${zabbix_server_setup_directory}"bin/"   >>   "${zabbix_server_setup_directory}"etc/zabbix_server.conf
previous_command_result_error_interactive_choose 
echo "FpingLocation=/usr/local/sbin/fping"   >>   "${zabbix_server_setup_directory}"etc/zabbix_server.conf
previous_command_result_error_interactive_choose 
##########
sed -i '/^LogFile=/d  '     "${zabbix_server_setup_directory}"etc/zabbix_agentd.conf 
previous_command_result_error_interactive_choose 
echo "LogFile="${zabbix_server_setup_directory}"zabbix_agentd.log"   >>   "${zabbix_server_setup_directory}"etc/zabbix_agentd.conf
previous_command_result_error_interactive_choose 
#############
cd ${zabbix_initial_setup_directory}
previous_command_result_error_interactive_choose
cp misc/init.d/fedora/core5/zabbix_server /etc/init.d/
previous_command_result_error_interactive_choose
cp misc/init.d/fedora/core5/zabbix_agentd /etc/init.d/
previous_command_result_error_interactive_choose
chmod 700 /etc/init.d/zabbix_*
previous_command_result_error_interactive_choose
sed -i 's/\/usr\/local\/sbin\/zabbix_server/\/usr\/local\/zabbix-server\/sbin\/zabbix_server/g'  /etc/init.d/zabbix_server
previous_command_result_error_interactive_choose
sed -i 's/\/usr\/local\/sbin\/zabbix_agentd/\/usr\/local\/zabbix-server\/sbin\/zabbix_agentd/g'  /etc/init.d/zabbix_agentd
previous_command_result_error_interactive_choose
chkconfig zabbix_server on
previous_command_result_error_interactive_choose
chkconfig zabbix_agentd on
previous_command_result_error_interactive_choose
echo "config_zabbix completed ------------------------------------------"
echo "#######################################################################"
echo
}

#######################################

function config_httpd(){
echo
echo "#######################################################################"
echo "reset httpd.conf ---------------------------------------------------"
sed -i 's/\/var\/www\/html/\/var\/www\/zabbix/g' /etc/httpd/conf/httpd.conf
previous_command_result_error_interactive_choose
}

#######################################

function config_php() {
echo
echo "#######################################################################"
echo "configure php ---------------------------------------------------------"
sed -i 's/post_max_size = 8M/post_max_size = 32M/g' /etc/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php.ini
sed -i 's/;date.timezone =/date.timezone = Asia\/Shanghai/g' /etc/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 600/g' /etc/php.ini
sed -i 's/max_input_time = 60/max_input_time = 600/g' /etc/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 256M/g' /etc/php.ini
sed -i 's/;mbstring.func_overload = 0/mbstring.func_overload = 0/g' /etc/php.ini
previous_command_result_error_interactive_choose
echo
echo "php configuration completed -------------------------------------------"
echo "#######################################################################"
}

#######################################

function config_mysql() {
echo
echo "#######################################################################"
echo "configure mysql -------------------------------------------------------"
mkdir -p /var/log/mysql/
mv /etc/my.cnf  /etc/my.cnf-backup
previous_command_result_error_interactive_choose
touch /etc/my.cnf 
previous_command_result_error_interactive_choose
chmod 644 /etc/my.cnf
previous_command_result_error_interactive_choose
cat >> /etc/my.cnf << "EOF"
[client]
port                    = 3306
socket                  = /var/lib/mysql/mysql.sock

######################
######################

[mysqld]

# paths
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock

# network
port                    = 3306
connect_timeout         = 120
wait_timeout            = 300
max_connections         = 1024
max_connect_errors      = 500
max_allowed_packet      = 128M

# limitation
max_heap_table_size     = 256M
table_cache             = 512

# log
slow_query_log          = 1
slow_query_log_file     = /var/log/mysql/mysql-slow.log
log_error               = /var/log/mysql/mysql-error.log
long_query_time         = 20

# innodb
default-storage-engine  = INNODB
innodb_file_per_table   = 1
innodb_status_file      = 1
innodb_additional_mem_pool_size = 128M
innodb_buffer_pool_size = 1024M
innodb_flush_method     = O_DIRECT
innodb_flush_log_at_trx_commit   = 2
innodb_support_xa       = 0
innodb_log_file_size    = 512M
innodb_log_buffer_size  = 128M

# other stuff
event_scheduler         = 1
query_cache_type        = 1
EOF
previous_command_result_error_interactive_choose
/etc/init.d/mysqld restart
previous_command_result_error_interactive_choose
cd ${zabbix_initial_setup_directory}database/mysql
previous_command_result_error_interactive_choose
mysql -uroot  <<EOF
create database zabbix character set utf8;
grant all privileges on *.* to '$zabbix_database_username'@'%' identified by '$zabbix_database_password';
grant all privileges on *.* to '$zabbix_database_username'@'localhost' identified by '$zabbix_database_password';
FLUSH PRIVILEGES;
use zabbix;
source ${zabbix_initial_setup_directory}database/mysql/schema.sql;
source ${zabbix_initial_setup_directory}database/mysql/images.sql;
source ${zabbix_initial_setup_directory}database/mysql/data.sql;
EOF
previous_command_result_error_interactive_choose
echo "mysql configuration completed ----------------------------------------"
echo "######################################################################"
}

#######################################

function start_services() {
echo
echo "#######################################################################"
chkconfig --level 2345 httpd on
echo "start httpd"
/etc/init.d/httpd restart
previous_command_result_error_interactive_choose
echo "#######################################################################"
chkconfig --level 2345 mysqld on
echo "start mysql"
/etc/init.d/mysqld restart
previous_command_result_error_interactive_choose
echo "#######################################################################"
echo "start zabbix"
/etc/init.d/zabbix_server restart
previous_command_result_error_interactive_choose
/etc/init.d/zabbix_agentd restart 
previous_command_result_error_interactive_choose
}

#######################################################################################################################################
#  setup zabbix server
#######################################################################################################################################

check_yum_availability
disable_selinux
install_base_package
install_mysql
install_httpd
install_php
install_zabbix
config_zabbix
config_httpd
config_php
config_mysql

start_services
