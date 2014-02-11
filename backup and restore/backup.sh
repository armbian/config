#!/bin/bash
DATE=`date +%F`
DBBACKUPNAME="mysql-"$DATE
WEBBACKUPNAME="website-"$DATE
FILEBACKUPNAME="website-"$DATE


# change this
COPY_TO=/root/temp/$DATE
COPY_FROM=/var/www/clients
USER=
PASSWORD=
HOST=localhost
#

mkdir -p $COPY_TO

echo "";
echo "************************************";
echo "       CRONTAB BACKUP";
echo "************************************";
echo "";

crontab -l > $COPY_TO/crontab-root.txt

echo "";
echo "************************************";
echo "       DATABASES BACKUP";
echo "************************************";
echo "";
for db in $(echo 'SHOW DATABASES;'|mysql -u$USER -p$PASSWORD -h$HOST|grep -v '^Database$'|grep -v "^performance_schema" |grep -v "^information_schema" |grep -v "^mysql"); 
do
	  mysqldump \
              -u$USER -p$PASSWORD -h$HOST \
              -Q -c -C --add-drop-table --add-locks --quick --lock-tables \
              $db | gzip --best -c > $COPY_TO/$DBBACKUPNAME-$db.sql.gz;
		echo "Backup of" $db;
done;

echo "";
echo "************************************";
echo "       WEB BACKUP";
echo "************************************";
echo "";

echo "Wait a moment please...";
for x in $(find $COPY_FROM -maxdepth 2 -name "web*" -type d -print0 | xargs -0)
do
tar -cpvzf $COPY_TO/$WEBBACKUPNAME-$(basename $x).tar.gz $x &> /dev/null
done;

echo "";
echo "************************************";
echo "       CONF BACKUP";
echo "************************************";
echo "";

service dovecot stop
service cups stop
service transmission-daemon stop
service hostapd stop
service postfix stop
service tvheadend stop
service samba stop
/etc/init.d/scanbuttond stop
/etc/init.d/vpnserver stop
# backup only minimum 
tar cvPfz $COPY_TO/$FILEBACKUPNAME-allfiles.tgz -T filelist.txt --exclude='*.sock'
#
service dovecot start
service cups start
service transmission-daemon start
service hostapd start
service postfix start
service tvheadend start
service samba start
/etc/init.d/scanbuttond start
/etc/init.d/vpnserver start

echo "";
echo "************************************";
echo "       INSTALLED PACKAGE LIST BACKUP";
echo "************************************";
echo "";
aptitude search '~i !~M !~pstandard !~pimportant !~prequired' | awk '{print $2}' > $COPY_TO/installedpackages
