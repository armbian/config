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
mkdir -p $COPY_TO


function crontab_backup ()
{
	echo -e "[\e[0;32m o.k. \x1B[0m] \e[1;32m$1\x1B[0mCrontab backup"
	crontab -l > $COPY_TO/crontab-root.txt &> /dev/null
}


function database_backup ()
{
	if which mysql >/dev/null; then
	for db in $(echo 'SHOW DATABASES;'|mysql -u$USER -p$PASSWORD -h$HOST|grep -v '^Database$'|grep -v "^performance_schema" |grep -v "^information_schema" |grep -v "^mysql"); 
	do
		mysqldump \
              -u$USER -p$PASSWORD -h$HOST \
              -Q -c -C --add-drop-table --add-locks --quick --lock-tables \
              $db | gzip --best -c > $COPY_TO/$DBBACKUPNAME-$db.sql.gz;
		echo -e "[\e[0;32m o.k. \x1B[0m] \e[1;32m$1\x1B[0mDatabase $db backup"		
	done;
	fi
}


function web_backup ()
{
	echo -e "[\e[0;32m o.k. \x1B[0m] \e[1;32m$1\x1B[0mWebsites backup"
	for x in $(find $COPY_FROM -maxdepth 2 -name "web*" -type d -print0 | xargs -0)
	do
	tar -cpvzf $COPY_TO/$WEBBACKUPNAME-$(basename $x).tar.gz $x &> /dev/null
	done;
}


function conf_backup ()
{
	/etc/init.d/scanbuttond stop
	/etc/init.d/vpnserver stop
	service transmission-daemon stop
	service tvheadend stop
	service cups stop
	service samba stop
	echo -e "[\e[0;32m o.k. \x1B[0m] \e[1;32m$1\x1B[0mConf files backup"
	# find only existing
	filename=filelist.txt
	tmpfilename=/tmp/filelist.txt
	touch tmpfilename
	IFS=$'\n'
	for next in `cat $filename`
	do
		[[ -f $next || -d $next ]] && echo "$next" >> $tmpfilename
	done
	tar cvPfz $COPY_TO/$FILEBACKUPNAME-allfiles.tgz -T $tmpfilename --exclude='*.sock' &> /dev/null
	service samba start
	service cups start
	service tvheadend start
	service transmission-daemon start
	/etc/init.d/scanbuttond start
	/etc/init.d/vpnserver start
}


function mail_backup ()
{
	if [[ -d /var/vmail ]]; then 
		service dovecot stop
		service postfix stop
		echo -e "[\e[0;32m o.k. \x1B[0m] \e[1;32m$1\x1B[0mMail backup"
		tar cvPfz $COPY_TO/$FILEBACKUPNAME-mail.tgz /var/vmail	
		service postfix start
		service dovecot start
	fi
}


function pkglist_backup ()
{
	echo -e "[\e[0;32m o.k. \x1B[0m] \e[1;32m$1\x1B[0mPackage list backup"
	aptitude search '~i !~M !~pstandard !~pimportant !~prequired' | awk '{print $2}' > $COPY_TO/installedpackages
}


# main app
crontab_backup
database_backup
web_backup
conf_backup
mail_backup
pkglist_backup