#!/bin/bash
#
# (c) Igor Pecovnik
# 


install_basic (){
#--------------------------------------------------------------------------------------------------------------------------------
# Set hostname, FQDN, add to sources list
#--------------------------------------------------------------------------------------------------------------------------------
cp /etc/hosts /etc/hosts.backup
cp /etc/hostname /etc/hostname.backup
sed -e 's/127.0.0.1       localhost/127.0.0.1       localhost.localdomain   localhost/g' -i /etc/hosts
cat >> /etc/hosts <<EOF
${serverIP} ${HOSTNAMEFQDN} ${HOSTNAMESHORT}
EOF
echo "$HOSTNAMESHORT" > /etc/hostname
/etc/init.d/hostname.sh start >/dev/null 2>&1
}


create_ispconfig_configuration (){
#--------------------------------------------------------------------------------------------------------------------------------
# ISPConfig autoconfiguration
#--------------------------------------------------------------------------------------------------------------------------------
cat > /tmp/isp.conf.php <<EOF
<?php
\$autoinstall['language'] = 'en'; // de, en (default)
\$autoinstall['install_mode'] = 'standard'; // standard (default), expert

\$autoinstall['hostname'] = '$HOSTNAMEFQDN'; // default
\$autoinstall['mysql_hostname'] = 'localhost'; // default: localhost
\$autoinstall['mysql_root_user'] = 'root'; // default: root
\$autoinstall['mysql_root_password'] = '$mysql_pass';
\$autoinstall['mysql_database'] = 'dbispconfig'; // default: dbispcongig
\$autoinstall['mysql_charset'] = 'utf8'; // default: utf8
\$autoinstall['http_server'] = '$server'; // apache (default), nginx
\$autoinstall['ispconfig_port'] = '8080'; // default: 8080
\$autoinstall['ispconfig_use_ssl'] = 'y'; // y (default), n

/* SSL Settings */
\$autoinstall['ssl_cert_country'] = 'AU';
\$autoinstall['ssl_cert_state'] = 'Some-State';
\$autoinstall['ssl_cert_locality'] = 'Chicago';
\$autoinstall['ssl_cert_organisation'] = 'Internet Widgits Pty Ltd';
\$autoinstall['ssl_cert_organisation_unit'] = 'IT department';
\$autoinstall['ssl_cert_common_name'] = \$autoinstall['hostname'];
?>
EOF
}


install_sugarcrm (){
#--------------------------------------------------------------------------------------------------------------------------------
# Community edition CRM
#--------------------------------------------------------------------------------------------------------------------------------
cd /tmp
wget http://downloads.sourceforge.net/project/sugarcrm/1%20-%20SugarCRM%206.5.X/WebPI/SugarCE-6.5.18-WebPI.zip
unzip SugarCE-6.5.18-WebPI.zip
cd SugarCE-Full-6.5.18
mv * /usr/share/nginx/www
}


install_varnish (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install high-performance HTTP accelerator
#-------------------------------------------------------------------------------------------------------------------------------- 
apt-get -y -qq install python-docutils python-sphinx automake autotools-dev libjemalloc-dev libtool pkg-config libncurses-dev libpcre3-dev libedit-dev
git clone https://github.com/varnish/Varnish-Cache /tmp/varnish
cd /tmp/varnish
./autogen.sh
./configure
make && make install
}


install_rpimonitor (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install rpimonitor with custom config
#--------------------------------------------------------------------------------------------------------------------------------
if !(grep -qs XavierBerger "/etc/apt/sources.list");then
cat >> /etc/apt/sources.list <<EOF
# RPi-Monitor official repository
deb https://github.com XavierBerger/RPi-Monitor-deb/raw/master/repo/
EOF
fi
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2C0D3C0F
debconf-apt-progress -- apt-get update
debconf-apt-progress -- apt-get -y install rpimonitor
service rpimonitor stop
# add my own configuration which is not default
cd /etc/rpimonitor
wget https://github.com/igorpecovnik/Debian-micro-home-server/blob/next/src/rpimonitor-myconfig.tgz?raw=true -O - | tar -xhz
cd /usr/local/bin
wget https://github.com/igorpecovnik/Debian-micro-home-server/blob/next/src/temp-pir-daemon.sh?raw=true -O temp-pir-daemon.sh
chmod +x /usr/local/bin/temp-pir-daemon.sh
sed -e 's/exit 0//g' -i /etc/rc.local
cat >> /etc/rc.local <<"EOF"
nohup /usr/local/bin/temp-pir-daemon.sh &
exit 0
EOF
rm -rf /var/lib/rpimonitor/stat
mkdir -p /var/log/rpimonitor
nohup /usr/local/bin/temp-pir-daemon.sh &
service rpimonitor start
/usr/share/rpimonitor/scripts/updatePackagesStatus.pl
}


install_bmc180 (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install temp and pressure sensor read utility
#-------------------------------------------------------------------------------------------------------------------------------- 
cd /tmp
git clone https://github.com/maasdoel/bmp180
cd bmp180
# let's change bus number to suits our need
sed -i "s/dev\/i2c-1/dev\/i2c-2/" bmp180dev3.c
gcc -Wall -o bmp180 ./bmp180dev3.c -lm
cp bmp180 /usr/local/bin
rm -r /tmp/bmp180
}


install_tsl2561 (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install light sensor read utility
#--------------------------------------------------------------------------------------------------------------------------------
cd /tmp
wget https://github.com/igorpecovnik/Debian-micro-home-server/blob/next/src/tsl2561-src.tgz?raw=true -O - | tar -xz
gcc -Wall -O2 -o TSL2561.o -c TSL2561.c
gcc -Wall -O2 -o TSL2561_test.o -c TSL2561_test.c
gcc -Wall -O2 -o TSL2561_test TSL2561.o TSL2561_test.o
cp TSL2561_test /usr/local/bin/tsl2561
}


install_tvheadend (){
#--------------------------------------------------------------------------------------------------------------------------------
# TVheadend
#--------------------------------------------------------------------------------------------------------------------------------
if !(grep -qs tvheadend "/etc/apt/sources.list");then
cat >> /etc/apt/sources.list <<EOF
# TV headend
deb http://apt.tvheadend.org/stable wheezy main
EOF
fi
wget -qO - http://apt.tvheadend.org/stable/repo.gpg.key | apt-key add -
debconf-apt-progress -- apt-get update
debconf-apt-progress -- apt-get -y install tvheadend
}


install_transmission (){
#--------------------------------------------------------------------------------------------------------------------------------
# transmission
#--------------------------------------------------------------------------------------------------------------------------------
debconf-apt-progress -- apt-get -y install transmission-cli transmission-common transmission-daemon
}


install_samba (){
#--------------------------------------------------------------------------------------------------------------------------------
# install Samba file sharing
#--------------------------------------------------------------------------------------------------------------------------------
# Read samba user / pass / group
SMBUSER=$(whiptail --inputbox "What is your samba username?" 8 78 $SMBUSER --title "$SECTION" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
SMBPASS=$(whiptail --inputbox "What is your samba password?" 8 78 $SMBPASS --title "$SECTION" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
SMBGROUP=$(whiptail --inputbox "What is your samba group?" 8 78 $SMBGROUP --title "$SECTION" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
#
debconf-apt-progress -- apt-get -y install samba samba-common-bin
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


install_cups (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install printer system
#--------------------------------------------------------------------------------------------------------------------------------
debconf-apt-progress -- apt-get -y install cups lpr foomatic-filters
# cups-filters if jessie
sed -e 's/Listen localhost:631/Listen 631/g' -i /etc/cups/cupsd.conf
sed -e 's/<Location \/>/<Location \/>\nallow $SUBNET/g' -i /etc/cups/cupsd.conf
sed -e 's/<Location \/admin>/<Location \/admin>\nallow $SUBNET/g' -i /etc/cups/cupsd.conf
sed -e 's/<Location \/admin\/conf>/<Location \/admin\/conf>\nallow $SUBNET/g' -i /etc/cups/cupsd.conf
service cups restart
service samba restart
} 


install_temper (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install USB temperature sensor
#--------------------------------------------------------------------------------------------------------------------------------
debconf-apt-progress -- apt-get -y install libusb-dev libusb-1.0-0-dev
cd /tmp
wget https://github.com/igorpecovnik/Debian-micro-home-server/blob/next/src/temper_v14_altered.tgz?raw=true -O - | tar -xz
cd temperv14
make
make rules-install
cp temperv14 /usr/bin/temper
}


install_scaner_and_scanbuttons (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install Scanner buttons
#--------------------------------------------------------------------------------------------------------------------------------
debconf-apt-progress -- apt-get -y install pdftk libusb-dev sane sane-utils libudev-dev imagemagick libtiff-tools
# wget http://wp.psyx.us/wp-content/uploads/2010/10/scanbuttond-0.2.3.genesys.tar.gz
wget https://github.com/igorpecovnik/Debian-micro-home-server/raw/master/src/scanbuttond-0.2.3.genesys.tar.gz
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


install_ocr (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install OCR
# get script from here https://github.com/gkovacs/pdfocr
#--------------------------------------------------------------------------------------------------------------------------------
wget https://raw2.github.com/gkovacs/pdfocr/master/pdfocr.rb
mv pdfocr.rb /usr/local/bin/pdfocr
chmod +x /usr/local/bin/pdfocr
apt-get -y install ruby tesseract-ocr libtiff-tools
} 


install_btsync (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install Personal cloud
#-------------------------------------------------------------------------------------------------------------------------------- 
cd /tmp
if [ "$(dpkg --print-architecture | grep armhf)" != "" ]; then
wget http://download.getsyncapp.com/endpoint/btsync/os/linux-arm/track/stable/btsync_arm.tar.gz -O - | tar -xz
else
wget http://download-new.utorrent.com/endpoint/btsync/os/linux-i386/track/stable/bittorrent_sync_i386.tar.gz -O - | tar -xz
fi
mv btsync /usr/local/bin
ln -sf /lib/ld-linux-armhf.so.3 /lib/ld-linux.so.3
chmod +x /usr/local/bin/btsync
sed -e 's/exit 0//g' -i /etc/rc.local
cat >> /etc/rc.local <<"EOF"
/usr/local/bin/btsync
exit 0
EOF
}


install_vpn_server (){
#--------------------------------------------------------------------------------------------------------------------------------
# Script downloads latest stable
#--------------------------------------------------------------------------------------------------------------------------------
cd /tmp
PREFIX="http://www.softether-download.com/files/softether/"
URL=$(wget -q $PREFIX -O - | html2text | grep rtm | awk ' { print $(NF) }' | tail -1)
SUFIX="${URL/-tree/}"
if [ "$(dpkg --print-architecture | grep armhf)" != "" ]; then
DLURL=$PREFIX$URL"/Linux/SoftEther%20VPN%20Server/32bit%20-%20ARM%20EABI/softether-vpnserver-$SUFIX-linux-arm_eabi-32bit.tar.gz"
else
DLURL=$PREFIX$URL"/Linux/SoftEther%20VPN%20Server/32bit%20-%20Intel%20x86/softether-vpnserver-$SUFIX-linux-x86-32bit.tar.gz"
fi
wget $DLURL -O - | tar -xz
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


install_DashNTP (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install DASH and ntp service
#--------------------------------------------------------------------------------------------------------------------------------
echo "dash dash/sh boolean false" | debconf-set-selections
dpkg-reconfigure -f noninteractive dash > /dev/null 2>&1
debconf-apt-progress -- apt-get -y install ntp ntpdate
} 


install_MySQL (){
#--------------------------------------------------------------------------------------------------------------------------------
# MYSQL
#--------------------------------------------------------------------------------------------------------------------------------
mysql_pass=$(whiptail --inputbox "What is your mysql root password?" 8 78 $mysql_pass --title "$SECTION" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
echo "mysql-server-5.5 mysql-server/root_password password $mysql_pass" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $mysql_pass" | debconf-set-selections
debconf-apt-progress -- apt-get -y install mysql-client mysql-server
#Allow MySQL to listen on all interfaces
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
sed -i 's|bind-address           = 127.0.0.1|#bind-address           = 127.0.0.1|' /etc/mysql/my.cnf
service mysql restart >> /dev/null
}


install_MySQLDovecot (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install Postfix, Dovecot, Saslauthd, phpMyAdmin, rkhunter, binutils
#--------------------------------------------------------------------------------------------------------------------------------
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections
debconf-apt-progress -- apt-get -y install postfix postfix-mysql postfix-doc openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve sudo libsasl2-modules
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
service postfix restart >> /dev/null
}


install_Virus (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install Amavisd-new, SpamAssassin, And Clamav
#--------------------------------------------------------------------------------------------------------------------------------
debconf-apt-progress -- apt-get -y install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj p7zip unrar ripole rpm nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl
/etc/init.d/spamassassin stop
insserv -rf spamassassin
}


install_Apache (){
#--------------------------------------------------------------------------------------------------------------------------------
#Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt
#--------------------------------------------------------------------------------------------------------------------------------
clear_console
echo "========================================================================="
echo "You will be prompted for some information during the install of phpmyadmin."
echo "Select NO when asked to configure using dbconfig-common"
echo "Please enter them where needed."
echo "========================================================================="
echo "Press ENTER to continue.."
read DUMMY
echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections

#BELOW ARE STILL NOT WORKING
#echo 'phpmyadmin      phpmyadmin/dbconfig-reinstall   boolean false' | debconf-set-selections
#echo 'phpmyadmin      phpmyadmin/dbconfig-install     boolean false' | debconf-set-selections
debconf-apt-progress -- apt-get -y install apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-ruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached

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
apt-get -y -qq install php5-xcache

#Restart Apache
service apache2 restart >> /dev/null
}


install_NginX (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install NginX, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt
#--------------------------------------------------------------------------------------------------------------------------------

echo 'phpmyadmin      phpmyadmin/reconfigure-webserver        multiselect' | debconf-set-selections
echo 'phpmyadmin      phpmyadmin/dbconfig-install     boolean false' | debconf-set-selections

debconf-apt-progress -- apt-get install -y nginx
if [ $(dpkg-query -W -f='${Status}' apache2 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
/etc/init.d/apache2 stop >> /dev/null
update-rc.d -f apache2 remove >> /dev/null
fi
service nginx start >> /dev/null

debconf-apt-progress -- apt-get install -y php5-fpm
debconf-apt-progress -- apt-get install -y php5-mysql php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached
debconf-apt-progress -- apt-get install -y php-apc
#PHP Configuration Stuff Goes Here
debconf-apt-progress -- apt-get install -y fcgiwrap
reset
echo "========================================================================="
echo "You will be prompted for some information during the install of phpmyadmin."
echo "Please enter them where needed."
echo "========================================================================="
echo "Press ENTER to continue.."
read DUMMY

DEBIAN_FRONTEND=noninteractive apt-get install -y dbconfig-common
debconf-apt-progress -- apt-get install -y phpmyadmin


#Fix Ming Error
rm /etc/php5/cli/conf.d/ming.ini
cat > /etc/php5/cli/conf.d/ming.ini <<"EOF"
extension=ming.so
EOF
/etc/init.d/php5-fpm restart
}


install_PureFTPD (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install PureFTPd
#--------------------------------------------------------------------------------------------------------------------------------
debconf-apt-progress -- apt-get -y install pure-ftpd-common pure-ftpd-mysql

sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
echo 1 > /etc/pure-ftpd/conf/TLS
mkdir -p /etc/ssl/private/

openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -subj "/C=/ST=/L=/O=/CN=$(hostname -f)" -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
chmod 600 /etc/ssl/private/pure-ftpd.pem
/etc/init.d/pure-ftpd-mysql restart
}



install_Bind (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install BIND DNS Server
#--------------------------------------------------------------------------------------------------------------------------------
debconf-apt-progress -- apt-get -y install bind9 dnsutils
}


install_Stats (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install Vlogger, Webalizer, And AWstats
#--------------------------------------------------------------------------------------------------------------------------------
debconf-apt-progress -- apt-get -y install vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl
sed -i "s/*/10 * * * * www-data/#*/10 * * * * www-data/" /etc/cron.d/awstats
sed -i "s/10 03 * * * www-data/#10 03 * * * www-data/" /etc/cron.d/awstats
}


install_Fail2BanDovecot() {
#--------------------------------------------------------------------------------------------------------------------------------
# Install fail2ban
#--------------------------------------------------------------------------------------------------------------------------------
debconf-apt-progress -- apt-get -y install fail2ban

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


install_Fail2BanRulesDovecot() {
#--------------------------------------------------------------------------------------------------------------------------------
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
service fail2ban restart >> /dev/null
}


install_ISPConfig (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install ISPConfig 3
#--------------------------------------------------------------------------------------------------------------------------------
cd /tmp
wget -q http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz -O - | tar -xz
cd /tmp/ispconfig3_install/install/
php -q install.php --autoinstall=/tmp/isp.conf.php
}
