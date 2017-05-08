# Armbian config

Utility for configuring your board and install various services.

It comes with Armbian (from 5.27) by default. Login as super user and type:

	armbian-config

![](https://www.armbian.com/wp-content/uploads/2017/05/confsoft.png)

**Configuration**

- wireless network connect,
- AP (hotspot) in bridged or NAT mode,
- freeze and unfreeze kernel and BSP upgrades,
- edit boot environment, network, FEX, welcome screen items,
- switching between avaliable kernels and nightly builds,
- enabling read only root filesystem (Ubuntu only),
- set display resolution (H3 boards with legacy kernel),

**Installation**

- [TV headend](https://tvheadend.org/) *(IPTV server)*
- [Syncthing](https://syncthing.net/) *(personal cloud)*
- [SoftEther VPN server](https://www.softether.org/) *(VPN server)*
- [Transmission](https://transmissionbt.com/) *(torrent server)*
- [ISPConfig](https://www.ispconfig.org/) *(WEB & MAIL server)*
- [Openmediavault NAS](http://www.openmediavault.org/) *(NAS server)*
- [PI hole](https://pi-hole.net) *(ad blocker)*
- [MiniDLNA](http://minidlna.sourceforge.net/) *(media sharing)*


[Project realisation example](http://www.igorpecovnik.com/2013/12/10/micro-home-server/)


----------

**Installation for regular Ubuntu or Debian based distributions**

	sudo apt-get -y install git
	cd ~
	git clone https://github.com/igorpecovnik/Debian-micro-home-server
	cd Debian-micro-home-server
	sudo ./debian-config
