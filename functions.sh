#!/bin/bash
#
# (c) Igor Pecovnik
#


# Very basic stuff
apt-get -y -qq install dialog whiptail lsb-release bc expect --no-install-recommends

# gather some info
distribution=$(lsb_release -cs)
family=$(lsb_release -is)
serverIP=$(ip route get 8.8.8.8 | awk '{ print $NF; exit }')
set ${serverIP//./ }
SUBNET="$1.$2.$3."
hostnamefqdn=$(hostname -f)
mysql_pass=""
backtitle="Armbian post deployment scripts, http://www.armbian.com"
logfile="/tmp/microhomeserver.log"
echo "Start:" > $logfile

TTY_X=$(($(stty size | awk '{print $2}')-6)) # determine terminal width
TTY_Y=$(($(stty size | awk '{print $1}')-6)) # determine terminal height


#distribution=$(lsb_release -i)" "$(lsb_release -cs)

function choose_webserver
{
dialog --title "Choose a webserver" \
--backtitle "$backtitle" \
--yes-label "Apache" \
--no-label "Nginx" \
--yesno "\nChoose a wenserver which you are familiar with. They both work almost the same." 8 70
response=$?
case $response in
   0) server="apache";;
   1) server="nginx";;
   255) exit;;
esac
echo $server > /tmp/server
}


function server_conf
{
exec 3>&1
dialog --title "Server configuration" \
--separate-widget $'\n' --ok-label "Install" \
--backtitle "$backtitle" \
--form "\nPlease fill out this form:\n " \
12 70 0 \
"Your FQDN for $serverip:"	1 1 "$hostnamefqdn"         1 31 32 0 \
"Mysql root password:" 	  	2 1 "$mysql_pass"       			2 31 32 0 \
2>&1 1>&3 | {

read -r hostnamefqdn
read -r mysql_pass
echo $mysql_pass > /tmp/mysql_pass
echo $hostnamefqdn > /tmp/hostnamefqdn
choose_webserver
# end
}
exec 3>&-
# read variables back
MYSQL_PASS=`cat /tmp/mysql_pass`
HOSTNAMEFQDN=`cat /tmp/hostnamefqdn`
server=`cat /tmp/server`
}


before_install ()
{
#--------------------------------------------------------------------------------------------------------------------------------
# What do we need anyway
#--------------------------------------------------------------------------------------------------------------------------------
apt-get update 		| dialog --backtitle "$backtitle" \
										--progressbox "Force package list update ..." $TTY_Y $TTY_X
apt-get -y upgrade	| dialog --backtitle "$backtitle" \
										--progressbox "Force upgrade ..." $TTY_Y $TTY_X
apt-get -y autoremove	| dialog --backtitle "$backtitle" \
										--progressbox "Remove packages that are no more needed ..." $TTY_Y $TTY_X
install_packet "debconf-utils unzip build-essential html2text apt-transport-https" "Downloading basic packages"

}




function what_to_install()
{
#--------------------------------------------------------------------------------------------------------------------------------
# Installation menu
#--------------------------------------------------------------------------------------------------------------------------------
DIALOG=${DIALOG=dialog}
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

$DIALOG --backtitle "$backtitle" \
--title "Installing to $family $distribution" --clear --checklist "\nChoose what you want to install:\n " 22 70 15 \
"Tasksel" "Stock $family $distribution app installer" off \
"TV headend" "TV streaming / proxy" off \
"Syncthing" "Personal cloud @syncthing.net" off \
"CUPS" "Printing" off \
"VPN server" "VPN server" off \
"Armbianmonitor" "Status page and statistics" off \
"OMV" "OpenMediaVault NAS solution" off \
"Minidlna" "Lightweight DLNA/UPnP-AV server" off \
"Pi hole" "Ad blocker" off \
"Transmission" "Torrent downloading" off \
"ISPConfig" "Advanced LAMP + SMTP, IMAP, POP3" off 2> $tempfile

retval=$?

choice=`cat $tempfile`
case $retval in
  0)
   ;;
  1)
    exit;;
  255)
    exit;;
esac
IFS=";"
choice="${choice//\" /;}"
choice="${choice//\"/}"
declare -a choice=($choice)
}


install_packet ()
{
#--------------------------------------------------------------------------------------------------------------------------------
# Install missing packets
#--------------------------------------------------------------------------------------------------------------------------------
i=0
j=1
IFS=" "
declare -a PACKETS=($1)
skupaj=${#PACKETS[@]}
while [[ $i -lt $skupaj ]]; do
procent=$(echo "scale=2;($j/$skupaj)*100"|bc)
		x=${PACKETS[$i]}
		if [ $(dpkg-query -W -f='${Status}' $x 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			printf '%.0f\n' $procent | dialog \
			--backtitle "$backtitle" \
			--title "Installing" \
			--gauge "\n$2\n\n$x" 10 70
		if [ "$(DEBIAN_FRONTEND=noninteractive apt-get -qq -y install $x >/tmp/install.log 2>&1 || echo 'Installation failed' | grep 'Installation failed')" != "" ]; then
			echo -e "[\e[0;31m error \x1B[0m] Installation failed"
			tail /tmp/install.log
			exit
		fi
		fi
		i=$[$i+1]
		j=$[$j+1]
done
echo ""
}


check_port (){
[[ -z $(netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".$1"') ]] && dialog --backtitle "$backtitle" --title "Checking service" --infobox "\nIt looks good.\n\nThere is $2 service on port $1" 7 52
sleep 3
}


install_basic (){
#--------------------------------------------------------------------------------------------------------------------------------
# Set hostname, FQDN, add to sources list
#--------------------------------------------------------------------------------------------------------------------------------
IFS=" "
set ${HOSTNAMEFQDN//./ }
HOSTNAMESHORT="$1"
cp /etc/hosts /etc/hosts.backup
cp /etc/hostname /etc/hostname.backup
# create new
echo "127.0.0.1   localhost.localdomain   localhost" > /etc/hosts
echo "${serverIP} ${HOSTNAMEFQDN} ${HOSTNAMESHORT} #ispconfig " >> /etc/hosts
echo "$HOSTNAMESHORT" > /etc/hostname
/etc/init.d/hostname.sh start >/dev/null 2>&1
if [[ $family == "Ubuntu" ]]; then
	# disable AppArmor
	service apparmor stop
	update-rc.d -f apparmor remove
	apt-get remove apparmor apparmor-utils
fi
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
\$autoinstall['mysql_root_password'] = '$MYSQL_PASS';
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


install_omv (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install high-performance HTTP accelerator
#--------------------------------------------------------------------------------------------------------------------------------
wget -qO - packages.openmediavault.org/public/archive.key | apt-key add -
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7AA630A1EDEE7D73

cat > /etc/apt/sources.list.d/openmediavault.list << EOF
deb http://packages.openmediavault.org/public erasmus main

## Uncomment the following line to add software from the proposed repository.
# deb http://packages.openmediavault.org/public erasmus-proposed main


## This software is not part of OpenMediaVault, but is offered by third-party
## developers as a service to OpenMediaVault users.

# deb http://packages.openmediavault.org/public erasmus partner

EOF
debconf-apt-progress -- apt-get update
install_packet "openmediavault postfix openmediavault-flashmemory" "Install network attached storage (NAS) solution"
URL='http://omv-extras.org/openmediavault-omvextrasorg_latest_all3.deb'; FILE=`mktemp`; wget "$URL" -qO $FILE && sudo dpkg -i $FILE; rm $FILE
/usr/sbin/omv-update
sed -i '/<flashmemory>/,/<\/flashmemory>/ s/<enable>0/<enable>1/' /etc/openmediavault/config.xml
/usr/sbin/omv-mkconf flashmemory
check_port 80
}


install_tvheadend (){
#--------------------------------------------------------------------------------------------------------------------------------
# TVheadend https://tvheadend.org/
#--------------------------------------------------------------------------------------------------------------------------------
install_packet "debconf-utils unzip build-essential html2text apt-transport-https" "Downloading dependendies"

if !(grep -qs tvheadend "/etc/apt/sources.list.d/tvheadend.list");then
	echo "deb https://dl.bintray.com/tvheadend/deb $distribution stable" >> /etc/apt/sources.list.d/tvheadend.list
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 379CE192D401AB61 >/dev/null 2>&1
fi
debconf-apt-progress -- apt-get update
install_packet "libssl-doc libssl1.0.0 zlib1g-dev tvheadend xmltv-util"
install -m 755 scripts/tv_grab_file /usr/bin/tv_grab_file
dpkg-reconfigure tvheadend
service tvheadend restart
}


install_transmission (){
#--------------------------------------------------------------------------------------------------------------------------------
# transmission
#--------------------------------------------------------------------------------------------------------------------------------
install_packet "debconf-utils unzip build-essential html2text apt-transport-https" "Downloading dependendies"
install_packet "transmission-cli transmission-common transmission-daemon" "Install torrent server"
}


install_cups (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install printer system
#--------------------------------------------------------------------------------------------------------------------------------
install_packet "cups lpr cups-filters" "Installing CUPS"
# cups-filters if jessie
sed -e 's/Listen localhost:631/Listen 631/g' -i /etc/cups/cupsd.conf
sed -e 's/<Location \/>/<Location \/>\nallow $SUBNET/g' -i /etc/cups/cupsd.conf
sed -e 's/<Location \/admin>/<Location \/admin>\nallow $SUBNET/g' -i /etc/cups/cupsd.conf
sed -e 's/<Location \/admin\/conf>/<Location \/admin\/conf>\nallow $SUBNET/g' -i /etc/cups/cupsd.conf
service cups restart
service samba restart | service smbd restart >/dev/null 2>&1
}


install_syncthing (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install Personal cloud https://syncthing.net/
#--------------------------------------------------------------------------------------------------------------------------------
curl -s https://syncthing.net/release-key.txt | apt-key add -
	if !(grep -qs syncthing "/etc/apt/sources.list.d/syncthing.list");then
	echo "deb http://apt.syncthing.net/ syncthing release" | tee /etc/apt/sources.list.d/syncthing.list
	debconf-apt-progress -- apt-get update
	install_packet "syncthing" "Install Personal cloud https://syncthing.net/"
	sed -e 's/exit 0//g' -i /etc/rc.local
	cat >> /etc/rc.local <<"EOF"
syncthing
exit 0
EOF
	syncthing >/dev/null 2>&1 &
	sleep 5
	fi
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
DLURL=$PREFIX$URL"/Linux/SoftEther_VPN_Server/32bit_-_ARM_EABI/softether-vpnserver-$SUFIX-linux-arm_eabi-32bit.tar.gz"
else
apt-get -y install gcc-multilib
DLURL=$PREFIX$URL"/Linux/SoftEther_VPN_Server/32bit_-_Intel_x86/softether-vpnserver-$SUFIX-linux-x86-32bit.tar.gz"
fi
wget -q $DLURL -O - | tar -xz
cd vpnserver
make i_read_and_agree_the_license_agreement >> $logfile
cd ..
cp -R vpnserver /usr/local
cd /usr/local/vpnserver/
chmod 600 *
chmod 700 vpncmd
chmod 700 vpnserver
if [[ -d /run/systemd/system/ ]]; then
cat <<EOT >/lib/systemd/system/ethervpn.service
[Unit]
Description=VPN service

[Service]
Type=oneshot
ExecStart=/usr/local/vpnserver/vpnserver start
ExecStop=/usr/local/vpnserver/vpnserver stop
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOT
systemctl enable ethervpn.service
service ethervpn start

else

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
update-rc.d vpnserver defaults >> $logfile
/etc/init.d/vpnserver start
fi
}


install_DashNTP (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install DASH and ntp service
#--------------------------------------------------------------------------------------------------------------------------------
echo "dash dash/sh boolean false" | debconf-set-selections
dpkg-reconfigure -f noninteractive dash > /dev/null 2>&1
install_packet "ntp ntpdate" "Install DASH and ntp service"
}


install_MySQL_old (){
#--------------------------------------------------------------------------------------------------------------------------------
# MYSQL
#--------------------------------------------------------------------------------------------------------------------------------
echo "mysql-server-5.5 mysql-server/root_password password $MYSQL_PASS" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQL_PASS" | debconf-set-selections
install_packet "mysql-client mysql-server" "Install Mysql client / server"
#Allow MySQL to listen on all interfaces
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
sed -i 's|bind-address           = 127.0.0.1|#bind-address           = 127.0.0.1|' /etc/mysql/my.cnf
service mysql restart >> /dev/null
}


install_MySQL (){
#--------------------------------------------------------------------------------------------------------------------------------
# Maria SQL
#--------------------------------------------------------------------------------------------------------------------------------
install_packet "mariadb-client mariadb-server" "Install Mysql client / server"
#Allow MySQL to listen on all interfaces
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
sed -i 's|bind-address           = 127.0.0.1|#bind-address           = 127.0.0.1|' /etc/mysql/mariadb.conf.d/50-server.cnf
SECURE_MYSQL=$(expect -c "
set timeout 3
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"\r\"
expect \"root password?\"
send \"y\r\"
expect \"New password:\"
send \"$MYSQL_PASS\r\"
expect \"Re-enter new password:\"
send \"$MYSQL_PASS\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
#
# Execution mysql_secure_installation
#
echo "${SECURE_MYSQL}"
service mysql restart >> /dev/null
}


install_MySQLDovecot (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install Postfix, Dovecot, Saslauthd, phpMyAdmin, rkhunter, binutils
#--------------------------------------------------------------------------------------------------------------------------------
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections
install_packet "postfix postfix-mysql postfix-doc openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d dovecot-mysql \
dovecot-sieve sudo libsasl2-modules" "postfix, dovecot, saslauthd, phpMyAdmin, rkhunter, binutils"
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
install_packet "amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj p7zip unrar-free ripole rpm nomarch lzop \
cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl \
libnet-ident-perl zip libnet-dns-perl" "amavisd, spamassassin, clamav"
/etc/init.d/spamassassin stop
insserv -rf spamassassin
}


install_apache (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear and mcrypt
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
install_packet "apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 \
php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear \
php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-ruby libapache2-mod-python \
php5-curl php5-intl php5-memcache php5-memcached php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy \
php5-xmlrpc php5-xsl memcached" "apache2, PHP5, phpMyAdmin, FCGI, suExec, pear and mcrypt"

a2enmod suexec rewrite ssl actions include >> /dev/null
a2enmod dav_fs dav auth_digest >> /dev/null

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
install_packet "php5-xcache" "Install XCache"

#Restart Apache
service apache2 restart >> /dev/null
}


install_nginx (){
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
debconf-apt-progress -- apt-get install -y php5-mysql php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-memcached php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached
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

/etc/init.d/php5-fpm restart >> /dev/null
}


install_PureFTPD (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install PureFTPd
#--------------------------------------------------------------------------------------------------------------------------------
install_packet "pure-ftpd-common pure-ftpd-mysql" "p3ureFTPd"

sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
echo 1 > /etc/pure-ftpd/conf/TLS
mkdir -p /etc/ssl/private/

openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -subj "/C=/ST=/L=/O=/CN=$(hostname -f)" -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
chmod 600 /etc/ssl/private/pure-ftpd.pem
/etc/init.d/pure-ftpd-mysql restart  >> /dev/null
}



install_Bind (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install BIND DNS Server
#--------------------------------------------------------------------------------------------------------------------------------
install_packet "bind9 dnsutils" "Install BIND DNS Server"
}


install_Stats (){
#--------------------------------------------------------------------------------------------------------------------------------
# Install Vlogger, Webalizer, And AWstats
#--------------------------------------------------------------------------------------------------------------------------------
install_packet "vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl" "vlogger, webalizer, awstats"
sed -i "s/*/10 * * * * www-data/#*/10 * * * * www-data/" /etc/cron.d/awstats
sed -i "s/10 03 * * * www-data/#10 03 * * * www-data/" /etc/cron.d/awstats
}


install_Fail2BanDovecot() {
#--------------------------------------------------------------------------------------------------------------------------------
# Install fail2ban
#--------------------------------------------------------------------------------------------------------------------------------
install_packet "fail2ban" "Install fail2ban"

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
#apt-get -y install php5-cli php5-mysql
php -q install.php --autoinstall=/tmp/isp.conf.php
}
