#!/bin/bash
#
# Debian micro home server installation(c) Igor Pecovnik
# 

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

# Debian only
if [ ! -f /etc/debian_version ]; then 
    echo "Unsupported Linux Distribution. Prepared for Debian"
    exit 1
fi

# Ramlog must be disabled
if [ -f /run/ramlog.lock ]; then
    echo "RAMlog is running. Please disable before running (service ramlog disable). Reboot is required."
    exit 1
fi

#--------------------------------------------------------------------------------------------------------------------------------
# What do we need anyway
debconf-apt-progress -- apt-get update
debconf-apt-progress -- apt-get -y upgrade
debconf-apt-progress -- apt-get -y install debconf-utils dnsutils unzip whiptail git build-essential alsa-base alsa-utils stunnel4 html2text
#--------------------------------------------------------------------------------------------------------------------------------

SECTION="Basic configuration"
# Read IP address
#
serverIP=$(ip route get 8.8.8.8 | awk '{ print $NF; exit }')
set ${serverIP//./ }
SUBNET="$1.$2.$3."
#
# Read full qualified hostname
HOSTNAMEFQDN=$(hostname -f)
HOSTNAMEFQDN=$(whiptail --inputbox "\nWhat is your full qualified hostname for $serverIP ?" 10 78 $HOSTNAMEFQDN --title "$SECTION" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
set ${HOSTNAMEFQDN//./ }
HOSTNAMESHORT="$1"

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


if [[ "$ins_samba" == "true" ]]; 			then install_samba; 			fi
if [[ "$ins_tvheadend" == "true" ]]; 			then install_tvheadend; 		fi
if [[ "$ins_btsync" == "true" ]]; 			then install_btsync; 			fi
if [[ "$ins_vpn_server" == "true" ]]; 			then install_vpn_server; 		fi
if [[ "$ins_cups" == "true" ]]; 			then install_cups; 			fi
if [[ "$ins_scanner_and_scanbuttons" == "true" ]];	then install_scaner_and_scanbuttons; 	fi
if [[ "$ins_temper" == "true" ]]; 			then install_temper; 			fi
if [[ "$ins_rpimonitor" == "true" ]]; 			then install_bmc180; install_tsl2561; install_rpimonitor;  			fi
if [[ "$ins_transmission" == "true" ]];                 then install_transmission;              fi
if [[ "$ins_ispconfig" == "true" ]];                    then
							install_basic
							install_DashNTP
							install_MySQL
							install_MySQLDovecot
							install_Virus;


							if (whiptail --no-button "Apache" --yes-button "NginX" --title "Choose webserver platform" --yesno "ISPConfig can run on both." 7 78) then
								server="nginx"
								install_NginX
							else
								server="apache"
								install_Apache
							fi
							create_ispconfig_configuration
				   			install_PureFTPD; install_Fail2BanDovecot; install_Fail2BanRulesDovecot; install_ISPConfig
fi
rm results
