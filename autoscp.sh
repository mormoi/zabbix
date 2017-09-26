#!/bin/bash
if [ $2 = "bjcnc" ];then
        ip=""
        d=`seq 11 26`
        p="192.168.20."
        for i in $d
        do
        ip="$ip $p$i"
        done
        ip="$ip 192.168.20.200 192.168.20.201 192.168.20.202 192.168.20.203 192.168.20.104 192.168.20.105 192.168.20.109 192.168.20.110 192.168.20.101 192.168.20.102"
        echo $ip
passwd='!@#ge()_r()()t'
fi
if [ $2 = "zjcnc" ];then
	ip=""
	i="172.16.6."
	ii="4 5 6 7 8 9 10 12"
	for p in $ii
	do
	ip="$ip $i$p"
	done
	echo $ip
	passwd="ge()_r()()t"
fi
for i in $ip
        do
        ip=$i
        echo -e "\033[32m $ip \033[0m"
if [ $1 = "root" ];then
        dir1="$3 $ip"
        ./autoexp3.sh ${ip} ${passwd} ${dir1} ${dir2}
        if [ $? -ne 0 ];then
        echo "error $ip" >> log
        fi
elif [ $1 = "scp" ];then
        dir1=$3
        ./autoscpssh.sh ${ip} ${passwd} ${dir1} ${dir2}
        if [ $? -ne 0 ];then
        echo "error $ip" >> log
        fi
else
        dir1=$1

        ./autoexp7.sh ${ip} ${passwd} ${dir1} ${dir2}
fi
done
