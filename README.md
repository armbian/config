# Armbian configuration utility

Utility for configuring your board, adjusting services and installing applications. It comes with Armbian by default.

Login as root and type:

	armbian-config

![](images/animated.gif)

- **system**
	- install to SATA, eMMC, NAND or USB
	- freeze and unfreeze kernel and BSP upgrades
	- switching between avaliable kernels and nightly builds
	- edit boot environment
	- reconfigure board settings with DT overlays or FEX (Allwinner legacy)
	- select dedicated DTB (Solidrun imx6 and Odroid XU4/HC1/HC2 boards)
	- adjust SSH daemon features
	- run apt update and upgrade
	- toggle desktop and login manager (desktop builds)
	- adjusting the display resolution (some boards)
	- toggle running servives (stock Debian utility)
	- enabling read only root filesystem (Ubuntu)
- **network**
	- select dynamic or static IP address
	- hotspot management. Automatic detection of: nl80211, realtek, 802.11n, 802.11a and 802.11ac
	- iperf3. Toogle bandwidth measuring server
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
		- [ExaGear desktop](https://eltechs.com/product/exagear-desktop) *(x86 emulator)*
		- [Plex](https://www.plex.tv/) *(Plex media server)*
		- [Radarr](https://radarr.video/) *(Movie downloading server)*
		- [Sonarr](https://sonarr.tv/) *(TV shows downloading server)*
		- [Transmission](https://transmissionbt.com/) *(torrent server)*
		- [ISPConfig](https://www.ispconfig.org/) *(WEB & MAIL server)*
		- [NCP](https://ownyourbits.com/nextcloudplus/) *(Nextcloud personal cloud)*
		- [Openmediavault NAS](http://www.openmediavault.org/) *(NAS server)*
		- [PI hole](https://pi-hole.net) *(ad blocker)*
		- [UrBackup](https://www.urbackup.org/) *(client/server backup system)*
		- [MiniDLNA](http://minidlna.sourceforge.net/) *(media sharing)*
	- monitoring tools
	- create diagnostics report
	- toggle kernel headers, RDP service, Thunderbird and Libreoffice (desktop builds)
- **help**
	- Links to documentation, support and sources

**Running this utility on 3rd party Debian based distributions**

	# Install dependencies
	apt install git iperf3 qrencode psmisc curl bc expect dialog network-manager sunxi-tools iptables \
	resolvconf debconf-utils unzip build-essential html2text apt-transport-https html2text dirmngr \
	software-properties-common libpam-google-authenticator qrencode

	git clone https://github.com/armbian/config
	cd config
	bash debian-config

