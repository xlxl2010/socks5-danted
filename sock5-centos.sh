#!/bin/sh
#For Centos

#yum update -y
yum install gcc make -y

wget ftp://ftp.inet.no/pub/socks/dante-1.3.2.tar.gz
tar zxvf dante*
cd dante*
./configure
make && make install

Getserverip_n=$(ifconfig | grep 'inet addr' | grep -Ev 'inet addr:127.0.0|inet addr:192.168.0|inet addr:10.0.0' | sed -n 's/.*inet addr:\([^ ]*\) .*/\1/p' | wc -l)
Getserverip=$(ifconfig | grep 'inet addr' | grep -Ev 'inet addr:127.0.0|inet addr:192.168.0|inet addr:10.0.0' | sed -n 's/.*inet addr:\([^ ]*\) .*/\1/p')

serverip=$Getserverip
( [ -z "$serverip" ] || [ -z "$(echo $Getserverip | grep $serverip)" ] ) && echo 'Get IP address Error.Try again OR report bug.' && exit
[ $Getserverip_n -gt 1 ] && ( echo $Getserverip | sed 's/ /\n/g' ) && read -p  "Server IP > 1, Please Input Taget Danted Server IP: " serverip

useradd sock -s /bin/false
echo sock:sock | chpasswd

cat >/etc/sockd.conf<<EOF
internal: $serverip  port =  8080
external: $serverip

#method: username none
method: pam
user.notprivileged: sock
logoutput: /var/log/danted.log

client pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
log: connect disconnect
}
pass {
from: 0.0.0.0/0 to: 0.0.0.0/0 port gt 1023
command: bind
log: connect disconnect
}
pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
command: connect udpassociate
log: connect disconnect
}
pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
command: bindreply udpreply
log: connect error
}
block {
from: 0.0.0.0/0 to: 0.0.0.0/0
log: connect error
}
EOF

cat >> ~/.bashrc<<EOF
alias s5='/usr/local/sbin/sockd -f /etc/sockd.conf &'
alias kills5='killall sockd'
EOF

/usr/local/sbin/sockd -f /etc/sockd.conf &
rm dante-1.3.2* -rf
rm centos-dante.sh -rf
exit

