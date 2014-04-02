#!/bin/bash
#Danted Auto config For Debian
port=$(( RANDOM % ( 65534-1024 ) + 1024 ))

apt-get update
apt-get install vim nano dante-server apache2-utils libpam-pwdfile -y

useradd sock -s /bin/false
echo sock:sock | chpasswd

Getserverip_n=$(ifconfig | grep 'inet addr' | grep -Ev 'inet addr:127.0.0|inet addr:192.168.0|inet addr:10.0.0' | sed -n 's/.*inet addr:\([^ ]*\) .*/\1/p' | wc -l)
Getserverip=$(ifconfig | grep 'inet addr' | grep -Ev 'inet addr:127.0.0|inet addr:192.168.0|inet addr:10.0.0' | sed -n 's/.*inet addr:\([^ ]*\) .*/\1/p')

serverip=$Getserverip
( [ -z "$serverip" ] || [ -z "$(echo $Getserverip | grep "$serverip" )" ] ) && echo 'Get IP address Error.Try again OR report bug.' && exit
[ $Getserverip_n -gt 1 ] && ( echo $Getserverip | sed 's/ /\n/g' ) && read -p  "Server IP > 1, Please Input Taget Danted Server IP: " serverip

#http://devmash.net/setup-dante-server-with-virtual-user-accounts-on-ubuntu/
cat > /etc/pam.d/sockd  <<EOF
auth required pam_pwdfile.so pwdfile /etc/danted/socks.passwd
account required pam_permit.so
EOF
mkdir -p /etc/danted
/usr/bin/htpasswd -c -b -d /etc/danted/socks.passwd proxy proxy

cat >/etc/danted.conf<<EOF
internal: ${serverip}  port = ${port}
external: ${serverip}
method: username none
#method: pam
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

/etc/init.d/danted start
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "Asia/Shanghai">/etc/timezone

cat >>/var/spool/cron/root<<'EOF'
30 15 * * * ( ps -e | grep -E 'danted|sockd' | awk '{print $1}'| while read pid;do kill -9  > /dev/null 2>&1;done);rm -rf /var/log/danted.log;( sleep 10 ) && ( /etc/init.d/danted start> /dev/null 2>&1)
EOF
crontab -u root /var/spool/cron/root
service cron restart

cat <<EOF
Danted Auto Config Done! 
-------------------------------
SOCK5 ${serverip}:${port}

-------------------------------
EOF

echo > /var/log/wtmp
echo > /var/log/btmp
echo > ~/.bash_history
history -c

exit
