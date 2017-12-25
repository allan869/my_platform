#!/bin/sh
#Script function: system init
#Write  by: yangruizeng
#Mail: yangruizeng@cctv.cn
echo -e "\033[32m+--------------------------------------------------------------+\033[0m"
echo -e "\033[32m|             Welcome to Centos System init                    |\033[0m"
echo -e "\033[32m+--------------------------------------------------------------+\033[0m"
format(){
          #echo -e "\033[42;37m ########### Finished ########### \033[0m"        
          sleep 5
          echo -e "\033[1;32m ----------------- Finished ----------------- \033[0m" 
          echo "  "
}
#set env
export PATH=$PATH:/bin:/sbin/:/usr/sbin
#export LANG="zh_CN.GB18030"
#Require root to run this script.
if [[ "$(whoami)" != "root" ]]; then
    echo "Please run this script as root." >&2
    exit 1
fi
#define cmd var
PASSWD="******"
MASTER_DNS=119.29.29.29
SLAVE_DNS=182.254.116.116
HOSTNAME=$1
GET_OPTION=$1
ADDRESS=`echo $1 |awk -F "-" '{print $1}'`
OS_VERSION=`egrep -o "6.* |7.* " /etc/redhat-release |awk -F "[.]" '{print $1}'`
#Source function library
. /etc/init.d/functions
USAGE() {
if  [ ! -n "$GET_OPTION"  ];then
        echo "Usage: 
        请在脚本后添加参数
        $0 + hostname"
        exit 0;
fi
}
####################Config Yum CentOS-Base.repo####################
ConfigYum(){
        echo "Config Yum CentOS-Base.repo."
        cd /etc/yum.repos.d/
        \cp CentOS-Base.repo CentOS-Base.repo.$(date +%F)
        ping -c 1 baidu.com >/dev/null
        [ ! $? -eq 0 ] && echo $"Networking not configured - exiting" && exit 1
        wget --quiet -o /dev/null http://mirrors.aliyun.com/repo/Centos-${OS_VERSION}.repo
        #wget --quiet -o /dev/null http://mirrors.aliyun.com/repo/Centos-7.repo
        \cp Centos-${OS_VERSION}.repo CentOS-Base.repo
        format
}
####################Install Init Packages###########################
installTool(){
        echo "sysstat ntp net-snmp lrzsz rsync net-tools tcpdump"
        yum -y install vim wget dmidecode sysstat ntp net-snmp lrzsz rsync zip unzip &> /tmp/yum.log
        format
}
######################Close Selinux and Iptables#####################
initFirewall(){
        echo "#Cloese Selinux and Iptables"
        \cp /etc/selinux/config /etc/selinux/config.`date +"%Y-%m-%d_%H-%M-%S"`
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
        setenforce 0
        if [ ${OS_VERSION} -eq 6 ];then
            /etc/init.d/iptables stop
            /etc/init.d/iptables status
        else
            systemctl stop firewalld.service
            systemctl disable firewalld.service
        fi
        grep SELINUX=disabled /etc/selinux/config
        echo "Close selinux->OK and iptables->OK"
        format
}
#####################Init Auto Startup Service#######################
initService(){
        if [ ${OS_VERSION} -eq 6 ];then
            echo "Close Nouseful Service"
            export LANG=en_US.UTF-8
            for service in `chkconfig --list|grep 3:on|awk '{print $1}'`;do chkconfig --level 3 $service off;done
            for service in crond network rsyslog sshd zabbix_agentd;do chkconfig --level 3 $service on;done
            #export LANG="zh_CN.GB18030"
            echo "Close Nouseful Service->OK"
            format
        else
            echo ">>>>>"
        fi
}
######################Init Hostname #################################
initHostName(){
        echo -e """Set hostname for example:
平台例子：bj-ail-g1-tchat9187-01 
          地点-IDC-分组-应用名称-编号
            """
#read  -p "please input hostname :" systemname
if [ ${OS_VERSION} -eq 6 ];then
    IP=`ifconfig eth0|grep inet|awk -F "[ :]" '{print $13}'`
else
    IP=`ip addr|grep global |awk -F "[ :/]" '{print $6}'`
fi
/bin/hostname $HOSTNAME
\cp /etc/hosts /etc/hosts.$(date +%U%T)
echo -e "\n$IP $HOSTNAME" >>/etc/hosts
sed -i.bak  "s/^HOSTNAME.*/HOSTNAME=$HOSTNAME/g" /etc/sysconfig/network
if [ ${OS_VERSION} -eq 7 ];then
    hostnamectl set-hostname $HOSTNAME
fi
format
}
############################Init Service ssh###########################
initSsh(){
        echo "----------sshConfig----------"
        \cp /etc/ssh/sshd_config /etc/ssh/sshd_config.`date +"%Y-%m-%d_%H-%M-%S"`
        sed -i.bak 's/#PubkeyAuthentication/PubkeyAuthentication/' /etc/ssh/sshd_config
        sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config
        sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
	sed -i 's%#Port 22%Port 8022%' /etc/ssh/sshd_config
        egrep "Port|AuthorizedKeysFile|PubkeyAuthentication|PasswordAuthentication" /etc/ssh/sshd_config
mkdir /root/.ssh
touch /root/.ssh/authorized_keys
#maliqun-key
cat <<EOF >>/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAv85Gt41esMoVqkl8uwdWPsR+Ep3MeGaGONkIE0CMQCmyXXmvOKLrryFIRbZo4jFbUlC+cCc+cCnb0EcSrFyz4v1+V8tyJjJUAT4f2mBvcRBz7xKDLo0YbbnliWP3ohV0QQcih8/rPByV4qRWo7SAZgAjQ+TOq3c3Cd1BtHG3XEACg0H1roa0Id6PwG5p7buLlONAJ24apsSEuS3+oOprc7d1EcSsHgaEUSNf2u4pRG1F3t/af7U19oruRLTTqRBiryZpvNs/9b16Ux7pi97u/QGmVyW4OZzyInOQYNUyBBhVRGH0jGD/aEmc4WxH8CtgRSTqhLUlWUQquejiHDMHkQ== maliqun@cctv.cn
EOF
#lixianlei-key
cat <<EOF >>/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxKRPTWzoHE5H3IeSEF266OR0ujLQgusu6MEvgdBuo0guFnr96GRsrHXY8n+O8jrjCKl/IQQFP0OkYOxUemrndXVszZtjk2ocrt97FrBc8VWURMzMbjDE2eLBsRE0y2DwRv33S6XwSip6eLKe2m4DyoSfxg0o2xnqE4L5BjQKzvU4ubVWoGBfg+EMikXIsS/OfxMy9Tfk1eAoB/3GtrndROdg3l84hzHwgta6lXSJ7KS0cKbvTzoJqC4A0H7X1+jwuhmw3rpRDNGfQfKbXaPPJvb6FTX5EkETyRtRY8xIjMUUBO6ieKYADlOB/UL6U5rfuIzLJEjmja82+8I9dU3TV lixianlei@cctv.cn
EOF
#liujun-key
cat <<EOF >>/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwjc8qAQRiQUicOTOKpywV9wYWpE8wbDydU2DjqyLw+NDuKep1kXxPCKOL8hiIpLZOwp52/Xnjk3Zjhbf4lyz/x0wBujqw/jMCKHEnMy3bJ0kphYvUEmVLP0ktXQICZtB0PPQIJkv9DtDeRWZ7ruPiuBzMOS7Fa0chR6RsBNTj+ynPcdeSzPjq8pwgPS89qV9zRjfLXaeHEMQHrM8PZLfj5xV04qBVmUnE51LejsJIz5BTaKorV7nQozu1aPMGFC1v0f7q7OMF1loYwuqM0/40cI+q03VPcBvvEZmeuu8BaVe30tp5vcw52FdUulIAMQ7vVIk39QvZvR0BKDDmpFe5Q== liujun@cctv.cn
EOF
#duanguanyang-key
cat <<EOF >>/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyh+/c5QbgWxOPsq4T3oO7hkleNTj6xrtQSAxd1VvmPADwvlnmkomPvy5hQkBeIu6onM3Gd6xr2MejyLLUWpgmiDlASiR//P2jRlfrEw53+KC3HODtNI5f+IZqmCw+YI+dOZRSzkYda3PhuAzC7QeWLmKDuLGGPqNCl72aOHVZEfdJoJ/AyQnBm6FUOApztT4btZIoZNa8fzOml5YF/vFWlS8wjtxfJdc7xGqiboyo6MLIwo0LepquVZkc+n6j491aT2WHRd5JygmSuwUtLh+mhRMQeEPPtysYq1PXjUK8cbv9cFfkwJ4oyf8RJFQO5FdndmnvaTuQbMffaZeRjMXKw== duanguanyang@cctv.cn
EOF
#zhaochenglin-key
cat <<EOF >>/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAv97ftJovy9QL4rfLuqGXFsTTiM5LOHgfd/OX0p1btgmE7uj5/fgvMmgtLqTFrDiTAdUN4ETCVqBfPv0zl2l+2YFOTXCmiWiuSd5EnOQN7zBITF2TvZJ/EkBNzKeH/1+mm27BfRPusQ1ii9p9hHglqc+OVeujR3DSRU7yXSCrOx8Qkwx0X7rPMu2r71Dfu337a3ItCk9yLRKCI1oM7dzLimmjL93Zan6xx8RnPo7YI1DE7hU5jGetq2oiiTuTaRRZP/ToXehgvT7O5UHEue7bf+gM1lTeCpmiaRaB1ud1Jtc8sPocjFH0FH/BkWnrMyiKBBLRAu9n9/JFZy0Gxh8zyw== zhaochenglin@cctv.cn
EOF
#jixiang-key
cat <<EOF >>/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwJnqB1yVquoivJl2+v2ScLRATQeGIA9pUvYjxsV5WHy/wqkRkro9TkcGJaUQqa0LUupkkGGOH3GsyhktotV0srmookPtrlNd5j5oW7cgPTjfcvUkpoBkJX6WY7lgIHHvyc6XsnNEXfl5KH/2kTVM3FgCv+mWvvE8KkEi6yxLYEQ4OiKmdHR/Qkdofd1kx2ysg0SPsWS/Tgz3Esn4jx4raZu5G0zmT7ouFQ+NauI2oHNqW3876M8qnY4LpkjwJ6S76u+YzMM+vQgJL6E4Jq3009goBR8LF9EfTd/cfZsgli6HjhGNa4Ykm3vfucSeaLV6ogCZZmpJ5IQ67VUSbB5Akw== jixiang@cctv.cn
EOF
#yangruizeng-key
cat <<EOF >>/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyPwd0E+ld+gonxe5ent4v21Egs2FZ9Wuu1giUI3PdYmtvhaLobqvrLao44SF2lyQxUId0o2kYd+vuzgfp0fBxjC+9w0/SMvivU4otWDrbLGTi6+MhSBS7i3qqCWOcGl4aNVEnnaTJFnIb373TQAEYVFbsNQ3IhZG4RRyV08frSKBl/A7NfSA7O7ctsbN/tylCfK04bq1ZHqjK5MIfzB/f9WSOFfSfdvQRa3symwGMhpM1qL2YiCy0O7+iJfCTdcrNejb9Idf25w6TVcBsmNpqYepYa8EE64XqCrkNnhD4tT9Q9sKKvjEjL+R0+jaWqYAc1YigBETyRmJ9YvI1wnEPw== yangruizeng@cctv.cn
EOF
#zhangkai-key
cat <<EOF >>/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDB5CWNcKWi93lwX4XA1fSqna7hCxAID8NAu4pdKGoIfgj8lEa7hQT1CyfBrNlvBMhG5b8Uby0/YDPrnfE9i7RMFj3QN9YLUOXmJnwAXJKmnq+EjReoTrXz2Gd7NzsF3EE7Iqo3+hgkehknLgj+yzeSMhhbyBdYW3NbgxgvPzNonhk8rSPdHAGrRNhrnjsSvgESNG93o6HhqU2nwLr61EVMLFId5rXjaDeCIExikBiHxjCjZNttCNZSTZK2JPqWq3t/6Oeeh3L2Yvihab8wYNQZz8HfEHeoSkOvO8Bf2hSvEzpViUZgAzIxZOxnOUKUNYUckVukb5mGXKmD+7Ez+thF fengx_Mac
EOF
#xinxin-key
cat <<EOF >>/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6N4LptIQHrd6SptZ5po02eesysaPTTgxjoNOYvIfVLPXwpAyM2gd38iipOTy7wuNgCq0riWJj11QyRlns0qf9XW30NxfMTlzMfPPNTYWfjqUxh5V28xjzFGAYNus1mqSjj7mNaFFd5hQt7iT9byZPtU5NYpINzmLEF+/EUHI6C92Bhl/31i+nWPQ/kO/mJDoZ0SYOMDdrMgNAP/4xU0VplxNmZP5SA4u7SixSnQQXWmZXeItX5t5cjfOcB8SMQa6RZhS45azl3Da6mZz3HezeRdcwaiQAEM0Kzhp0EAE1fUdnCHd55dVZsEOrnWNNqMDEh4Bm4POik0l5jSiT2hRPQ== xinxin@cctv.cn
EOF
chmod 600 /root/.ssh/authorized_keys
chmod 700 /root/.ssh/
        if [ ${OS_VERSION} -eq 7 ];then
            systemctl restart crond
            systemctl restart sshd.service
            systemctl enable  sshd.service
        else
            /etc/init.d/sshd reload && action $"--sshConfig--" /bin/true||action $"--sshConfig--" /bin/false
        fi
echo -e "Add lixianlei  liujun duanguanyang zhaochenglin jixiang yangruizeng  key successful --- OK "
        format
}
##############################Change root's password###############################
C_PASSWORD() {
echo "----------------Start Change Root Pass------------------------"
echo $PASSWD | passwd --stdin root &> /dev/null
echo  "--- Password for root changed to $PASSWD --- OK  "
format
}
##############################Add Prod User########################################
ADD_USER(){
        echo "Start add user prod"
        useradd -u 1000 prod
        echo "1nqq,,id"|passwd prod --stdin
        format
}
##############################Set Ntp Time########################################
syncSystemTime(){
        echo "##########Set Ntp Time###########"
        #同步时间
        #if [  `grep ntpdate /var/spool/cron/root|grep -v grep |wc -l` -lt 1  ];then
        #    echo "*/5 * * * * /usr/sbin/ntpdate cn.pool.ntp.org >/dev/null 2>&1" >>/var/spool/cron/root
        #fi
        cp  /usr/share/zoneinfo/Asia/Chongqing  /etc/localtime
        printf 'ZONE="Asia/Chongqing"\nUTC=false\nARC=false' > /etc/sysconfig/clock
        /usr/sbin/ntpdate pool.ntp.org
        echo "* */5 * * * /usr/sbin/ntpdate pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/root;chmod 600 /var/spool/cron/root
        echo 'LANG="en_US.UTF-8"' > /etc/sysconfig/i18n
        source  /etc/sysconfig/i18n
        format
}
##############################Set Open File#####################################
openFiles(){
        echo "------------Set Open File 65535-------------------"
        \cp /etc/security/limits.conf /etc/security/limits.conf.`date +"%Y-%m-%d_%H-%M-%S"`
		\cp /etc/systemd/system.conf /etc/systemd/system.conf.`date +"%Y-%m-%d_%H-%M-%S"`
		\cp /etc/security/limits.d/20-nproc.conf /etc/security/limits.d/20-nproc.conf.`date +"%Y-%m-%d_%H-%M-%S"`
        ulimit -HSn 102400
        echo "#config  openFile num"
        echo "ulimit -SHn 102400" >> /etc/rc.local
cat >> /etc/security/limits.conf << EOF
*           soft   nproc        102400
*           hard   nproc        102400
EOF
sed -i 's#65535#102400#g' /etc/security/limits.conf
sed -i 's#4096#102400#g' /etc/security/limits.d/20-nproc.conf 
cat >> /etc/systemd/system.conf  << EOF
DefaultLimitCORE=infinity
DefaultLimitNOFILE=100000
DefaultLimitNPROC=100000
EOF
        echo "调整最大打开系统文件个数成功！（修改后重新登录生效）"
        format
}
###########################Kernel optimization###################################
optimizationKernel(){
        echo "Kernel optimization----->"
        \cp /etc/sysctl.conf /etc/sysctl.conf.`date +"%Y-%m-%d_%H-%M-%S"`
cat <<EOF >/etc/sysctl.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 1024 65535

vm.swappiness=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_congestion_control=cubic
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_tw_recycle=1
net.ipv4.tcp_max_syn_backlog=65535
net.core.somaxconn=65535
net.core.rmem_max=16777216
net.core.wmem_max=16777216
vm.overcommit_memory=1

fs.file-max = 2097152
fs.nr_open = 2097152
net.core.somaxconn = 32768
net.ipv4.tcp_max_syn_backlog = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.ip_local_port_range = 1024 65535

net.ipv4.tcp_mem = 786432 2097152 3145728

net.ipv4.tcp_rmem=4096 4096 32768
net.ipv4.tcp_wmem=4096 4096 32768
net.core.rmem_default=65536
net.core.wmem_default=65536
net.core.rmem_max=4194304
net.core.wmem_max=4197304
net.core.optmem_max=4194304

net.ipv4.tcp_max_tw_buckets = 1048576
net.ipv4.tcp_fin_timeout = 30

net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.eth0.rp_filter = 0 
EOF
/sbin/sysctl -p && action $"Kerneloptimization：" /bin/true||action $"Kernel optimization：" /bin/false
format
}
##############################Config Dns Server##############################
C_DNS(){
echo "--- Start Set DNS   ---"
echo "nameserver $MASTER_DNS" > /etc/resolv.conf
echo "nameserver $SLAVE_DNS" >>/etc/resolv.conf
echo -e "--- Set dns $MASTER_DNS AND $SLAVE_DNS --- OK "
}
mount_disk() {
yum -y install xfsprogs
echo -e "n\np\n\n\n\nw"|fdisk /dev/vdb
mkfs.xfs -fn ftype=1  /dev/vdb1
echo "/dev/vdb1 /opt  xfs  defaults        1 1" >> /etc/fstab
mount /dev/vdb1 /opt
}

installTool
initFirewall
initService
initSsh
openFiles
optimizationKernel
mount_disk
