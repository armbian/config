Debian-micro-home-server
========================

Samba, TV headend, Transmission, BitTorrent Sync, SoftEther VPN server, CUPS, scanner + buttons + OCR, Postfix, Dovecot, Apache2, PHP, Mysql + phpMyAdmin install, ISPConfig 3

Tips:
- disable Ramlog (service ramlog disable;reboot) before running install. Ramlog is default in my Cubieboard Debian.
- set fixed ip address

Help:
Most of installation is based on this:
http://www.howtoforge.com/perfect-server-debian-wheezy-nginx-bind-dovecot-ispconfig-3

Installation steps
------------------

```shell
sudo apt-get -y install git
cd ~
git clone https://github.com/igorpecovnik/Debian-micro-home-server
chmod +x ./Debian-micro-home-server/install.sh
cd ./Debian-micro-home-server
sudo ./install.sh
```
