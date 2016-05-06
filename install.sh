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
#--------------------------------------------------------------------------------------------------------------------------------
    if [ "$i" == "ISPConfig" ] ; then
		server_conf
		if [[ "$MYSQL_PASS" == "" ]]; then
			dialog --msgbox "Mysql password can't be blank. Exiting..." 7 70
			exit
		fi
		install_basic; install_DashNTP; install_MySQL; install_MySQLDovecot; install_Virus; install_$server
		create_ispconfig_configuration; install_PureFTPD; install_Fail2BanDovecot; install_Fail2BanRulesDovecot; 
		install_ISPConfig
    fi
	if [ "$i" == "Samba" ] ; then
		install_samba
	fi
	if [ "$i" == "TV headend" ] ; then
		install_tvheadend "$tv_user" "$tv_pass"
	fi
	if [ "$i" == "Syncthing" ] ; then
		install_syncthing
	fi
	if [ "$i" == "CUPS" ] ; then
		install_cups
	fi
	if [ "$i" == "VPN server" ] ; then
		install_vpn_server
	fi	
	if [ "$i" == "Scanner" ] ; then
		install_scaner_and_scanbuttons
	fi
	if [ "$i" == "Rpi monitor" ] ; then
		install_rpimonitor
	fi
	if [ "$i" == "Pi hole" ] ; then
		curl -L install.pi-hole.net | bash
		fi
	if	[ "$i" == "Transmission" ] ; then
		install_transmission
	fi
	
#--------------------------------------------------------------------------------------------------------------------------------	
done






exit







SECTION="Basic configuration"
# Read IP address
#
#
# Read full qualified hostname

source "functions.sh"

whiptail --ok-button "Install" --title "Debian micro home server installation (c) Igor Pecovnik" --checklist --separate-output "\nIP:   $serverIP\nFQDN: $HOSTNAMEFQDN\n\nChoose what you want to install:" 20 78 9 \
"Samba" "Windows compatible file sharing        " off \
"TV headend" "TV streaming / proxy" off \
"BitTorrent Sync" "Personal cloud" off \
"SoftEther VPN server" "Advanced VPN solution" off \
"CUPS" "Printing" off \
"Scanner" "Control your scanner with buttons, OCR" off \
"Temper" "USB temperature sensor" off \
"Rpi monitor" "Status page and statistics" off \
"Transmission" "Torrent downloading" off \
"ISPConfig" "WWW, PHP, SQL, SMTP, IMAP, POP3" off 2>results
while read choice
do
   case $choice in
		   "Samba") 			ins_samba="true";;
                   "TV headend") 		ins_tvheadend="true";;
                   "BitTorrent Sync") 	  	ins_btsync="true";;
                   "SoftEther VPN server") 	ins_vpn_server="true";;
		   "CUPS") 			ins_cups="true";;
		   "Scanner") 			ins_scaner_and_scanbuttons="true";;
                   "Temper") 			ins_temper="true";;
				   "Rpi monitor") 			ins_rpimonitor="true";;
                   "Transmission")		ins_transmission="true";;
		   "ISPConfig")			ins_ispconfig="true";;
                *)
                ;;
        esac
done < results


if [[ "$ins_samba" == "true" ]]; 			then ; 			fi
if [[ "$ins_tvheadend" == "true" ]]; 			then ; 		fi
if [[ "$ins_btsync" == "true" ]]; 			then install_btsync; 			fi
if [[ "$ins_vpn_server" == "true" ]]; 			then install_vpn_server; 		fi
if [[ "$ins_cups" == "true" ]]; 			then install_cups; 			fi
if [[ "$ins_scanner_and_scanbuttons" == "true" ]];	then install_scaner_and_scanbuttons; 	fi
if [[ "$ins_temper" == "true" ]]; 			then install_temper; 			fi
if [[ "$ins_rpimonitor" == "true" ]]; 			then install_bmc180; install_tsl2561; install_rpimonitor;  			fi
if [[ "$ins_transmission" == "true" ]];                 then ;              fi
