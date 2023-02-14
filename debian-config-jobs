#!/bin/bash
#
#
# Copyright (c) 2017 Igor Pecovnik, igor.pecovnik@gma**.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.

[[ -n ${SUDO_USER} ]] && SUDO="sudo "

function jobs ()
{
	# Shows box with loading ...
	#
	dialog --backtitle "$BACKTITLE" --title " Please wait " --infobox "\nLoading ${selection,,} submodule ... " 5 $((26+${#selection}))

	unset selection

	case $1 in

	#-------------------------------------------------------------------------------------------------------------------------------------#


	# Application installer
	#
	"Softy" )
		[[ -f softy ]] && ./softy || softy
	;;

	# Remove BT
	#
	"BT remove" )
		if ! is_package_manager_running; then
			debconf-apt-progress -- apt-get -y remove bluetooth bluez bluez-tools
			check_if_installed xserver-xorg && debconf-apt-progress -- apt-get -y remove pulseaudio-module-bluetooth blueman
			debconf-apt-progress -- apt -y -qq autoremove
		fi
	;;

	# Enabling BT
	#
	"BT install" )
		if ! is_package_manager_running; then
			debconf-apt-progress -- apt-get -y install bluetooth bluez bluez-tools
			check_if_installed xserver-xorg && debconf-apt-progress -- apt-get -y --no-install-recommends install pulseaudio-module-bluetooth blueman
		fi
	;;

	# Removing IR
	#
	"Remove IR" )
		if ! is_package_manager_running; then
			debconf-apt-progress -- apt-get -y remove lirc
			debconf-apt-progress -- apt -y -qq autoremove
		fi
	;;

	# Enabling IR
	#
	"IR" )
		if ! is_package_manager_running; then
			debconf-apt-progress -- apt-get -y --no-install-recommends install lirc
		fi
	;;


	# Sharing USB ports
	#
	"USB redirector" )
		if [[ -n $(netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".'32032'"') ]]; then
			[[ -f /usr/local/usb-redirector/uninstall.sh ]] && /usr/local/usb-redirector/uninstall.sh uninstall
			rm -f /usr/local/bin/usbclnt
		else
			TARGET_BRANCH=$BRANCH
			exceptions "$BRANCH"
			IFS='.' read -a array <<< $(uname -r)
			[[ -z $(dpkg -l | grep linux-headers) ]] && debconf-apt-progress -- apt-get -y \
			install linux-headers${TARGET_BRANCH}-${TARGET_FAMILY}
			if (( "${array[0]}" == "4" )) && (( "${array[1]}" >= "1" )); then
				rm -rf /usr/src/usb-redirector-linux-arm-gnueabi
				wget -qO- https://www.incentivespro.com/usb-redirector-linux-arm-gnueabi.tar.gz | tar xz -C /usr/src
				cd /usr/src/usb-redirector-linux-arm-gnueabi/
			else
				rm -rf /usr/src/usb-redirector-linux-arm-eabi
				wget -qO- https://raw.githubusercontent.com/armbian/build/master/packages/blobs/usb-redirector/usb-redirector-old.tgz \
				| tar xz -C /usr/src
				cd /usr/src/usb-redirector-linux-arm-eabi/
			fi
			./installer.sh install
			sleep 3
			check_port "32032" "USB Redirector"
		fi
	;;


	# Simple CLI monitoring
	#
	"Monitor" )
		clear
		armbianmonitor -m
		sleep 2
	;;

	# SBC-becn
	#
	"Benchmarking" )
		if [[ ! -f /usr/local/bin/sbc-benc ]]; then
			wget -q -O /usr/local/bin/sbc-bench https://raw.githubusercontent.com/ThomasKaiser/sbc-bench/master/sbc-bench.sh
			chmod +x /usr/local/bin/sbc-bench
		fi
		sbc-bench
		echo ""
		read -n 1 -s -p "Press any key to continue"
	;;


	# Send diagnostics
	#
	"Diagnostics" )
		clear
		armbianmonitor -u
		echo ""
		read -n 1 -s -p "Press any key to continue"
	;;


	# Control board consumption
	#
	"Consumption" )
		clear
		h3consumption
		echo -e "\nType \e[92m${SUDO}${0##*/}\e[0m to get back\n"
		exit
	;;


	# Board (fex) settings editor
	#
	"Fexedit" )
		exec 3>&1
		monitor=$(dialog --print-maxsize 2>&1 1>&3)
		exec 3>&-
		mon_x=$(echo $monitor | awk '{print $2}' | sed 's/,//')
		mon_y=$(echo $monitor | awk '{print $3}' | sed 's/,//')
		TEMP=$(mktemp -d || exit 1)
		trap "rm -rf \"${TEMP}\" ; exit 0" 0 1 2 3 15
		bin2fex /boot/script.bin ${TEMP}/tempfex.txt >/dev/null 2>&1
		dialog --title "Edit u-boot environment" \
		--ok-label "Save" --no-collapse --editbox ${TEMP}/tempfex.txt $mon_y 0 2> ${TEMP}/tempfex.out
		[[ $? = 0 ]] && fex2bin ${TEMP}/tempfex.out /boot/script.bin
	;;




	#
	# Install kernel headers
	#
	"Headers_install" )
		if ! is_package_manager_running; then
			if [[ -f /etc/armbian-release ]]; then
				INSTALL_PKG="linux-headers-${BRANCH}-${LINUXFAMILY}";
				else
				INSTALL_PKG="linux-headers-$(uname -r | sed 's/'-$(dpkg --print-architecture)'//')";
			fi
			debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
		fi
	;;


	#
	# Remove kernel headers
	#
	"Headers_remove" )
		if ! is_package_manager_running; then
			REMOVE_PKG="linux-headers-*"
			if [[ -n $(dpkg -l | grep linux-headers) ]]; then
				debconf-apt-progress -- apt-get -y purge ${REMOVE_PKG}
				rm -rf /usr/src/linux-headers*
			else
				debconf-apt-progress -- apt-get -y install ${INSTALL_PKG}
			fi
			# cleanup
			apt clean
			debconf-apt-progress -- apt -y autoremove
		fi
	;;


	#
	# Install kernel source
	#
	"Source_install" )
		if ! is_package_manager_running; then

			if [[ -z $scripted ]]; then
				LIST=()
				for pkg in $SOURCE_PKG_LIST
				do
					LIST+=( "$pkg" "" )
				done

				exec 3>&1
				selection=$(dialog --backtitle "$BACKTITLE" --title "Kernel install" --clear --cancel-label "Back" \
				--menu "Choose kernel version" 12 70 ${#LIST[@]} "${LIST[@]}" 2>&1 1>&3)
				exit_status=$?
				exec 3>&-
				[[ $exit_status == 1 || $exit_status == 255 ]] && clear
			else
				selection=$(echo $SOURCE_PKG_LIST | awk '{ print $NF }')
			fi

			PACKAGE=$(echo "$selection" | sed "s/-current//" | sed "s/-dev//" | sed "s/-edge//" | sed "s/-legacy//")
			if [[ -n $PACKAGE ]]; then
				debconf-apt-progress -- apt-get -y install ${selection}
				mkdir -p /usr/src/$PACKAGE
				(pv -n /usr/src/$PACKAGE".tar.xz" | xz -d -T0 - | tar xf - -C /usr/src/$PACKAGE ) 2>&1 | dialog --colors --backtitle "$BACKTITLE" --title " Please wait! " --gauge "\nDecompressing kernel sources to /usr/src/$PACKAGE" 8 80
				xz -d /usr/src/*config.xz --stdout > /usr/src/$PACKAGE/.config
				rm /usr/src/$PACKAGE".tar.xz" /usr/src/*config.xz
				apt clean
				debconf-apt-progress -- apt-get -y purge linux-source*
				debconf-apt-progress -- apt -y autoremove
				if [[ -z $scripted ]]; then
					dialog --colors --backtitle "$BACKTITLE" --no-collapse --title " Kernel source " --clear --msgbox "\nYou will find pre-configured kernel sources in /usr/src/$PACKAGE" 7 72
				fi
			else
				dialog --backtitle "$BACKTITLE" --title " Please wait " --infobox "\nLoading software submodule ... " 5 34
			fi
		fi
	;;



	#
	# Remove kernel source
	#
	"Source_remove" )
		if ! is_package_manager_running; then

			if [[ -z $scripted ]]; then
				LIST=()
				for pkg in $SOURCE_PKG_LIST_INSTALLED
				do
					LIST+=( "$pkg" "" )
				done

				exec 3>&1
				selection=$(dialog --backtitle "$BACKTITLE" --title "Kernel remove" --clear --cancel-label "Back" \
				--menu "Choose kernel version" 12 70 ${#LIST[@]} "${LIST[@]}" 2>&1 1>&3)
				exit_status=$?
				exec 3>&-
				[[ $exit_status == 1 || $exit_status == 255 ]] && clear
			else
				selection=$(echo $SOURCE_PKG_LIST_INSTALLED | awk '{ print $NF }')
			fi

			if [[ -n $selection ]]; then
				PACKAGE="linux-source-$(echo $selection | sed 's/[-|(|[:alpha:]|(|[:space:]|(|/]//g')-${BRANCH}-${LINUXFAMILY}"
				if ls $selection 1> /dev/null 2>&1; then
					debconf-apt-progress -- apt-get -y purge $PACKAGE
					debconf-apt-progress -- apt -y autoremove
					apt clean
					dialog --backtitle "$BACKTITLE" --title " Please wait " --infobox "\nRemoving $selection ... " 5 72
					rm -r $selection
				fi
				if [[ -z $scripted ]]; then
					dialog --colors --backtitle "$BACKTITLE" --no-collapse --title " Kernel source " --clear --msgbox "\n$selection removed" 7 72
				fi
			else
				dialog --backtitle "$BACKTITLE" --title " Please wait " --infobox "\nLoading software submodule ... " 5 34
			fi
		fi
	;;



	# Toggle mini and full firmware
	#
	"Full"|"Mini" )
		if ! is_package_manager_running; then
			debconf-apt-progress -- apt-get -y purge armbian-firmware* # workaround since pkg replace doesn't work properly
			debconf-apt-progress -- apt-get -y install armbian-firmware$(echo -"${1,,}" | sed 's/-mini//')
		fi
	;;


	# Set the display resolution
	#
	"Display" )
		# show display modes menu
		if [[ -f /usr/bin/h3disp ]]; then
			# h3 boards
			get_h3modes
			dialog --title " Display output type " --colors --help-button --help-label "Cancel" --no-label "DVI" --yes-label "HDMI" \
			--backtitle "$BACKTITLE" --yesno "\nIn case you use an HDMI-to-DVI converter choose DVI!" 7 57
			output_type=$?
			if [[ $output_type = 0 || $output_type = 1 ]]; then
				if [[ $output_type = 0 ]]; then
					display_cmd="h3disp -m $SCREEN_RESOLUTION";
					else
					display_cmd="h3disp -m $SCREEN_RESOLUTION -d";
				fi


			fi
		elif [[ "$LINUXFAMILY" = odroidc* || "$LINUXFAMILY" = odroidn2 ]]; then
			get_odroidmodes
			display_cmd="sed -i \"s/^setenv m .*/# &/\" /boot/boot.ini;sed -i '/setenv m \"$SCREEN_RESOLUTION\"/s/^# //g' /boot/boot.ini";
			# odroid n2
			display_cmd='sed -i "s/^setenv hdmimode .*/setenv hdmimode \"$SCREEN_RESOLUTION\"/" /boot/boot.ini; sed -i "s/^setenv display_autodetect .*/setenv display_autodetect \"false\"/" /boot/boot.ini';
		else
			# a20 boards
			get_a20modes
			display_cmd="sed -i \"s/^disp_mode=.*/disp_mode=$SCREEN_RESOLUTION/\" /boot/armbianEnv.txt";
		fi

		dialog --title " Display resolution " --colors --no-label "Cancel" --backtitle "$BACKTITLE" --yesno \
		"\nSwitching to \Z1$SCREEN_RESOLUTION\Z0 and reboot?" 7 42
		if [[ $? = 0 ]]; then
			eval $display_cmd > /dev/null
			reboot
		fi
	;;


	#-------------------------------------------------------------------------------------------------------------------------------------#
	#-------------------------------------------------------------------------------------------------------------------------------------#
	#-------------------------------------------------------------------------------------------------------------------------------------#



	# Select dynamic or edit static IP address
	#
	"IP" )
			select_interface
			# check if we have systemd networking in action
			SYSTEMDNET=$(service systemd-networkd status | grep -w active | grep -w running)
			dialog --title " IP address assignment " --colors --backtitle "$BACKTITLE" --help-button --help-label "Cancel" \
			--yes-label "DHCP" --no-label "Static" --yesno \
			"\n\Z1DHCP:\Z0   automatic IP assignment by your router or DHCP server\n\n\Z1Static:\Z0 manually fixed IP address" 9 70
			exitstatus=$?;

			# dynamic
			if [[ $exitstatus = 0 ]]; then
				if [[ -n $SYSTEMDNET ]]; then
					filename="/etc/systemd/network/10-${SELECTED_ADAPTER}.network"
					if [[ -f $filename ]]; then
						sed -i '/Network/,$d' $filename
						echo -e "[Network]" >>$filename
						echo -e "DHCP=ipv4" >>$filename
					fi
				else
					if [[ -n $(LC_ALL=C nmcli device status | grep $SELECTED_ADAPTER ) ]]; then
						nmcli connection delete uuid $(LC_ALL=C nmcli -f UUID,DEVICE connection show | grep $SELECTED_ADAPTER | awk '{print $1}') >/dev/null 2>&1
						nmcli con add con-name "Armbian ethernet" type ethernet ifname $SELECTED_ADAPTER >/dev/null 2>&1
						nmcli con up "Armbian ethernet" >/dev/null 2>&1
						else
						create_if_config "$SELECTED_ADAPTER" "$SELECTED_ADAPTER" "dynamic" > /etc/network/interfaces
					fi
				fi
			fi

			# static
			if [[ $exitstatus = 1 ]]; then
				create_if_config "$SELECTED_ADAPTER" "$SELECTED_ADAPTER" "fixed" > /dev/null
				if [[ -n $SYSTEMDNET ]]; then
					systemd_ip_editor "${SELECTED_ADAPTER}"
				else
					if [[ -n $(LC_ALL=C nmcli device status | grep $SELECTED_ADAPTER | grep -v unavailable ) ]]; then
						nm_ip_editor "$SELECTED_ADAPTER"
					else
						ip_editor "$SELECTED_ADAPTER" "$SELECTED_ADAPTER" "/etc/network/interfaces"
					fi
				fi
			fi
	;;

	# Start network performance daemon
	#
	"Iperf3" )
			#
			if pgrep -x "iperf3" > /dev/null
			then
				pkill iperf3
			else
				iperf3 -s -D
			fi
	;;


	# Toggle IPv6
	#
	"IPV6" )
			#
			sed -i --follow-symlinks '/^net.ipv6.conf*/d' /etc/sysctl.d/99-sysctl.conf
			if [ -f "/etc/apt/apt.conf.d/99force-ipv4" ]; then
				rm /etc/apt/apt.conf.d/99force-ipv4
				echo 'net.ipv6.conf.all.disable_ipv6 = 0' >> /etc/sysctl.d/99-sysctl.conf
				echo 'net.ipv6.conf.default.disable_ipv6 = 0' >> /etc/sysctl.d/99-sysctl.conf
				echo 'net.ipv6.conf.lo.disable_ipv6 = 0' >> /etc/sysctl.d/99-sysctl.conf
			else
				echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
				echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/99-sysctl.conf
				echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.d/99-sysctl.conf
				echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/99-sysctl.conf
			fi
			sysctl -p > /dev/null
	;;


	# Connect to wireless access point
	#
	"WiFi" )
		# disable AP mode on certain adapters
		wlan_exceptions "off"
		[[ "$reboot_module" == true ]] && dialog --backtitle "$BACKTITLE" --title " Warning " --msgbox "\nReboot is required for this adapter to switch to STA mode" 7 62 && reboot
		nmtui-connect
	;;


	# Connect to 3G/4G network
	#
	"LTE" )
		if ! is_package_manager_running; then
			if [[ $LTE_MODEM == *online* ]]; then
				dialog --title " LTE modem is connected " --colors --backtitle "$BACKTITLE" --yes-label "Back" --no-label "Disconnect" --yesno "\n\Z1Disconnect:\Z0 kill mobile connection\n\n" 7 42
				[[ $? = 1 ]] && lte "$LTE_MODEM_ID" "off"
			else
				dialog --title " LTE modem is disconnected " --colors --backtitle "$BACKTITLE" --yes-label "Back" --no-label "Connect" --yesno "\n\Z1Connect:\Z0 dial mobile connection\n\n" 7 42
				[[ $? = 1 ]] && lte "$LTE_MODEM_ID" "on"
			fi
		fi
	;;


	# Connect to wireless access point
	#
	"Clear" )
		# remove managed interfaces
		systemctl daemon-reload
		nmcli con delete $(nmcli --fields NAME,UUID,TYPE con | grep wifi | awk '{print $2}')
		sed 's/interface-name:wl.*//' -i /etc/NetworkManager/conf.d/10-ignore-interfaces.conf
		sed 's/,$//' -i /etc/NetworkManager/conf.d/10-ignore-interfaces.conf
		rm -f /etc/network/interfaces.d/armbian.ap.*
		rm -f /etc/dnsmasq.conf
		systemctl stop dnsmasq
		systemctl disable dnsmasq
		iptables -t nat -D POSTROUTING 1 >/dev/null 2>&1
		systemctl stop armbian-restore-iptables.service
		systemctl disable armbian-restore-iptables.service
		rm -f /etc/iptables.ipv4.nat
		rm -f /var/run/hostapd/* >/dev/null 2>&1
		reload-nety
	;;


	# Create WiFi access point
	#
	"Hotspot" )
	if ! is_package_manager_running; then
		systemctl daemon-reload
		CURRENT_UUID=$(LC_ALL=C nmcli -f DEVICE,TYPE,STATE device status | grep -w " wifi " | grep -w " disconnected")
		if [[ -n $(service hostapd status | grep -w active | grep -w running) ]]; then
			if [[ -n $HOSTAPDBRIDGE ]]; then
				dialog --title " Hostapd service is running " --colors --backtitle "$BACKTITLE" --help-button \
				--help-label "Cancel" --yes-label "Stop and reboot" --no-label "Edit" --yesno \
				"\n\Z1Stop:\Z0 stop and reboot\n\n\Z1Edit:\Z0 change basic parameters: SSID, password and channel" 9 70

			else
				dialog --title " Hostapd service is running " --colors --backtitle "$BACKTITLE" --help-button \
				--help-label "Cancel" --yes-label "Stop" --no-label "Edit" --yesno \
				"\n\Z1Stop:\Z0 stop providing Access Point\n\n\Z1Edit:\Z0 change basic parameters: SSID, password and channel" 9 70
			fi
			exitstatus=$?;
			if [[ $exitstatus = 0 ]]; then
				dialog --backtitle "$BACKTITLE" --title " Please wait " --infobox "\nDisabling hotspot. Please wait!" 5 35
				sed -i "s/^DAEMON_CONF=.*/DAEMON_CONF=/" /etc/init.d/hostapd
				# disable DNS
				systemctl daemon-reload
				systemctl disable dnsmasq.service >/dev/null 2>&1

				ifdown $WIRELESS_ADAPTER 2> /dev/null
				rm -f /etc/network/interfaces.d/armbian.ap.*
				rm -f /etc/dnsmasq.conf
				iptables -t nat -D POSTROUTING 1 >/dev/null 2>&1
				rm -f /etc/iptables.ipv4.nat
				systemctl stop armbian-restore-iptables.service
				systemctl disable armbian-restore-iptables.service				rm -f /var/run/hostapd/* >/dev/null 2>&1
				sed -i '/^iptables/ d' /etc/rc.local
				sed -i '/^service dnsmasq/ d' /etc/rc.local
				sed 's/interface-name:wl.*//' -i /etc/NetworkManager/conf.d/10-ignore-interfaces.conf
				sed 's/,$//' -i /etc/NetworkManager/conf.d/10-ignore-interfaces.conf
				iptables -F
				# reload services
				reload-nety
				[[ -n $HOSTAPDBRIDGE ]] && reboot
			fi
			if [[ $exitstatus = 1 ]]; then wlan_edit; reload-nety "reload"; fi
		elif [[ -z $CURRENT_UUID ]]; then
				dialog --title " Info " --backtitle "$BACKTITLE" --no-collapse --msgbox "\nAll wireless connections are in use." 7 40
		else
				# check for low quality drivers and combinations
				check_and_warn

				# remove interfaces from managed list
				if [[ -f /etc/NetworkManager/conf.d/10-ignore-interfaces.conf ]]; then
					sed 's/interface-name:wl.*//' -i /etc/NetworkManager/conf.d/10-ignore-interfaces.conf
					sed 's/,$//' -i /etc/NetworkManager/conf.d/10-ignore-interfaces.conf
				fi

				# clear current settings
				rm -f /etc/network/interfaces.d/armbian.ap.nat
				rm -f /etc/network/interfaces.d/armbian.ap.bridge
				service networking restart
				service NetworkManager restart
				{ for ((i = 0 ; i <= 100 ; i+=20)); do sleep 1; echo $i; done } | dialog --title " Initializing wireless adapters " --colors --gauge "" 5 50 0

				# start with basic config
				if grep -q "^## IEEE 802.11ac" /etc/hostapd.conf; then sed '/## IEEE 802.11ac\>/,/^## IEEE 802.11ac\>/ s/.*/#&/' -i /etc/hostapd.conf; fi
				if grep -q "^## IEEE 802.11a" /etc/hostapd.conf; then sed '/## IEEE 802.11a\>/,/^## IEEE 802.11a\>/ s/.*/#&/' -i /etc/hostapd.conf; fi
				if grep -q "^## IEEE 802.11n" /etc/hostapd.conf; then sed '/## IEEE 802.11n/,/^## IEEE 802.11n/ s/.*/#&/' -i /etc/hostapd.conf; fi
				sed -i "s/^channel=.*/channel=5/" /etc/hostapd.conf

				service NetworkManager reload
				# change special adapters to AP mode
				wlan_exceptions "on"
				# check for WLAN interfaces
				get_wlan_interface
				# add interface to unmanaged list
				if [[ -f /etc/NetworkManager/conf.d/10-ignore-interfaces.conf ]]; then
					[[ -z $(grep -w unmanaged-devices= /etc/NetworkManager/conf.d/10-ignore-interfaces.conf) ]] && sed '$ s/$/,/' -i /etc/NetworkManager/conf.d/10-ignore-interfaces.conf
					sed '$ s/$/'"interface-name:$WIRELESS_ADAPTER"'/' -i /etc/NetworkManager/conf.d/10-ignore-interfaces.conf
				else
					echo "[keyfile]" > /etc/NetworkManager/conf.d/10-ignore-interfaces.conf
					echo "unmanaged-devices=interface-name:$WIRELESS_ADAPTER" >> /etc/NetworkManager/conf.d/10-ignore-interfaces.conf
				fi
				service NetworkManager reload
				# display dialog
				dialog --colors --backtitle "$BACKTITLE" --title "Please wait" --infobox \
				"\nWireless adapter: \Z1${WIRELESS_ADAPTER}\Z0\n\nProbing nl80211 hostapd driver compatibility." 7 50
				debconf-apt-progress -- apt-get --reinstall -o Dpkg::Options::="--force-confnew" -y -qq --no-install-recommends install hostapd
				# change to selected interface
				sed -i "s/^interface=.*/interface=$WIRELESS_ADAPTER/" /etc/hostapd.conf
				# add hostapd.conf to services
				sed -i "s/^DAEMON_CONF=.*/DAEMON_CONF=\/etc\/hostapd.conf/" /etc/init.d/hostapd
				# check both options
				# add allow cli access if not exists. temporally
				if ! grep -q "ctrl_interface" /etc/hostapd.conf; then
					echo "" >> /etc/hostapd.conf
					echo "ctrl_interface=/var/run/hostapd" >> /etc/hostapd.conf
					echo "ctrl_interface_group=0" >> /etc/hostapd.conf
				fi
				#
				check_advanced_modes
				#
				if [[ -n "$hostapd_error" ]]; then
					dialog --colors --backtitle "$BACKTITLE" --title "Please wait" --infobox \
					"\nWireless adapter: \Z1${WIRELESS_ADAPTER}\Z0\n\nProbing Realtek hostapd driver compatibility." 7 50
					debconf-apt-progress -- apt-get --reinstall -o Dpkg::Options::="--force-confnew" -y -qq --no-install-recommends install hostapd-realtek
					# change to selected interface
					sed -i "s/^interface=.*/interface=$WIRELESS_ADAPTER/" /etc/hostapd.conf
					# add allow cli access if not exists. temporally
					if ! grep -q "ctrl_interface" /etc/hostapd.conf; then
						echo "ctrl_interface=/var/run/hostapd" >> /etc/hostapd.conf
						echo "ctrl_interface_group=0" >> /etc/hostapd.conf
					fi
					#
					check_advanced_modes
					#
				fi

				if [[ -n "$hostapd_error" ]]; then
					dialog --backtitle "$BACKTITLE" --title "Warning" \
					--infobox "\nWireless adapter: $WIRELESS_ADAPTER\n\nNo compatible hostapd driver found." 7 39
					sed -i "s/^DAEMON_CONF=.*/DAEMON_CONF=/" /etc/init.d/hostapd
					# remove interfaces from managed list
					sed 's/interface-name:wl.*//' -i /etc/NetworkManager/conf.d/10-ignore-interfaces.conf
					sed 's/,$//' -i /etc/NetworkManager/conf.d/10-ignore-interfaces.conf
					systemctl daemon-reload;service hostapd restart
				fi

				# let's remove bridge out for this simple configurator
				#
				# dialog --title " Choose Access Point mode for $WIRELESS_ADAPTER " --colors --backtitle "$BACKTITLE" --no-label "Bridge" \
				# --yes-label "NAT" --yesno "\n\Z1NAT:\Z0 with own DHCP server, out of your primary network\n\
				# \n\Z1Bridge:\Z0 wireless clients will use your routers DHCP server" 9 70
				# response=$?
				#
				# let's remove bridge out for this simple configurator

				response=0

				# create interfaces file if not exits
				[[ ! -f /etc/network/interfaces ]] && echo "source /etc/network/interfaces.d/*" > /etc/network/interfaces

				# select default interfaces if there is more than one
				select_default_interface

				NETWORK_CONF="/etc/network/interfaces"

				case $response in
					# bridge
					1)
						TEMP_CONF="/etc/network/interfaces.d/armbian.ap.bridge"

						sed -i 's/.bridge=.*/bridge=br0/' /etc/hostapd.conf
						if [[ $DEFAULT_ADAPTER == "br0" ]]; then NEW_DEFAULT_ADAPTER="eth0"; else NEW_DEFAULT_ADAPTER="$DEFAULT_ADAPTER"; fi
						echo -e "#bridged wireless for hostapd by armbian-config\n" > $TEMP_CONF
						echo -e "auto lo br0\niface lo inet loopback" >> $TEMP_CONF
						echo -e "\nauto $NEW_DEFAULT_ADAPTER\nallow-hotplug $NEW_DEFAULT_ADAPTER\niface $NEW_DEFAULT_ADAPTER inet manual" >> $TEMP_CONF
						echo -e "\nauto $WIRELESS_ADAPTER\nallow-hotplug $WIRELESS_ADAPTER\niface $WIRELESS_ADAPTER inet manual\n" >> $TEMP_CONF
						create_if_config "$DEFAULT_ADAPTER" "br0" >> $TEMP_CONF
						echo -e "\nbridge_ports $NEW_DEFAULT_ADAPTER $WIRELESS_ADAPTER" >> $TEMP_CONF

					;;
					# NAT
					0)
						TEMP_CONF="/etc/network/interfaces.d/armbian.ap.nat"

						# install dnsmas and iptables
						if [[ $(dpkg-query -W -f='${db:Status-Abbrev}\n' dnsmasq 2>/dev/null) != "*ii*" ]]; then
							debconf-apt-progress -- apt-get -qq -y --no-install-recommends install dnsmasq iptables
							systemctl enable dnsmasq
						fi

						echo -e "# armbian NAT hostapd\nallow-hotplug $WIRELESS_ADAPTER\niface $WIRELESS_ADAPTER inet static " > $TEMP_CONF
						echo -e "\taddress 172.24.1.1\n\tnetmask 255.255.255.0\n\tnetwork 172.24.1.0\n\tbroadcast 172.24.1.255" >> $TEMP_CONF
						# create new configuration
						echo "interface=$WIRELESS_ADAPTER				# Use interface $WIRELESS_ADAPTER" > /etc/dnsmasq.conf
						echo "listen-address=172.24.1.1					# Explicitly specify the address to listen on" >> /etc/dnsmasq.conf
						echo "bind-interfaces							# Bind to the interface to make sure we aren't sending \
						things elsewhere" >> /etc/dnsmasq.conf
						echo "server=8.8.8.8							# Forward DNS requests to Google DNS" >> /etc/dnsmasq.conf
						echo "domain-needed								# Don't forward short names" >> /etc/dnsmasq.conf
						echo "bogus-priv								# Never forward addresses in the non-routed address spaces" \
						>> /etc/dnsmasq.conf
						echo "dhcp-range=172.24.1.50,172.24.1.150,12h	# Assign IP addresses between 172.24.1.50 and 172.24.1.150 with \
						a 12 hour lease time" >> /etc/dnsmasq.conf
						# - Enable IPv4 forwarding
						sed -i "/net.ipv4.ip_forward=/c\net.ipv4.ip_forward=1" /etc/sysctl.conf
						echo 1 > /proc/sys/net/ipv4/ip_forward
						# Clear iptables
						iptables-save | awk '/^[*]/ { print $1 } /^:[A-Z]+ [^-]/ { print $1 " ACCEPT" ; } /COMMIT/ { print $0; }' | iptables-restore
						# - Apply iptables
						iptables -t nat -A POSTROUTING -o $DEFAULT_ADAPTER -j MASQUERADE
						iptables -A FORWARD -i $DEFAULT_ADAPTER -o $WIRELESS_ADAPTER -m state --state RELATED,ESTABLISHED -j ACCEPT
						iptables -A FORWARD -i $WIRELESS_ADAPTER -o $DEFAULT_ADAPTER -j ACCEPT
						# - Save IP tables, applied during ifup in /etc/network/interfaces.
						iptables-save > /etc/iptables.ipv4.nat
						sed -i 's/^bridge=.*/#&/' /etc/hostapd.conf
						#sed -e 's/exit 0//g' -i /etc/rc.local
						# workaround if hostapd is too slow
						#echo "service dnsmasq start" >> /etc/rc.local
						#echo "iptables-restore < /etc/iptables.ipv4.nat" >> /etc/rc.local
						#echo "exit 0" >> /etc/rc.local
						systemctl stop armbian-restore-iptables.service
						systemctl disable armbian-restore-iptables.service
						cat <<-EOF > /etc/systemd/system/armbian-restore-iptables.service
						[Unit]
						Description="Restore IP tables"
						[Timer]
						OnBootSec=20Sec
						[Service]
						Type=oneshot
						ExecStart=/sbin/iptables-restore /etc/iptables.ipv4.nat
						[Install]
						WantedBy=sysinit.target
						EOF
						systemctl enable armbian-restore-iptables.service
					;;
				3)exit;;

				255) exit;;
				esac

				dialog --backtitle "$BACKTITLE" --title " Please wait " --infobox "\nEnabling hotspot. Please wait!" 5 34

				#
				# only for bridged connection we need to check and reboot. tdlr check if it can be done on the fly
				HOSTAPDBRIDGE=$(cat /etc/hostapd.conf 2> /dev/null | grep -w "^bridge=br0")
				if [[ -n $HOSTAPDBRIDGE ]]; then
						dialog --title "Manually adjust network configuration if needed" --backtitle "$BACKTITLE" \
						--ok-label "Reboot to apply new settings" --no-collapse --editbox $TEMP_CONF 30 0 2> $TEMP_CONF".tmp"
						response=$?
						if [[ $response = 0 ]]; then
							mv $TEMP_CONF".tmp" $TEMP_CONF
							#reboot
						fi
					else
						ifdown $WIRELESS_ADAPTER 2> /dev/null
						sleep 2
						ifup $WIRELESS_ADAPTER 2> /dev/null
						echo "nameserver 8.8.8.8" > /etc/resolvconf/resolv.conf.d/base
						[[ "$reboot_module" == true ]] && dialog --backtitle "$BACKTITLE" --title " Warning " --msgbox "\nReboot is required for this adapter to switch to AP mode" 7 61 && reboot
						# reload services
						reload-nety "reload"
				fi
		fi
	fi
	;;


	# Manage Softether VPN
	#
	"VPN" )
	VPNDIR="/usr/local/vpnclient/"

	function vpn_reconfigure ()
	{
	if [[ -f /etc/server.vpn ]]; then
		${VPNDIR}vpnclient stop >/dev/null 2>&1
		${VPNDIR}vpnclient start >/dev/null 2>&1
		# purge old settings
		${VPNDIR}vpncmd /client localhost /cmd accountlist | grep "VPN Connection Setting Name" | cut -d "|" -f 2 | sed 's/^/"/;s/$/"/' | xargs /usr/local/vpnclient/vpncmd /client localhost /cmd accountdisconnect >/dev/null 2>&1
		${VPNDIR}vpncmd /client localhost /cmd accountlist | grep "VPN Connection Setting Name" | cut -d "|" -f 2 | sed 's/^/"/;s/$/"/' | xargs /usr/local/vpnclient/vpncmd /client localhost /cmd accountdelete >/dev/null 2>&1
		# import new
		${VPNDIR}vpncmd /client localhost /cmd accountimport //etc//server.vpn >/dev/null 2>&1
		# reload to connect
		${VPNDIR}vpnclient stop >/dev/null 2>&1
		${VPNDIR}vpnclient start >/dev/null 2>&1
		[[ $? = 0 ]] && dialog --backtitle "$BACKTITLE" --title " VPN " --msgbox "\nConfiguration was successfully imported!" 7 43
	fi
	}

	function get_numbers {
		EXCLUDE=$(ip neigh | grep vpn_se | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.' | head -1)
		ADAPTER=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | grep -v vpn_se | head -1)
		IP=$(ip route | grep $ADAPTER | grep default | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1)
		VPNSERVERIP=$(${VPNDIR}vpncmd /client localhost /cmd accountlist | grep "VPN Server" |grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1)
		SUBNET=$(ifconfig vpn_se | grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
		GW=$(ip neigh | grep vpn_se | grep $SUBNET | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1)
	}

	function raise_dev {
		i=0;
		while [[ -z "$TEMP" && $i<5 ]]; do
				TEMP=$(${VPNDIR}vpncmd /client localhost /cmd accountlist | grep Status | grep Connected)
				sleep 1
				i=$((i+1))
		done
		dhclient vpn_se
	}

	if pgrep -x "vpnclient" > /dev/null
	then
		${VPNDIR}vpnclient stop >/dev/null 2>&1
		${VPNDIR}vpnclient start >/dev/null 2>&1
		if [[ -z $(${VPNDIR}vpncmd /client localhost /cmd nicList | grep Enabled) ]]; then
			${VPNDIR}vpncmd /client localhost /cmd niccreate se >/dev/null 2>&1
		fi
		if [[ -z $(${VPNDIR}vpncmd /client localhost /cmd accountlist | grep "VPN Server") ]]; then
			dialog --backtitle "$BACKTITLE" --no-label " Cancel " --yes-label " Import " --title " VPN " --yesno "\nA VPN configuration was not found.\n\nPlace valid file at /etc/server.vpn" 9 45
			if [[ $? = 0 && -f /etc/server.vpn ]]; then
				${VPNDIR}vpncmd /client localhost /cmd accountimport //etc//server.vpn >/dev/null 2>&1
				${VPNDIR}vpnclient stop >/dev/null 2>&1
				${VPNDIR}vpnclient start >/dev/null 2>&1
				[[ $? = 0 ]] && dialog --backtitle "$BACKTITLE" --title " VPN " --msgbox "\nConfiguration was successfully imported!" 7 43
			fi
		fi

		# raise devices
		raise_dev

		if [[ -n $(${VPNDIR}vpncmd /client localhost /cmd accountlist | grep Status | grep Connected) ]]; then
			get_numbers
			echo "ip route add $VPNSERVERIP via $IP dev $ADAPTER"
			echo "ip route del default"
			echo "ip route add default via $GW dev vpn_se"
			read
			dialog --title "VPN client is connected to $VPNSERVERIP" --colors --backtitle "$BACKTITLE" --help-button --help-label "Cancel" --yes-label "Stop" --no-label " Import " --yesno "\n\Z1Stop:  \Z0 stop\n\n\Z1Import:\Z0 import new config from /etc/armbian.vpn" 9 70
		fi
		response=$?
		if [[ $response = 0 ]]; then
			get_numbers
			echo "ip route del $VPNSERVERIP"
			echo "ip route del default"
			echo "ip route add default via $IP dev $ADAPTER"
			read
			dialog --backtitle "$BACKTITLE"  --nocancel --nook --infobox "\nClosing VPN connection" 5 27
			${VPNDIR}vpnclient stop >/dev/null 2>&1
		fi
	else
		dialog --title "VPN client is disconnected" --colors --backtitle "$BACKTITLE" --help-button --help-label "Cancel" --yes-label "Connect" --no-label " Import " --yesno "\n\Z1Connect:\Z0 Connect with your VPN server \n\n\Z1Import:\Z0 import new config from /etc/armbian.vpn" 9 70
		response=$?
		if [[ $response = 0 ]]; then
			${VPNDIR}vpnclient start >/dev/null 2>&1

			# raise devices
			raise_dev
			get_numbers
			echo "ip route add $VPNSERVERIP via $IP dev $ADAPTER"
			echo "ip route del default"
			echo "ip route add default via $GW dev vpn_se"
			read

		fi
		[[ $response = 1 ]] && vpn_reconfigure
	fi
	;;


	# Connect to Bluetooth
	#
	"BT discover" )
		dialog --backtitle "$BACKTITLE" --title " Bluetooth " --msgbox "\nVerify that your Bluetooth device is discoverable!" 7 54
		connect_bt_interface
	;;


	# Edit network settings
	#
	"Advanced" )
		dialog --backtitle "$BACKTITLE" --title " Edit ifupdown network configuration /etc/network/interfaces" --no-collapse \
		--ok-label "Save" --editbox /etc/network/interfaces 30 0 2> /etc/network/interfaces.out
		[[ $? = 0 ]] && mv /etc/network/interfaces.out /etc/network/interfaces && reload-nety "reload"
	;;

	# Remove automatic wifi conections
	#
	"Forget" )
		LC_ALL=C nmcli --fields UUID,TIMESTAMP-REAL,TYPE con show | grep wifi |  awk '{print $1}' | while read line; \
		do nmcli con delete uuid  $line; done > /dev/null
	;;




	#-------------------------------------------------------------------------------------------------------------------------------------#
	#-------------------------------------------------------------------------------------------------------------------------------------#
	#-------------------------------------------------------------------------------------------------------------------------------------#




	# Change timezone
	#
	"Timezone" )
		dpkg-reconfigure tzdata
	;;


	# Change locales
	#
	"Locales" )
		dpkg-reconfigure locales
		source /etc/default/locale
		sed -i "s/^LANGUAGE=.*/LANGUAGE=$LANG/" /etc/default/locale
		export LANGUAGE=$LANG
	;;

	# Change keyboard
	#
	"Keyboard" )
		dpkg-reconfigure keyboard-configuration
		setupcon
	;;

	# Change Hostname
	#
	"Hostname" )
		hostname_current=$(cat /etc/hostname)
		hostname_new=$(\
		dialog --no-cancel --title " Change hostname " --backtitle "$BACKTITLE" --inputbox "\nType new hostname\n " 10 50 $hostname_current \
		3>&1 1>&2 2>&3 3>&- \
		)
		if [[ $? = 0 && -n $hostname_new ]]; then
			sed -i "s/$hostname_current/$hostname_new/g" /etc/hosts
			sed -i "s/$hostname_current/$hostname_new/g" /etc/hostname
			hostname $hostname_new
			systemctl restart systemd-logind.service
			dialog --title " Info " --backtitle "$BACKTITLE" --no-collapse --msgbox "\nYou need to logout to make the changes effective." 7 53
		fi
	;;

	# Bash
	#
	"BASH" )
		if ! is_package_manager_running; then
			debconf-apt-progress -- apt-get purge -y armbian-zsh
			BASHLOCATION=$(grep /bash$ /etc/shells | tail -1)
			# change shell back to bash for future users
			sed -i "s|^SHELL=.*|SHELL=${BASHLOCATION}|" /etc/default/useradd
			sed -i "s|^DSHELL=.*|DSHELL=${BASHLOCATION}|" /etc/adduser.conf
			# change to BASH shell for root and all normal users
			awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534 || $3 == 0) print $1}' /etc/passwd | xargs -L1 chsh -s $(grep /bash$ /etc/shells | tail -1)
			if [[ -z $scripted ]]; then
			dialog --backtitle "$BACKTITLE" --title "Info" --colors --msgbox "\nYour default shell was switched to: \Z1BASH\Z0\n\nPlease logout & login from this session!" 9 47
			fi
		fi
	;;


	# ZSH
	#
	"ZSH" )
		if ! is_package_manager_running; then
			debconf-apt-progress -- apt-get update
			debconf-apt-progress -- apt-get install -y armbian-zsh
			awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534 || $3 == 0) print $1}' /etc/passwd | xargs -L1 chsh -s $(grep /zsh$ /etc/shells | tail -1)
			if [[ -z $scripted ]]; then
				dialog --backtitle "$BACKTITLE" --title "Info" --colors --msgbox "\nYour default shell was switched to: \Z1ZSH\Z0\n\nPlease logout & login from this session!" 9 47
			fi
		fi
	;;


	# Firmware update
	#
	"Firmware" )
		if ! is_package_manager_running; then
			clear
			exec 3>&1
			monitor=$(dialog --print-maxsize 2>&1 1>&3)
			exec 3>&-
			mon_x=$(echo $monitor | awk '{print $2}' | sed 's/,//');mon_x=$(( $mon_x / 2 ))
			mon_y=$(echo $monitor | awk '{print $3}' | sed 's/,//');
			if [[ -z $scripted ]]; then
			dialog --title " Update " --backtitle "$BACKTITLE" --no-label "No" --yesno "\nDo you want to update board firmware?" 7 41
			fi
			if [[ $? -eq 0 ]]; then

				# unfreeze packages
				apt-mark showhold | egrep "linux|armbian" | xargs sudo apt-mark unhold

				debconf-apt-progress -- apt --fix-broken -y install
				debconf-apt-progress -- apt-get -o Acquire::CompressionTypes::Order::=gz -o Acquire::http::No-Cache=true -o Acquire::BrokenProxy=true -o Acquire::http::Pipeline-Depth=0 update
				debconf-apt-progress -- apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y upgrade
				[[ -z $scripted ]] && \
				dialog --title " Firmware update " --colors --no-label "No" --backtitle "$BACKTITLE" --yesno \
				"\nFirmware has been updated. Reboot?   " 7 39
				if [[ $? -eq 0 ]]; then reboot; fi
			fi
		fi
	;;


	# Install to SATA, eMMC, NAND or USB
	#
	"Install" )
		nand-sata-install
	;;


	# Freeze and unfreeze kernel and board support packages
	#
	"Freeze" | "Defreeze" )
	if ! is_package_manager_running; then
		if [[ -z $scripted ]]; then dialog --title " Updating " --backtitle "$BACKTITLE" --yes-label "$1" --no-label "Cancel" --yesno \
		"\nDo you want to ${1,,} Armbian firmware updates?" 7 54
		fi
		if [[ $? -eq 0 ]]; then

			unset PACKAGE_LIST

			# basic packages

			check_if_installed linux-u-boot-${BOARD}-${BRANCH} && PACKAGE_LIST+=" linux-u-boot-${BOARD}-${BRANCH}"
			check_if_installed linux-image-${BRANCH}-${LINUXFAMILY} && PACKAGE_LIST+=" linux-image-${BRANCH}-${LINUXFAMILY}"
			check_if_installed linux-dtb-${BRANCH}-${LINUXFAMILY} && PACKAGE_LIST+=" linux-dtb-${BRANCH}-${LINUXFAMILY}"
			check_if_installed linux-headers-${BRANCH}-${LINUXFAMILY} && PACKAGE_LIST+=" linux-headers-${BRANCH}-${LINUXFAMILY}"

			# new BSP
			check_if_installed armbian-${LINUXFAMILY} && PACKAGE_LIST+=" armbian-${LINUXFAMILY}"
			check_if_installed armbian-${BOARD} && PACKAGE_LIST+=" armbian-${BOARD}"
			check_if_installed armbian-${DISTROID} && PACKAGE_LIST+=" armbian-${DISTROID}"
			check_if_installed armbian-bsp-cli-${BOARD} && PACKAGE_LIST+=" armbian-bsp-cli-${BOARD}"
			check_if_installed armbian-${DISTROID}-desktop-xfce && PACKAGE_LIST+=" armbian-${DISTROID}-desktop-xfce"
			check_if_installed armbian-firmware && PACKAGE_LIST+=" armbian-firmware"
			check_if_installed armbian-firmware-full && PACKAGE_LIST+=" armbian-firmware-full"

			local words=( $PACKAGE_LIST )
			local command="unhold"
			IFS=" "
			[[ $1 == "Freeze" ]] && local command="hold"
			for word in $PACKAGE_LIST; do apt-mark $command $word; done | dialog --backtitle "$BACKTITLE" --title "Packages ${1,,}" --progressbox $((${#words[@]}+2)) 64
			fi
		fi
	;;


	# Switch to other kernel versions
	"Other")
	if ! is_package_manager_running; then
		other_kernel_version
	fi
	;;



	# Enable or disable desktop
	#
	"Desktop" )
		if [[ -n $DISPLAY_MANAGER ]]; then
			dialog --title " Desktop is enabled and running " --backtitle "$BACKTITLE" \
			--yes-label "Stop" --no-label "Cancel" --yesno "\nDo you want to stop and disable this service?" 7 50
			exitstatus=$?;
			if [[ $exitstatus = 0 ]]; then
				function stop_display()
				{
					bash -c "service lightdm stop >/dev/null 2>&1
					systemctl disable lightdm.service >/dev/null 2>&1
					service nodm stop >/dev/null 2>&1
					systemctl disable nodm.service >/dev/null 2>&1"
				}
				if xhost >& /dev/null ; then
					stop_display &
				else
					stop_display
				fi
			fi
		else
			if ! is_package_manager_running; then
				# remove nodm and install lightdm = backward compatibility
				[[ -n $(dpkg -l | grep nodm) ]] && debconf-apt-progress -- apt-get -y purge nodm
				[[ -z $(dpkg -l | grep lightdm) ]] && debconf-apt-progress -- apt-get -o Dpkg::Options::="--force-confold" -y --no-install-recommends install lightdm-gtk-greeter lightdm
				if [[ -n $DESKTOP_INSTALLED ]]; then
					dialog --title " Display manager " --backtitle "$BACKTITLE" --yesno "\nDo you want to enable autologin?" 7 36
					exitstatus=$?;
					if [[ $exitstatus = 0 ]]; then
						add_choose_user
						if [ -n "$CHOSEN_USER" ]; then
							mkdir -p /etc/lightdm/lightdm.conf.d
							echo "[Seat:*]" > /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
							echo "autologin-user=$CHOSEN_USER" >> /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
							echo "autologin-user-timeout=0" >> /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
							echo "user-session=xfce" >> /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf
							ln -s /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service >/dev/null 2>&1
							service lightdm start >/dev/null 2>&1
						fi
					else
						rm /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf >/dev/null 2>&1
						ln -s /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service >/dev/null 2>&1
						service lightdm start >/dev/null 2>&1
					fi
					# kill this bash script after desktop is up and if executed on console
					[[ $(tty | sed -e "s:/dev/::") == tty* ]] && kill -9 $$
				fi
			fi
		fi
	;;

	"Default" )

		RELEASE=$(source /etc/os-release; echo $VERSION_CODENAME)
		LIST=($(apt list 2>/dev/null | grep armbian | grep desktop | grep -v bsp | grep "\-"$RELEASE | sed "s/\/$RELEASE,$RELEASE//g" | cut -d" " -f1-2))
		LIST_LENGTH=$((${#LIST[@]}/2));
		exec 3>&1
			TARGET_DESKTOP=$(dialog --cancel-label "Cancel" --backtitle "$BACKTITLE" --no-collapse --title "Select Armbian optimised desktop" --clear --menu "" $((6+${LIST_LENGTH})) 52 25 "${LIST[@]}" 2>&1 1>&3)
			exitstatus=$?;
		exec 3>&-

		if [[ $exitstatus = 0 ]]; then
			configure_desktop "--install-recommends" "$TARGET_DESKTOP"
		fi
	;;

	"RDP" )
		if [[ -n $(service xrdp status | grep -w active) ]]; then
			systemctl stop xrdp.service >/dev/null 2>&1
			systemctl disable xrdp.service >/dev/null 2>&1
		else
			if ! is_package_manager_running; then
				debconf-apt-progress -- apt-get -y install xrdp xorgxrdp
				systemctl enable xrdp.service >/dev/null 2>&1
				systemctl start xrdp.service >/dev/null 2>&1
				dialog --title "Info" --backtitle "$BACKTITLE" --nocancel --no-collapse --pause \
				"\nRemote graphical login to $BOARD_NAME using Microsoft Remote Desktop Protocol (RDP) is enabled." 11 57 3

			fi
		fi
	;;

	"Thunderbird" )
		if ! check_if_installed thunderbird; then
			debconf-apt-progress -- apt-get -y install thunderbird
		else
			debconf-apt-progress -- apt-get -y purge thunderbird
		fi
	;;

	"Gimp" )
		if ! check_if_installed gimp; then
			debconf-apt-progress -- apt-get -y install gimp
		else
			debconf-apt-progress -- apt-get -y purge gimp
		fi
	;;

	"Libre" )
		debconf-apt-progress -- apt-get -y purge libreoffice*
	;;

	"Writer" )
		pkg_install="libreoffice-writer libreoffice-style-tango"
		if [[ "$DISTROID" == "xenial" ]]; then pkg_install+=" libreoffice-gtk"; else pkg_install+=" libreoffice-gtk2"; fi
		debconf-apt-progress -- apt-get -y install $pkg_install
	;;

	"Suite" )
		pkg_install="libreoffice libreoffice-style-tango"
		if [[ "$DISTROID" == "xenial" ]]; then pkg_install+=" libreoffice-gtk"; else pkg_install+=" libreoffice-gtk2"; fi
		debconf-apt-progress -- apt-get -y install $pkg_install
	;;


	# Stop low-level messages on console
	#
	"Lowlevel" )
		dialog --title " Kernel messages " --backtitle "$BACKTITLE" --help-button \
		--help-label "Yes & reboot" --yes-label "Yes" --no-label "Cancel" --yesno "\nStop low-level messages on console?" 7 64
		exitstatus=$?;
		[[ $exitstatus = 0 ]] && sed -i 's/^#kernel.printk\(.*\)/kernel.printk\1/' /etc/sysctl.conf
		[[ $exitstatus = 2 ]] && sed -i 's/^#kernel.printk\(.*\)/kernel.printk\1/' /etc/sysctl.conf && reboot
	;;

	# CPU speed and governor
	#
	"CPU" )
		POLICY="policy0"
		[[ $(grep -c '^processor' /proc/cpuinfo) -gt 4 ]] && POLICY="policy4"
		[[ ! -d /sys/devices/system/cpu/cpufreq/policy4 ]] && POLICY="policy0"
		[[ -d /sys/devices/system/cpu/cpufreq/policy0 && -d /sys/devices/system/cpu/cpufreq/policy2 ]] && POLICY="policy2"
		generic_select "$(cat /sys/devices/system/cpu/cpufreq/$POLICY/scaling_available_frequencies 2>/dev/null || cat /sys/devices/system/cpu/cpufreq/$POLICY/cpuinfo_min_freq 2>/dev/null)" "Select minimum CPU speed"
		MIN_SPEED=$PARAMETER
		generic_select "$(cat /sys/devices/system/cpu/cpufreq/$POLICY/scaling_available_frequencies 2>/dev/null || cat /sys/devices/system/cpu/cpufreq/$POLICY/cpuinfo_max_freq 2>/dev/null)" "Select maximum CPU speed" "$PARAMETER"
		MAX_SPEED=$PARAMETER
		generic_select "$(cat /sys/devices/system/cpu/cpufreq/$POLICY/scaling_available_governors)" "Select CPU governor"
		GOVERNOR=$PARAMETER
		if [[ -n $MIN_SPEED && -n $MAX_SPEED && -n $GOVERNOR ]]; then
			dialog --colors --title " Apply and save changes " --backtitle "$BACKTITLE" --yes-label "OK" --no-label "Cancel" --yesno \
			"\nCPU frequency will be within \Z1$(($MIN_SPEED / 1000))\Z0 and \Z1$(($MAX_SPEED / 1000)) MHz\Z0. The governor \Z1$GOVERNOR\Z0 will decide which speed to use within this range." 9 58
			if [[ $? -eq 0 ]]; then
				sed -i "s/MIN_SPEED=.*/MIN_SPEED=$MIN_SPEED/" /etc/default/cpufrequtils
				sed -i "s/MAX_SPEED=.*/MAX_SPEED=$MAX_SPEED/" /etc/default/cpufrequtils
				sed -i "s/GOVERNOR=.*/GOVERNOR=$GOVERNOR/" /etc/default/cpufrequtils
				systemctl restart cpufrequtils
				sync
			fi
		fi
	;;

	"Avahi")
	if ! is_package_manager_running; then
		if check_if_installed avahi-daemon ; then
			service avahi-daemon stop
			debconf-apt-progress -- apt-get -y purge avahi-daemon
		else
			debconf-apt-progress -- apt-get -y install avahi-daemon
			[[ -f /usr/share/doc/avahi-daemon/examples/sftp-ssh.service ]] && cp /usr/share/doc/avahi-daemon/examples/sftp-ssh.service /etc/avahi/services/
			[[ -f /usr/share/doc/avahi-daemon/examples/ssh.service ]] && cp /usr/share/doc/avahi-daemon/examples/ssh.service /etc/avahi/services/
			service avahi-daemon restart
		fi
	fi
	;;


	# Edit boot environment
	#
	"Bootenv" )
		dialog --title " Edit u-boot environment " --ok-label "Save" \
		--no-collapse --editbox /boot/armbianEnv.txt 30 0 2> /boot/armbianEnv.txt.out
		[[ $? = 0 ]] && mv /boot/armbianEnv.txt.out /boot/armbianEnv.txt
		sync
	;;

	# Edit boot script
	#
	"Bootscript" )
		if [[ -f /boot/boot.ini ]]; then
			dialog --title " Edit boot.ini script " --ok-label "Save" \
			--no-collapse --editbox /boot/boot.ini 30 0 2> /boot/boot.ini.out
			[[ $? = 0 ]] && mv /boot/boot.ini.out /boot/boot.ini
		fi
	;;


	# Toggle overlay items
	#
	"Hardware" )
		# check if user agree to enter this area
		CHANGES="false"
		while true; do
			overlay_prefix=$(cat /boot/armbianEnv.txt | grep overlay_prefix | sed 's/overlay_prefix=//g')
			TARGET_BRANCH=$BRANCH
			exceptions "$BRANCH"
			MOTD=()
			LINES=()
			LIST_CONST=-3
			j=0
			DIALOG_CANCEL=1
			DIALOG_ESC=255

			def_overlays=$(ls -1 ${OVERLAYDIR}/${overlay_prefix}*.dtbo | sed 's/^.*\('${overlay_prefix}'.*\)/\1/g' | sed 's/'${overlay_prefix}'-//g' | sed 's/.dtbo//g')
			if [ $BOARDFAMILY == "rockchip-rk3588" ] && [ $BRANCH == "legacy" ]; then
        		builtin_overlays=$(ls -1 ${OVERLAYDIR}/*.dtbo | grep -v ${overlay_prefix} | sed 's#^'${OVERLAYDIR}'/##' | sed 's/.dtbo//g')
        		def_overlays="$def_overlays"'\n'"$builtin_overlays"
			fi

			while read line
			do
				STATUS=$([[ -n $(cat /boot/armbianEnv.txt | grep overlays | grep -w ${line}) ]] && echo "on")
				DESC=$(description "$line")
				MOTD+=( "$line" "$DESC" "$STATUS")
				LINES[ $j ]=$line
				(( j++ ))
			done < <(echo -e $def_overlays | tr " " "\n" )

			exec 3>&1
				selection=$(dialog --backtitle "$BACKTITLE" --colors --title "Toggle hardware configuration" --clear --cancel-label \
				"Back" --ok-label "Save" --checklist "\nUse \Z1<space>\Z0 to toggle functions and save them. Exit when you are done.\n " \
				0 0 0 "${MOTD[@]}" 2>&1 1>&3)
				exit_status=$?
			exec 3>&-

			case $exit_status in
					$DIALOG_ESC)
					break
				;;
				0)
					CHANGES="true"
					newoverlays="$(echo "$selection" | sed "s|[^ ]* *|&|g")"
					sed -i "s/^overlays=.*/overlays=$newoverlays/" /boot/armbianEnv.txt
					if ! grep -q "overlays" /boot/armbianEnv.txt; then echo "overlays=$newoverlays" >> /boot/armbianEnv.txt; fi
					if [[ -z $newoverlays ]]; then sed -i "/^overlays/d" /boot/armbianEnv.txt; fi
					sync
				;;
				1)
					if [[ "$CHANGES" == "true" ]]; then
					dialog --title " Applying changes " --backtitle "$BACKTITLE" --yes-label "Reboot" \
					--no-label "Cancel" --yesno "\nReboot to enable new features?" 7 34
					if [[ $? = 0 ]]; then reboot; else break; fi
					else
						break
					fi
				;;
				esac
			done

	;;


	# Toggle welcome screen items
	#
	"Welcome" )
		while true; do
		HOME="/etc/update-motd.d/"
		MOTD=()
		LINES=()
		LIST_CONST=9
		j=0
		DIALOG_CANCEL=1
		DIALOG_ESC=255

		while read line
		do
			STATUS=$([[ -x ${HOME}${line} ]] && echo "on")
			DESC=$(description "$line")
			MOTD+=( "$line" "$DESC" "$STATUS")
			LINES[ $j ]=$line
			(( j++ ))
		done < <(ls -1 $HOME)

				LISTLENGTH="$(($LIST_CONST+${#MOTD[@]}/3))"
				exec 3>&1
				selection=$(dialog --backtitle "$BACKTITLE" --title "Toggle motd executing scripts" --clear --cancel-label \
				"Back" --ok-label "Save" --checklist "\nChoose what you want to enable or disable:\n " \
				$LISTLENGTH 80 15 "${MOTD[@]}" 2>&1 1>&3)
				exit_status=$?
				exec 3>&-
				case $exit_status in
				$DIALOG_CANCEL | $DIALOG_ESC)
						break
						;;
				0)
						chmod -x ${HOME}*
						chmod +x $(echo "$selection" | sed "s|[^ ]* *|${HOME}&|g")
				;;
				esac
		done
	;;


	# Toggle sshd options
	#
	"SSH" )
	if ! is_package_manager_running; then
		while true; do
			if ! check_if_installed libpam-google-authenticator ; then
				debconf-apt-progress -- apt-get -y install libpam-google-authenticator
			fi
			if ! check_if_installed qrencode ; then
				debconf-apt-progress -- apt-get -y install qrencode
			fi
			DIALOG_CANCEL=2
			DIALOG_ESC=255
			LIST_CONST=9
			WINDOW_SIZE=21

			# variables cleanup
			PermitRootLogin="";
			PubkeyAuthentication="";
			PasswordAuthentication="";
			PhoneAuthentication=""
			MergeParameter="";
			ExtraDesc="";

			Buttons="--no-cancel --ok-label "Save" --help-button --help-label Cancel"

			# read values
			[[ $(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}') == "yes" ]] 			&& PermitRootLogin="on"
			[[ $(grep "^@include common-auth" /etc/pam.d/sshd | awk '{print $2}') == "common-auth" ]]  	&& PasswordAuthentication="on"
			[[ $(grep "^PubkeyAuthentication" /etc/ssh/sshd_config | awk '{print $2}') == "yes" ]]  	&& PubkeyAuthentication="on"
			[[ -n $(grep "pam_google_authenticator.so" /etc/pam.d/sshd) ]] 								&& PhoneAuthentication="on"

			# create menu
			MOTD=( "PermitRootLogin" "Allow root login" "$PermitRootLogin" )
			MOTD+=( "PasswordAuthentication" "Password login" "$PasswordAuthentication" )
			MOTD+=( "PubkeyAuthentication" "SSH key login" "$PubkeyAuthentication" )
			MOTD+=( "PhoneAuthentication" "Google two-step authentication with one-time passcode" "$PhoneAuthentication" )

			Buttons="--no-cancel --ok-label "Save" --help-button --help-label Cancel"
			if [[ $PhoneAuthentication == "on" ]]; then
				Buttons="--cancel-label Generate-token --ok-label "Save" --help-button --help-label Cancel"
				ExtraDesc="\n\Z1Note:\Z0 Two-step verification token is identical for all users on the system.\n \n"
				LIST_CONST=11
				if [[ -f ~/.google_authenticator ]]; then
					Buttons="--cancel-label New-token --ok-label "Save" --help-button --help-label Cancel --extra-button --extra-label Show-token"
				fi
			fi

			LISTLENGTH="$((${#MOTD[@]}/3))"
			HEIGHT="$((LISTLENGTH + $LIST_CONST))"

			exec 3>&1
				selection=$(dialog --colors $Buttons --backtitle "$BACKTITLE" --title " Toggle sshd options " --clear --checklist \
				"\nChoose what you want to enable or disable:\n $ExtraDesc" $HEIGHT 0 $LISTLENGTH "${MOTD[@]}" 2>&1 1>&3)
				exit_status=$?
			exec 3>&-

			case $exit_status in
				$DIALOG_CANCEL | $DIALOG_ESC)
				break
				;;
				0)
					# read values, adjust config and restart service
					my_array=($selection)
					for((n=0;n<${#MOTD[@]};n++)); do
						if (( $(($n % 3 )) == 0 )); then

								# generic options if any
								if [[ " ${my_array[*]} " == *" ${MOTD[$n]} "* ]]; then
									sed -i "s/^#\?${MOTD[$n]}.*/${MOTD[$n]} yes/" /etc/ssh/sshd_config
									else
									sed -i "s/^#\?${MOTD[$n]}.*/${MOTD[$n]} no/" /etc/ssh/sshd_config
								fi

								if [[ $n -eq 0 ]]; then

									# phone
									if [[ " ${my_array[*]} " == *" PhoneAuthentication "* ]]; then
										MergeParameter="keyboard-interactive"
										sed -i "s/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/" /etc/ssh/sshd_config
										sed -i -n '/password updating/{p;:a;N;/@include common-password/!ba;s/.*\n/auth required pam_google_authenticator.so nullok\n/};p' /etc/pam.d/sshd
										else
										MergeParameter=""
										sed -i '/^auth required pam_google_authenticator.so nullok/ d' /etc/pam.d/sshd
										sed -i "s/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/" /etc/ssh/sshd_config
									fi

									# password
									if [[ " ${my_array[*]} " == *" PasswordAuthentication "* ]]; then
											MergeParameter="password keyboard-interactive"
											sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config
											sed -i "s/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/" /etc/ssh/sshd_config
											sed -i "s/^\#@include common-auth/\@include common-auth/" /etc/pam.d/sshd
										else
											sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
											#sed -i "s/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/" /etc/ssh/sshd_config
											sed -i "s/^\@include common-auth/\#@include common-auth/" /etc/pam.d/sshd
									fi

									# pubkey
									if [[ " ${my_array[*]} " == *" PubkeyAuthentication "* ]]; then
											MergeParameter="publickey keyboard-interactive "
											sed -i "s/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config
										else
											sed -i "s/^#\?PubkeyAuthentication.*/PubkeyAuthentication no/" /etc/ssh/sshd_config
									fi


									if [[ " ${my_array[*]} " == *" PubkeyAuthentication "* && " ${my_array[*]} " == *" PhoneAuthentication "* ]]; then
											MergeParameter="publickey,password publickey,keyboard-interactive"
											sed -i "s/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config
									fi


								fi
						fi
					done

					if [[ -z $MergeParameter ]]; then
							sed -i '/^AuthenticationMethods.*/ d' /etc/ssh/sshd_config
						else
							sed -i '/^AuthenticationMethods.*/ d' /etc/ssh/sshd_config
							sed -i -n '/and ChallengeResponseAuthentication to/{p;:a;N;/UsePAM yes/!ba;s/.*\n/AuthenticationMethods '"$MergeParameter"'\n/};p' /etc/ssh/sshd_config
					fi

					# reload sshd
					systemctl restart sshd.service
				;;
				3)
					display_qr_code
				;;
				1)
					dialog --colors --title " \Z1Warning\Z0 " --backtitle "$BACKTITLE" --yes-label "Generate" --no-label "No" --yesno "\nWhen you generate new token you have to scan it with your mobile device again.\n\nUnderstand?" 10 48
					if [[ $? = 0 ]]; then
						google-authenticator -t -d -f -r 3 -R 30 -W -q
						google_token_allusers
						display_qr_code
					fi
				;;
				esac
		done
	fi
	;;



	# Switch to daily builds
	#
	"Nightly" )

		if ! is_package_manager_running; then
			[[ -z $scripted ]] &&
			dialog --colors --title " \Z1Warning\Z0 " --backtitle "$BACKTITLE" --yes-label "Yes" \
			--no-label "No" --yesno \
			"\nYou are switching to an untested auto-build repository which might break your system.\n\nContinue?" 10 48

			if [[ $? = 0 || -n $scripted ]]; then
				sed -i 's/http:\/\/[^ ]*/http:\/\/beta.armbian.com/' /etc/apt/sources.list.d/armbian.list
				reload_bsp $branch
			fi
		fi
	;;


	# Switch to stable builds
	#
	"Stable" )

		if ! is_package_manager_running; then
			[[ -z $scripted ]] &&
			dialog --colors --title " \Z1Warning\Z0 " --backtitle "$BACKTITLE" --yes-label "Yes" \
			--no-label "No" --yesno \
			"\nYou are switching to a stable repository where you will receive future updates.\n\nContinue?" 9 44

			if [[ $? = 0 || -n $scripted ]]; then
				sed -i 's/http:\/\/[^ ]*/http:\/\/apt.armbian.com/' /etc/apt/sources.list.d/armbian.list
				reload_bsp $branch
			fi
		fi

	;;

	# Switch to alternative configurations
	#
	"DTB" )
		if ! is_package_manager_running; then
			aval_dtbs
			if [[ $exitstatus = 0 ]]; then
				BOX_LENGTH=$((${#TARGET_BOARD}+28));
				dialog --title "Switching board config" --backtitle "$BACKTITLE" --yes-label "Reboot" --no-label "Cancel" --yesno "\nReboot to $TARGET_BOARD settings?" 7 $BOX_LENGTH
				if [[ $? = 0 ]]; then
					sed -i "s/^fdt_file=.*/fdt_file=$TARGET_BOARD/" /boot/armbianEnv.txt 2> /dev/null && grep -q "fdt_file=$TARGET_BOARD" /boot/armbianEnv.txt 2> /dev/null || echo "fdt_file=$TARGET_BOARD" >> /boot/armbianEnv.txt
					[[ "$LINUXFAMILY" = odroidxu4 ]] && sed -i "s/^fdt_file/board_name/" /boot/armbianEnv.txt && sed -i "s/^BOARD_NAME.*/BOARD_NAME=\"Odroid ${TARGET_BOARD^^}\"/" /etc/armbian-release
					reboot;
				fi
			fi
		fi
	;;


	# Toggle virtual read-only root filesystem
	#
	"Overlayroot" )
		if ! is_package_manager_running; then
			if [[ -n $(mount | grep -w overlay | grep -v chromium) ]]; then
				dialog --title " Root overlay " --backtitle "$BACKTITLE" --yes-label "Disable" \
				--no-label "Cancel" \
				--yesno "\nYour system is already virtual read-only.\n\nDo you want to disable this feature and reboot?" 9 60
				if [[ $? = 0 ]]; then
					overlayroot-chroot sed -i "s/^overlayroot=.*/overlayroot=\"\"/" /etc/overlayroot.conf
					sed -i "s/^overlayroot_cfgdisk=.*/overlayroot_cfgdisk=\"disabled\"/" /etc/overlayroot.conf
					overlayroot-chroot rm /etc/update-motd.d/97-overlayroot
					reboot
				fi
			else
				debconf-apt-progress -- apt-get -o Dpkg::Options::="--force-confnew" -y install overlayroot
				debconf-apt-progress -- apt-get -f -yy install
				[[ ! -f /etc/overlayroot.conf ]] && cp /etc/overlayroot.conf.dpkg-new /etc/overlayroot.conf
				echo '#!/bin/bash' > /etc/update-motd.d/97-overlayroot
				echo 'if [ -n "$(mount | grep -w tmpfs-root)" ]; then \
				echo -e "[\e[0m \e[1mremember: your system is in virtual read only mode\e[0m ]\n";fi' >> /etc/update-motd.d/97-overlayroot
				chmod +x /etc/update-motd.d/97-overlayroot
				dialog --title "Root overlay" --backtitle "$BACKTITLE" --yes-label "Reboot" \
				--no-label "Cancel" --yesno "\nEnable virtual read-only root and reboot." 7 45
				if [[ $? = 0 ]]; then
					sed -i "s/^overlayroot=.*/overlayroot=\"tmpfs\"/" /etc/overlayroot.conf
					sed -i "s/^overlayroot_cfgdisk=.*/overlayroot_cfgdisk=\"enabled\"/" /etc/overlayroot.conf
					reboot
				fi
			fi
		fi
	;;



	"Dtc" )
		# Check if dtc command installed and install it if missing
		if ! command -v dtc 2> /dev/null
		then
			echo "device tree compiler (dtc) could not be found, ask for installing it"
			sudo apt install -y dtc
			if ! command -v dtc 2> /dev/null
			then
				echo "Failed to install device tree compiler (dtc), exiting!"
				exit
			fi
		else
			echo "dtc already installed!"
		fi


		## Start search for current dtb in use
		# read compatible field of the device tree
		comp=$(sed 's/\x0/,/g' /proc/device-tree/compatible)

		# split strings using ','
		OLDIFS=$IFS
		IFS=', ' read -r -a array <<< "${comp}"
		IFS=OLDIFS

		for element in "${array[@]}"
		do
			if [[ $element == *"rockchip"* ]]; then
				soc_manufacturer="rockchip"
				break
			elif [[ $element == *"amlogic"* ]]; then
				soc_manufacturer="amlogic"
				break
			elif [[ $element == *"allwinner"* ]]; then
				soc_manufacturer="allwinner"
				break
			elif [[ $element == *"freescale"* ]]; then
				soc_manufacturer="freescale"
				break
			elif [[ $element == *"nexell"* ]]; then
				soc_manufacturer="nexell"
				break
			elif [[ $element == *"marvell"* ]]; then
				soc_manufacturer="marvell"
				break
			elif [[ $element == *"samsung"* ]]; then
				soc_manufacturer="samsung"
				break
			fi
		done
		# thanks to compatible property convention: https://elinux.org/Device_Tree_Usage#Understanding_the_compatible_Property
		board_name="${array[1]}"

		echo "SoC manufacturer: ${soc_manufacturer}"
		echo "board name: ${board_name}"

		#  check dtbs folder
		if [[ -d "/boot/dtb/${soc_manufacturer}" ]]; then
			dtb_path="/boot/dtb/${soc_manufacturer}"
		else
			dtb_path="/boot/dtb"
		fi

		#~ echo "dtb path: ${dtb_path}"

		# search the used dtb in the dtbs folder
		for dtb in ${dtb_path}/*.dtb
		do
			if [[ $dtb == *"${board_name}"* ]]; then
				used_dtb=$dtb
				break
			fi
		done
		## End search for current dtb in use
		
		dtbfile="${used_dtb}"
		tmpdir="$(mktemp -d || exit 1)"
		chmod 700 "${tmpdir}"
		trap "rm -rf \"${tmpdir}\" ; exit 0" 0 1 2 3 15
		dtsfile="${tmpdir}/current.dts"
		dtc -I dtb "${dtbfile}" -O dts -o "${dtsfile}"

		dts_edit=1
		while [[ ${dts_edit} != 0 ]]; do
			# Edit dts
			oldtime=`stat -c %Y "${dtsfile}"`
			nano "${dtsfile}"

			# Check if modified
			if [[ `stat -c %Y "${dtsfile}"` -gt ${oldtime} ]] ; then
				# Yes: recompile to dtb
				dtc -I dts "${dtsfile}" -O dtb -o "${tmpdir}/current.dtb"
				# Check if errors at the compilation step
				if [ $? -eq 0 ]; then
					# No: ask for dtb replacement in boot folder
					read -p "Do you want to replace active dtb with current modification(s)? (y/n)" yn
					case $yn in
						[Yy]* )
							# Keep a copy of original file
							sudo cp -p "${dtbfile}" "${dtbfile}.bak";
							# Replace with current file
							sudo cat "${tmpdir}/current.dtb" >"${dtbfile}";
							# Ask for immediate reboot
							read -p "Do you want to reboot to check modification(s) effect? (y/n)" ynr
							case $ynr in
								[Yy]* ) sudo reboot;;
								* ) break;;
							esac
							;;
						* ) 
							echo "Modifications cancelled!"
							;;
					esac
				else
					echo "Wrong device tree modifications!"
				fi
			fi
			read -p "Do you want to edit the device tree again? (y/n)" yne
			case $yne in
				[Yy]* )
					dts_edit=1
					;;
				* )
					dts_edit=0
					;;
			esac
		done
		echo "Device tree modifications finished!"
	;;

	"Mirrors")

		# Default automated mirror
		url="http://apt.armbian.com"
		LIST=( "0" "Automated" )
		mirrors=( "${url}" )

		# Mirrors for each region
		for region in $(wget -qO- "${url}/regions" | jq -r '.[]' | sort | grep -v default); do
			LIST+=( "${#mirrors[@]}" "Region ${region}" )
			mirrors+=( "${url}/region/${region}/" )
		done

		# Individual mirrors
		for mirror in $(wget -qO- "${url}/mirrors" | jq -r '.[] | .[]' | sort | uniq); do
			LIST+=( "${#mirrors[@]}" "${mirror}" )
			mirrors+=( "${mirror}" )
		done

		exec 3>&1
		selection=$(dialog --colors --backtitle "${BACKTITLE}" --title " Select APT mirror " --clear --menu "Select mirror" 0 0 10 "${LIST[@]}" 2>&1 1>&3)
		exit_status=$?
		exec 3>&-
		clear

		if [ $exit_status -eq 0 ]; then
			# Reconfigure apt
			codename=$(lsb_release -sc)
			mirror=${mirrors[$selection]}
			echo "deb ${mirror} ${codename} main ${codename}-utils ${codename}-desktop" > /etc/apt/sources.list.d/armbian.list
			apt-get update
		fi
		;;

	esac



[[ -n $scripted ]] && exit
}
