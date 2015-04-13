#!/bin/bash

## root 계정 비번 제거
sed -i '/root/d' /etc/shadow
echo "root:!:16038:0:99999:7:::" >> /etc/shadow

echo "
acpiphp
pci_hotplug" >> /etc/modules
for m in acpiphp pci_hotplug; do sudo modprobe ${m}; done

if [ ! -z $PASSWD ]; then
	echo "root:$PASSWD" | chpasswd
	#echo "$PASSWD" | passwd --stdin root
fi

cp -f /usr/share/zoneinfo/Asia/Seoul /etc/localtime

## HOSTNAME 설정
#HOSTNAME="Public-VM-`echo $ETH0_IP | sed 's/\./-/g'`"
HOSTNAME="VM-`echo $ETH0_IP | sed 's/\./-/g'`"
echo "$HOSTNAME.test.org" > /etc/hostname
#echo "$ETH0_IP $HOSTNAME.test.org $HOSTNAME" >> /etc/hosts
#echo "127.0.0.1 $HOSTNAME.test.org $HOSTNAME" >> /etc/hosts
hostname $HOSTNAME.test.org
#/etc/init.d/hostname restart

echo "nameserver 192.168.33.11
nameserver 168.126.63.1" > /etc/resolv.conf

CODENAME=`lsb_release -a 2> /dev/null| awk '/^Codename/ {print $2}'`
if [ $CODENAME == "precise" ]; then

echo "### Internal apt-get Mirror
#deb http://192.168.33.11/ubuntu precise main restricted universe
#deb http://192.168.33.11/ubuntu precise-updates main restricted universe
#deb http://192.168.33.11/ubuntu precise-security main restricted universe multiverse

deb http://ftp.daum.net/ubuntu precise main restricted universe
deb http://ftp.daum.net/ubuntu precise-updates main restricted universe
deb http://ftp.daum.net/ubuntu precise-security main restricted universe multiverse" > /etc/apt/sources.list

elif [ $CODENAME == "trusty" ]; then

echo "### Internal apt-get Mirror
#deb http://192.168.33.11/ubuntu trusy main restricted universe
#deb http://192.168.33.11/ubuntu trusy-updates main restricted universe
#deb http://192.168.33.11/ubuntu trusy-security main restricted universe multiverse

deb http://ftp.daum.net/ubuntu/ trusty main restricted universe multiverse
deb http://ftp.daum.net/ubuntu/ trusty-updates main restricted universe multiverse
deb http://ftp.daum.net/ubuntu/ trusty-security main restricted universe multiverse
#deb http://ftp.daum.net/ubuntu/ trusty-backports main restricted universe multiverse" > /etc/apt/sources.list

fi

if [ $CODENAME == "trusty" ]; then
	ifdown -a && ifup -a
else
	/etc/init.d/networking restart
fi

umount -l /mnt

update-rc.d vmcontext disable
echo -e "nameserver 192.168.33.11\nnameserver 168.126.63.1" >> /etc/resolvconf/resolv.conf.d/head 
