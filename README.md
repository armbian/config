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
	- select dedicated DTB (Solidrun imx6 boards)
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
		- [Transmission](https://transmissionbt.com/) *(torrent server)*
		- [ISPConfig](https://www.ispconfig.org/) *(WEB & MAIL server)*
		- [Openmediavault NAS](http://www.openmediavault.org/) *(NAS server)*
		- [PI hole](https://pi-hole.net) *(ad blocker)*
		- [UrBackup](https://www.urbackup.org/) *(client/server backup system)*
		- [Webmin](http://www.webmin.com) *(Web-based interface for system administration)*
		- [MiniDLNA](http://minidlna.sourceforge.net/) *(media sharing)*
	- monitoring tools
	- create diagnostics report
	- install kernel headers
	- remove build-essentials
	- install RDP service (desktop builds)
- **help**
	- Links to documentation, support and sources

**Running this utility on 3rd party Debian based distributions**

	# Install dependencies
	apt install git bc expect rcconf dialog network-manager sunxi-tools iptables resolvconf debconf-utils unzip build-essential html2text apt-transport-https html2text dirmngr software-properties-common

	git clone https://github.com/armbian/config
	cd config
	bash debian-config

