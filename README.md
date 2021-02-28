NOTICE: We are refactoring this tool. [Your input & help is more then welcome!](https://forum.armbian.com/topic/16933-armbian-config-rfc-ideas)

# Armbian configuration utility

Utility for configuring your board, adjusting services and installing applications.
It comes with Armbian by default.

Login as root and type:

	armbian-config

![](images/animated.gif)

- **system**
	- install to SATA, eMMC, NAND or USB
	- freeze and unfreeze kernel and BSP upgrades
	- switching between available kernels and nightly builds
	- edit boot environment
	- reconfigure board settings with DT overlays or FEX (Allwinner legacy)
	- select dedicated DTB (Solidrun i.MX6 and Odroid XU4/HC1/HC2 boards)
	- adjust SSH daemon features
	- 3G/4G LTE modem management
	- run apt update and upgrade
	- toggle BASH/ZSH with [Oh My ZSH](https://ohmyz.sh/) and [tmux](https://en.wikipedia.org/wiki/Tmux)
	- toggle desktop and login manager (desktop builds)
	- adjusting the display resolution (some boards)
	- enabling read only root filesystem (Ubuntu)
- **network**
	- select dynamic or static IP address
	- hotspot management. Automatic detection of: nl80211, realtek, 802.11n, 802.11a and 802.11ac
	- iperf3. Toggle bandwidth measuring server
	- connect to wireless
	- install IR support
	- install support, pair and connect Bluetooth devices
	- edit IFUPDOWN interfaces
- **personal**
	- change timezone, languages and hostname
	- select welcome screen items
- **software**
	- softy
		- [TV headend](https://tvheadend.org/) *(IPTV server)*
		- [Syncthing](https://syncthing.net/) *(personal cloud)*
		- [SoftEther VPN server](https://www.softether.org/) *(VPN server)*
		- [Plex](https://www.plex.tv/) *(Plex media server)*
		- [Emby](https://emby.media/) *(Emby media server)*
		- [Radarr](https://radarr.video/) *(Movie downloading server)*
		- [Sonarr](https://sonarr.tv/) *(TV shows downloading server)*
		- [Transmission](https://transmissionbt.com/) *(torrent server)*
		- [ISPConfig](https://www.ispconfig.org/) *(WEB & MAIL server)*
		- [NCP](https://nextcloudpi.com) *(Nextcloud personal cloud)*
		- [Openmediavault NAS](http://www.openmediavault.org/) *(NAS server)*
		- [OpenHab2](https://www.openhab.org) *(Smarthome suite)*
		- [Home Assistant](https://www.home-assistant.io/hassio/) *(Smarthome suite within Docker)*
		- [PI hole](https://pi-hole.net) *(ad blocker)*
		- [UrBackup](https://www.urbackup.org/) *(client/server backup system)*
		- [Docker](https://www.docker.com) *(Docker CE engine)*
		- [Mayan EDMS](https://www.mayan-edms.com/) *(Document management system within Docker)*
		- [MiniDLNA](http://minidlna.sourceforge.net/) *(media sharing)*
	- monitoring tools
	- create diagnostics report
	- toggle kernel headers, RDP service, Thunderbird and LibreOffice (desktop builds)
- **help**
	- Links to documentation, support and sources

**Run this utility on 3rd party Debian based distributions**

	echo "deb [arch=arm64] http://apt.armbian.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/armbian.list
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 9F0E78D5
	apt update
	apt install armbian-config

Development version:

	# Install dependencies
	apt install git iperf3 psmisc curl bc expect dialog network-manager sunxi-tools \
	debconf-utils unzip dirmngr software-properties-common psmisc

	git clone https://github.com/armbian/config
	cd config
	bash debian-config

# Software testings

|Application name|Buster|Stretch*|Bionic*|Test install|
|:--|:--:|:--:|:--:|--:|
|TV headend (IPTV server)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|15.11.2020|
|Syncthing (personal cloud)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|15.11.2020|
|SoftEther VPN server (VPN server)|:grey_question:|:heavy_check_mark:|:heavy_check_mark:|09.03.2019|
|Plex (Plex media server)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|15.07.2019|
|Emby (Emby server)|:heavy_check_mark:|:heavy_check_mark:|:grey_question:|24.07.2019|
|Radarr (Movie downloading server)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|10.06.2019|
|Sonarr (TV shows downloading server)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|10.06.2019|
|Transmission (torrent server)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|10.06.2019|
|ISPConfig (WEB, SMTP, POP, IMAP, FTPD, MYSQL server)|:grey_question:|:heavy_check_mark:|:heavy_check_mark:|29.09.2018|
|NCP (Nextcloud personal cloud)|:grey_question:|:heavy_check_mark:|n/a|19.05.2019|
|OpenMediaVault NAS (NAS server)|:heavy_check_mark:|:heavy_check_mark:|n/a|24.07.2019|
|OpenHAB2 (Smarthome suite)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|17.12.2019|
|Home Assistant (Smarthome suite within Docker)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|09.03.2019|
|PI hole (ad blocker)|:grey_question:|:heavy_check_mark:|:heavy_check_mark:|09.03.2019|
|UrBackup (client/server backup system)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|10.06.2019|
|Docker (Docker CE engine)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|10.06.2019|
|Mayan EDMS (Document management system within Docker)|:grey_question:|:heavy_check_mark:|:heavy_check_mark:|29.09.2018|
|MiniDLNA (Media sharing)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|10.06.2019|

\* no longer supported
