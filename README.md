# Armbian configuration utility

Utility for configuring your board, adjusting services and installing applications. It comes with Armbian by default. 

Login as root and type:

	armbian-config

![](images/animated.gif)

- **system**
	- change timezone, languages and hostname
	- adjust SSH daemon features
	- update board firmware
	- toggle desktop, RDP and login manager (desktop builds)
	- adjusting the display resolution (some boards)
	- toggle running servives (stock Debian utility)
	- enabling read only root filesystem (Ubuntu)
	- install kernel headers
- **networking**
	- select dynamic or static IP address
	- hotspot management. Automatic detection of: nl80211, realtek, 802.11n, 802.11a and 802.11ac 
	- connect to wireless 
	- pair and connect Bluetooth devices
	- edit IFUPDOWN interfaces
- **armbian**
	- install to SATA, eMMC, NAND or USB
	- freeze and unfreeze kernel and BSP upgrades
	- edit boot environment, welcome screen items
	- reconfigure board settings with DT overlays or FEX (Allwinner legacy)
	- switching between avaliable kernels and nightly builds
- **software**
	- softy
		- [TV headend](https://tvheadend.org/) *(IPTV server)*
		- [Syncthing](https://syncthing.net/) *(personal cloud)*
		- [SoftEther VPN server](https://www.softether.org/) *(VPN server)*
		- [Transmission](https://transmissionbt.com/) *(torrent server)*
		- [ISPConfig](https://www.ispconfig.org/) *(WEB & MAIL server)*
		- [Openmediavault NAS](http://www.openmediavault.org/) *(NAS server)*
		- [PI hole](https://pi-hole.net) *(ad blocker)*
		- [MiniDLNA](http://minidlna.sourceforge.net/) *(media sharing)*
	- monitoring tools	
	- create diagnostics report	
- **help**
	- Links to documentation, support and sources

**Running this utility on 3rd party Debian based distributions**

	sudo apt-get -y install git
	cd ~
	git clone https://github.com/armbian/config
	cd config
	bash debian-config