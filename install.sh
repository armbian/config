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
for menu_choice in "${choice[@]}"
do
	if [[ "$menu_choice" == ISPConfig* ]] ; then
		server_conf
		if [[ "$MYSQL_PASS" == "" ]]; then
			dialog --msgbox "Mysql password can't be blank. Exiting..." 7 70
			exit
		fi
		install_basic; install_DashNTP; install_MySQL; install_MySQLDovecot; install_Virus; install_$server
		create_ispconfig_configuration; install_PureFTPD; install_Fail2BanDovecot; install_Fail2BanRulesDovecot;
		install_ISPConfig
    fi
	if [[ "$menu_choice" == *Tasksel* ]] ; then
		tasksel
	fi
	if [[ "$menu_choice" == *headend* ]] ; then
		install_tvheadend
		check_port 9981
		echo $menu_choice;
	fi
	if [[ "$menu_choice" == *Syncthing* ]] ; then
		install_syncthing
		check_port 8384 "Syncthing"
	fi
	if [[ "$menu_choice" == CUPS* ]] ; then
		install_cups
	fi
	if [[ "$menu_choice" == *server* ]] ; then
		install_vpn_server
	fi
	if [[ "$menu_choice" == Scanner* ]] ; then
		install_scaner_and_scanbuttons
	fi
	if [[ "$menu_choice" == *monitor* ]] ; then
		armbianmonitor -r
	fi
	if [[ "$menu_choice" == *OMV* ]] ; then
		install_omv
	fi
	if [[ "$menu_choice" == *hole* ]] ; then
		curl -L install.pi-hole.net | bash
	fi
	if [[ "$menu_choice" == *Minidlna* ]] ; then
		install_packet "minidlna" "Install lightweight DLNA/UPnP-AV server"
		check_port 8200
	fi
	if	[[ "$menu_choice" == *Transmission* ]] ; then
		install_transmission
		check_port 9091
	fi
done