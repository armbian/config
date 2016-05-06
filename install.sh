#!/bin/bash
#
# Debian micro home server installation(c) Igor Pecovnik
#
# Copyright (c) 2015 Igor Pecovnik, igor.pecovnik@gma**.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of https://github.com/igorpecovnik/Debian-micro-home-server
#


# Read functions
source "functions.sh"


# Check if user is root
if [ $(id -u) != "0" ]; then
	dialog --msgbox "Error: You must be root to run this script, please use the root user to install the software." 7 70
	exit 1
fi


# Debian only
if [ ! -f /etc/debian_version ]; then 
	dialog --msgbox "Warning: Unsupported Linux Distribution, it might not install properly. Tailored for Debian. " 7 70
fi


# Ramlog must be disabled
if [ -f /run/ramlog.lock ]; then
	dialog --msgbox "Ramlog is running. Please disable before running (service ramlog disable). Reboot is required." 7 70
    exit 1
fi

# Choose what to install
what_to_install
before_install
for i in "${choice[@]}"
do	
    if [[ "$i" == ISPConfig* ]] ; then
		server_conf
		if [[ "$MYSQL_PASS" == "" ]]; then
			dialog --msgbox "Mysql password can't be blank. Exiting..." 7 70
			exit
		fi
		install_basic; install_DashNTP; install_MySQL; install_MySQLDovecot; install_Virus; install_$server
		create_ispconfig_configuration; install_PureFTPD; install_Fail2BanDovecot; install_Fail2BanRulesDovecot; 
		install_ISPConfig
    fi
	if [[ "$i" == Samba* ]] ; then
		install_samba
	fi
	if [[ "$i" == *headend* ]] ; then
		install_tvheadend
	fi
	if [[ "$i" == Syncthing* ]] ; then
		install_syncthing
	fi
	if [[ "$i" == CUPS* ]] ; then
		install_cups
	fi
	if [[ "$i" == *server* ]] ; then
		install_vpn_server
	fi	
	if [[ "$i" == Scanner* ]] ; then
		install_scaner_and_scanbuttons
	fi
	if [[ "$i" == *monitor* ]] ; then
		install_rpimonitor
	fi
	if [[ "$i" == *hole* ]] ; then
		curl -L install.pi-hole.net | bash
	fi
	if	[[ "$i" == Transmission* ]] ; then
		install_transmission
	fi
	

done