#!/bin/bash

#
# Check if user is root
#
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

if [ ! -f /etc/debian_version ]; then 
    echo "Unsupported Linux Distribution. Prepared for Debian"
    exit 1
fi

#############################################################################
# What do we need anyway
apt-get update
apt-get -y upgrade
apt-get -y install dnsutils unzip whiptail git build-essential alsa-base alsa-utils stunnel4 html2text

install_basic (){
#############################################################################
# Set hostname, FQDN, add to sources list

sed -e 's/127.0.0.1       localhost/127.0.0.1       localhost.localdomain   localhost/g' -i /etc/hosts
cat >> /etc/hosts <<EOF
${serverIP} ${HOSTNAMEFQDN} ${HOSTNAMESHORT}
EOF

echo "$HOSTNAMESHORT" > /etc/hostname
/etc/init.d/hostname.sh start >/dev/null 2>&1

# add tvheadend repo and key
if !(grep -qs tvheadend "/etc/apt/sources.list");then
cat >> /etc/apt/sources.list <<EOF
# TV headend
deb http://apt.tvheadend.org/stable wheezy main
EOF
wget -qO - http://apt.tvheadend.org/stable/repo.gpg.key | apt-key add -
apt-get update
fi
}
#############################################################################

install_samba (){
#############################################################################
# install Samba file sharing
apt-get -y install samba samba-common-bin
useradd $SMBUSER
echo -ne "$SMBPASS\n$SMBPASS\n" | passwd $SMBUSER
echo -ne "$SMBPASS\n$SMBPASS\n" | smbpasswd -a -s $SMBUSER
service samba stop
 cat > /etc/samba/smb.conf <<"EOF"
[global]
	workgroup = SMBGROUP
	server string = %h server
	hosts allow = SUBNET
	log file = /var/log/samba/log.%m
	max log size = 1000
	syslog = 0
	panic action = /usr/share/samba/panic-action %d
	load printers = yes
	printing = cups
	printcap name = cups

[printers]
	comment = All Printers
	path = /var/spool/samba
	browseable = no
	public = yes
	guest ok = yes
	writable = no
	printable = yes
	printer admin = SMBUSER

[print$]
	comment = Printer Drivers
	path = /etc/samba/drivers
	browseable = yes
	guest ok = no
	read only = yes
	write list = SMBUSER
	
[ext]
	comment = Storage	
	path = /ext
	writable = yes
	public = no
	valid users = SMBUSER
	force create mode = 0777
	force directory mode = 0777
EOF
sed -i "s/SMBGROUP/$SMBGROUP/" /etc/samba/smb.conf
sed -i "s/SMBUSER/$SMBUSER/" /etc/samba/smb.conf
sed -i "s/SUBNET/$SUBNET/" /etc/samba/smb.conf
mkdir /ext
chmod -R 777 /ext
service samba start
}
#############################################################################

install_cups (){
#############################################################################
#Install printer system
apt-get -y install cups lpr foomatic-filters
sed -e 's/Listen localhost:631/Listen 631/g' -i /etc/cups/cupsd.conf
sed -e 's/<Location \/>/<Location \/>\nallow $SUBNET/g' -i /etc/cups/cupsd.conf
sed -e 's/<Location \/admin>/<Location \/admin>\nallow 172.16.100./g' -i /etc/cups/cupsd.conf
sed -e 's/<Location \/admin\/conf>/<Location \/admin\/conf>\nallow 172.16.100./g' -i /etc/cups/cupsd.conf
service cups restart
service samba restart
} 
#############################################################################

install_temper (){
#############################################################################
#Install USB temperature sensor
apt-get -y install libusb-dev libusb-1.0-0-dev
wget https://github.com/igorpecovnik/Debian-micro-home-server/blob/master/src/temper_v14_altered.tgz
tar xvfz temper_v14_altered.tgz
cd temperv14
make
make rules-install
cp temperv14 /usr/bin/temper
} 
#############################################################################

install_scaner_and_scanbuttons (){
#############################################################################
#Install Scanner buttons
apt-get -y install pdftk libusb-dev sane sane-utils libudev-dev imagemagick 
# wget http://wp.psyx.us/wp-content/uploads/2010/10/scanbuttond-0.2.3.genesys.tar.gz
wget https://github.com/igorpecovnik/Debian-micro-home-server/blob/master/src/scanbuttond-0.2.3.genesys.tar.gz
tar xvfz scanbuttond-0.2.3.genesys.tar.gz
rm scanbuttond-0.2.3.genesys.tar.gz
cd scanbuttond-0.2.3.genesys
chmod +x configure
make clean 
./configure --prefix=/usr --sysconfdir=/etc
make
make install
echo "sane-find-scanner" >> /etc/scanbuttond/initscanner.sh
sed -e 's/does nothing./does nothing.\n\/usr\/bin\/scanbuttond/g' -i /etc/rc.local
} 
#############################################################################

install_ocr (){
#############################################################################
# Install OCR
# get script from here https://github.com/gkovacs/pdfocr
wget https://raw2.github.com/gkovacs/pdfocr/master/pdfocr.rb
mv pdfocr.rb /usr/local/bin/pdfocr
chmod +x /usr/local/bin/pdfocr
apt-get -y install ruby tesseract-ocr libtiff-tools
} 
#############################################################################

install_btsync (){
#############################################################################
# Install Personal cloud
# 
wget http://download.getsyncapp.com/endpoint/btsync/os/linux-arm/track/stable/btsync_arm.tar.gz
tar xvfz btsync_arm.tar.gz
mv btsync /usr/local/bin
ln -sf /lib/ld-linux-armhf.so.3 /lib/ld-linux.so.3
chmod +x /usr/local/bin/btsync
sed -e 's/exit 0//g' -i /etc/rc.local
cat >> /etc/rc.local <<"EOF"
/usr/local/bin/btsync
exit 0
EOF
} 
#############################################################################

install_vpn_server (){
#############################################################################
# valid only for ARM installation, script downloads latest stable
PREFIX="http://www.softether-download.com/files/softether/"
URL=$(wget -q $PREFIX -O - | html2text | grep rtm | awk ' { print $(NF) }' | tail -1)
SUFIX="${URL/-tree/}"
DLURL=$PREFIX$URL"/Linux/SoftEther%20VPN%20Server/32bit%20-%20ARM%20EABI/softether-vpnserver-$SUFIX-linux-arm_eabi-32bit.tar.gz"
wget $DLURL
tar xfz softether-vpnserver-$SUFIX-linux-arm_eabi-32bit.tar.gz
rm softether-vpnserver-$SUFIX-linux-arm_eabi-32bit.tar.gz
cd vpnserver
make i_read_and_agree_the_license_agreement
cd ..
cp -R vpnserver /usr/local
cd /usr/local/vpnserver/
chmod 600 *
chmod 700 vpncmd
chmod 700 vpnserver
cat <<EOT > /etc/init.d/vpnserver
#!/bin/sh
### BEGIN INIT INFO
# Provides:          vpnserver
# Required-Start:    \$remote_fs \$syslog
# Required-Stop:     \$remote_fs \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable Softether by daemon.
### END INIT INFO
DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/vpnserver
test -x $DAEMON || exit 0
case "\$1" in
start)
\$DAEMON start
touch \$LOCK
;;
stop)
\$DAEMON stop
rm \$LOCK
;;
restart)
\$DAEMON stop
sleep 3
\$DAEMON start
;;
*)
echo "Usage: \$0 {start|stop|restart}"
exit 1
esac
exit 0
EOT
chmod 755 /etc/init.d/vpnserver
mkdir /var/lock/subsys
update-rc.d vpnserver defaults
/etc/init.d/vpnserver start
}
#############################################################################

install_DashNTP (){
#############################################################################
echo "dash dash/sh boolean false" | debconf-set-selections
dpkg-reconfigure -f noninteractive dash > /dev/null 2>&1

#Synchronize the System Clock
apt-get -y install ntp ntpdate

} #end function install_DashNTP
#############################################################################

install_MySQLDovecot (){
#############################################################################
#Install Postfix, Dovecot, Saslauthd, MySQL, phpMyAdmin, rkhunter, binutils
echo "mysql-server-5.5 mysql-server/root_password password $mysql_pass" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $mysql_pass" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections

apt-get -y install postfix postfix-mysql postfix-doc mysql-client mysql-server openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve sudo libsasl2-modules

#Uncommenting some Postfix configuration files
cp /etc/postfix/master.cf /etc/postfix/master.cf.backup
sed -i 's|#submission inet n       -       -       -       -       smtpd|submission inet n       -       -       -       -       smtpd|' /etc/postfix/master.cf
sed -i 's|#  -o syslog_name=postfix/submission|  -o syslog_name=postfix/submission|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_tls_security_level=encrypt|  -o smtpd_tls_security_level=encrypt|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#smtps     inet  n       -       -       -       -       smtpd|smtps     inet  n       -       -       -       -       smtpd|' /etc/postfix/master.cf
sed -i 's|#  -o syslog_name=postfix/smtps|  -o syslog_name=postfix/smtps|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_tls_wrappermode=yes|  -o smtpd_tls_wrappermode=yes|' /etc/postfix/master.cf

#Allow MySQL to listen on all interfaces
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
sed -i 's|bind-address           = 127.0.0.1|#bind-address           = 127.0.0.1|' /etc/mysql/my.cnf

/etc/init.d/postfix restart
/etc/init.d/mysql restart

} #end function install_MySQLDovecot
#############################################################################

install_Virus (){
#############################################################################
#Install Amavisd-new, SpamAssassin, And Clamav
apt-get -y install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl
/etc/init.d/spamassassin stop
insserv -rf spamassassin
}
#############################################################################

install_Apache (){
#############################################################################
clear_console
echo "========================================================================="
echo "You will be prompted for some information during the install of phpmyadmin."
echo "Select NO when asked to configure using dbconfig-common"
echo "Please enter them where needed."
echo "========================================================================="
echo "Press ENTER to continue.."
read DUMMY

#Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt

echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
#BELOW ARE STILL NOT WORKING
#echo 'phpmyadmin      phpmyadmin/dbconfig-reinstall   boolean false' | debconf-set-selections
#echo 'phpmyadmin      phpmyadmin/dbconfig-install     boolean false' | debconf-set-selections

apt-get -y install apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-ruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached

a2enmod suexec rewrite ssl actions include
a2enmod dav_fs dav auth_digest

#Fix Ming Error
rm /etc/php5/cli/conf.d/ming.ini
cat > /etc/php5/cli/conf.d/ming.ini <<"EOF"
extension=ming.so
EOF

#Fix SuPHP
cp /etc/apache2/mods-available/suphp.conf /etc/apache2/mods-available/suphp.conf.backup
rm /etc/apache2/mods-available/suphp.conf
cat > /etc/apache2/mods-available/suphp.conf <<"EOF"
<IfModule mod_suphp.c>
    #<FilesMatch "\.ph(p3?|tml)$">
    #    SetHandler application/x-httpd-suphp
    #</FilesMatch>
        AddType application/x-httpd-suphp .php .php3 .php4 .php5 .phtml
        suPHP_AddHandler application/x-httpd-suphp

    <Directory />
        suPHP_Engine on
    </Directory>

    # By default, disable suPHP for debian packaged web applications as files
    # are owned by root and cannot be executed by suPHP because of min_uid.
    <Directory /usr/share>
        suPHP_Engine off
    </Directory>

# # Use a specific php config file (a dir which contains a php.ini file)
#       suPHP_ConfigPath /etc/php5/cgi/suphp/
# # Tells mod_suphp NOT to handle requests with the type <mime-type>.
#       suPHP_RemoveHandler <mime-type>
</IfModule>
EOF

#Enable Ruby Support
sed -i 's|application/x-ruby|#application/x-ruby|' /etc/mime.types

#Install XCache
apt-get -y install php5-xcache



#Restart Apache
/etc/init.d/apache2 restart

}
#############################################################################

install_NginX (){
#############################################################################
#Install NginX, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt

echo 'phpmyadmin      phpmyadmin/reconfigure-webserver        multiselect' | debconf-set-selections
echo 'phpmyadmin      phpmyadmin/dbconfig-install     boolean false' | debconf-set-selections

apt-get install -y nginx
/etc/init.d/apache2 stop
update-rc.d -f apache2 remove
/etc/init.d/nginx start

apt-get install -y php5-fpm
apt-get install -y php5-mysql php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached
apt-get install -y php-apc
#PHP Configuration Stuff Goes Here
apt-get install -y fcgiwrap

echo "========================================================================="
echo "You will be prompted for some information during the install of phpmyadmin."
echo "Please enter them where needed."
echo "========================================================================="
echo "Press ENTER to continue.."
read DUMMY

DEBIAN_FRONTEND=noninteractive apt-get install -y dbconfig-common
apt-get install -y phpmyadmin

#Remove the Apache2 Stuff for NginX
/etc/init.d/apache2 stop
insserv -r apache2
/etc/init.d/nginx start

#Fix Ming Error
rm /etc/php5/cli/conf.d/ming.ini
cat > /etc/php5/cli/conf.d/ming.ini <<"EOF"
extension=ming.so
EOF

/etc/init.d/php5-fpm restart

}
#############################################################################

install_PureFTPD (){
#############################################################################
#Install PureFTPd
apt-get -y install pure-ftpd-common pure-ftpd-mysql

#Setting up Pure-Ftpd
sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
echo 1 > /etc/pure-ftpd/conf/TLS
mkdir -p /etc/ssl/private/

openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -subj "/C=/ST=/L=/O=/CN=$(hostname -f)" -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
chmod 600 /etc/ssl/private/pure-ftpd.pem
/etc/init.d/pure-ftpd-mysql restart

}
#############################################################################

#############################################################################
install_Bind (){
#############################################################################
#Install BIND DNS Server
apt-get -y install bind9 dnsutils
}
#############################################################################

install_Stats (){
#############################################################################
#Install Vlogger, Webalizer, And AWstats
apt-get -y install vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl

sed -i "s/*/10 * * * * www-data/#*/10 * * * * www-data/" /etc/cron.d/awstats
sed -i "s/10 03 * * * www-data/#10 03 * * * www-data/" /etc/cron.d/awstats

}
#############################################################################

install_Fail2BanDovecot() {
#############################################################################
#Install fail2ban
apt-get -y install fail2ban

cat > /etc/fail2ban/jail.local <<"EOF"
[pureftpd]
enabled  = true
port     = ftp
filter   = pureftpd
logpath  = /var/log/syslog
maxretry = 3

[dovecot-pop3imap]
enabled = true
filter = dovecot-pop3imap
action = iptables-multiport[name=dovecot-pop3imap, port="pop3,pop3s,imap,imaps", protocol=tcp]
logpath = /var/log/mail.log
maxretry = 5

[sasl]
enabled  = true
port     = smtp
filter   = sasl
logpath  = /var/log/mail.log
maxretry = 3
EOF

}
#############################################################################

install_Fail2BanRulesDovecot() {
#############################################################################
cat > /etc/fail2ban/filter.d/pureftpd.conf <<"EOF"
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/dovecot-pop3imap.conf <<"EOF"
[Definition]
failregex = (?: pop3-login|imap-login): .*(?:Authentication failure|Aborted login \(auth failed|Aborted login \(tried to use disabled|Disconnected \(auth failed|Aborted login \(\d+ authentication attempts).*rip=(?P<host>\S*),.*
ignoreregex =
EOF
/etc/init.d/fail2ban restart
}
#############################################################################

install_ISPConfig (){
#############################################################################
#Install ISPConfig 3
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
rm ISPConfig-3-stable.tar.gz
cd /tmp/ispconfig3_install/install/
php -q install.php
} 
#############################################################################

SECTION="Basic configuration"
#
# Read IP address
#
serverIP=$(ip route get 8.8.8.8 | awk '{ print $NF; exit }')
serverIP=$(whiptail --inputbox "What is your IP?" 8 78 $serverIP --title "$SECTION" 3>&1 1>&2 2>&3)
set ${serverIP//./ }
SUBNET="$1.$2.$3."
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi

#
# Read full qualified hostname
#
HOSTNAMEFQDN=$(hostname -f)
HOSTNAMEFQDN=$(whiptail --inputbox "What is your full qualified hostname?" 8 78 $HOSTNAMEFQDN --title "$SECTION" 3>&1 1>&2 2>&3)
set ${HOSTNAMEFQDN//./ }
HOSTNAMESHORT="$1"
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi

#
# Read MYSQL pass
#
mysql_pass=$(whiptail --inputbox "What is your mysql root password?" 8 78 $mysql_pass --title "$SECTION" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi

#
# Reade samba user
#
SMBUSER=$(whiptail --inputbox "What is your samba username?" 8 78 $SMBUSER --title "$SECTION" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
#
# Reade samba pass
#
SMBPASS=$(whiptail --inputbox "What is your samba password?" 8 78 $SMBPASS --title "$SECTION" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
#
# Reade samba group
#
SMBGROUP=$(whiptail --inputbox "What is your samba group?" 8 78 $SMBGROUP --title "$SECTION" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi

install_basic
install_DashNTP
install_MySQLDovecot
install_Virus
#install_Apache
install_NginX
install_PureFTPD
install_Fail2BanDovecot
install_Fail2BanRulesDovecot
install_samba
install_scaner_and_scanbuttons
install_ocr
install_cups
install_btsync
install_temper
install_vpn_server
apt-get -y install tvheadend
apt-get -y install transmission-cli transmission-common transmission-daemon
install_ISPConfig
               


