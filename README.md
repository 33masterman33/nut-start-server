# nut-start-server
In this project I will be using a headless Raspberry Pi Zero W that I had lying around to act as a nut server to shut down and start up servers based on current UPS battery level

- [nut-start-server](#nut-start-server)
  * [Setup Headless Pi](#setup-headless-pi)
      - [balenaEtcher](#balenaetcher)
      - [Raspberry Pi Imager](#raspberry-pi-imager)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>


## Setup Headless Pi
Install your preferred img writer. I will be using balenaEtcher although the offical raspberry pi one might be easier. A standard install works just as well headless is just more convient for me. If you don't want headless you can still follow along and just plug in a montior and keyboard.
### balenaEtcher
1. [Download Etcher](https://www.balena.io/etcher/)
2. [Download whatever version of Raspberry Pi OS thats compatible](https://www.raspberrypi.com/software/operating-systems/)
3. Connect your sd card
4. Open Etcher and write the extracted os image to your sd card
5. If its not already mount the boot partition on the sd card
6. Create an empty file named `ssh` to enable ssh on first boot for headless on the root of the boot partition
7. If using wifi instead of ethernet create a file named `wpa_supplicant.conf` and add the following changing {NETWORK-SSID} and {NETWORK-PASSWORD}
```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="{NETWORK-SSID}"
    psk="{NETWORK-PASSWORD}"
}
```
7. Create a file name `userconf` with the following substituting {USERNAME} with `pi` or whatever you want your user to be.
```
{USERNAME}:{FORLATER}
```
7. Open up terminal on an existing linux machine and run the following command `openssl passwd -6`. After running the command type the password you want for your user. This will generate an excrypted password needed to do headless setups on modern PiOS.
8. Copy the entire output of the command and paste it into where {FORLATER} is
9. Eject the SD Card

### Raspberry Pi Imager
1. [Download the Imager](https://www.raspberrypi.com/software/)
2. Connect your sd card and open Pi Imager
3. Choose your preferred os
4. Click on the settings icon in the bottom right
5. Set hostname if desired
6. Check enable ssh, set the username and password, and configure wifi if needed
7. Save the settings and write the image to the sd card
8. Eject the sd card

### Configure PI
1. Log into your router and see what ipaddress the pi got assigned. This can be skipped if doing a headed setup.
2. SSH into the Pi or open terminal if headed
3. Run `sudo raspi-config` to update hostname and other settings such as VNC if desired.
4. Update the OS by running the following. This will install all availble updates and auto approve them
```
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt dist-upgrade -y
```

### Install NUT Server
I am doing this on a pi so I will be using apt. Substitute the command if using another os.
1. Install NUT with the following command `sudo apt install nut`
2. Run `nut-scanner` it should output all the UPSs connected to your system in the form nut wants them in. This is what mine looks like 
```
[nutdev1]
	driver = "usbhid-ups"
	port = "auto"
	vendorid = "051D"
	productid = "0002"
	bus = "001"
```
3. I will be using nano as a text editor but you can choose another. Open the ups config file with `sudo nano /etc/nut/ups.conf`
4. At the bottom of the file paste the output of nut scanner. We are going to tweak it a bit by changing the name from nutdev1 to someone easier to recognize. We are going to specify the poll inverval as shown. I am also going to set the low battery percentage and run time at 30% and 20 minutes becasue the default of 10% and 2 mins is too low for me. Runtime is counted in seconds
```
[APC750]
        driver = "usbhid-ups"
        port = "auto"
        vendorid = "051D"
        productid = "0002"
        bus = "001"
        pollinterval = 1
        override.battery.charge.low = 30
        override.battery.runtime.low = 1200
```
5. Save and exit ups.conf and open upsd.conf with `sudo nano /etc/nut/upsd.conf`. At the bottom of the file we will set NUT to listen on local host and all interfaces
``` 
LISTEN 127.0.0.1 3493
LISTEN 0.0.0.0 3493
```
6. NUT stores user info as clear text so we can use these commands to restrict access to root/sudo only
```
chown root.root /etc/nut/upsd.users
chmod 600 /etc/nut/upsd.users
```
7. Now we need to edit the user file to create our users. `sudo nano /etc/nut/upsd.users` the passwords can be changed but the rest should be the same
```
[mon_master]
    password = monmaster
    actions = set
    instcmds = ALL
    upsmon master
[mon_slave]
    password = monslave
    upsmon slave
```
8. Now we will tell NUT what UPSs to monitor `sudo nano /etc/nut/upsmon.conf` APC750 is the name of my UPS. 1 is the number of UPSs you have powering your server. Mon_master is the username and monmaster is the password. 
```
MONITOR APC750@localhost 1 mon_master monmaster master
```
9. Since this file also has clear text passwords we will change the permissions again.
```
chown root.root /etc/nut/upsmon.conf
chmod 600 /etc/nut/upsmon.conf
```
10. Now we have to tell NUT to act as a server `sudo nano /etc/nut/nut.conf` We need the MDOE set to netserver
```
MODE=netserver
```
11. If using iDRAC or another LOM for power control attach your PIs ssh key to an account that has access to power control. The script supports iDRAC and wakeonlan only out of the box as that is the only things my systems supports.
12. Download the script from the github repo and ensure it is executable with `sudo chmod +x ./script.sh`
13. If using iDRAC update the hostname and idrac username in the variables section of the script and set wakeonlan to 0. If using wakeonlan set the hostname and mac address.
14. We need to edit upsmon again to add the condition to execute the script. This can be done by opening up upsmon with `sudo nano /etc/nut/upsmon.conf` and adding
```
NOTIFYFLAG ONLINE EXEC+WALL+SYSLOG
NOTFIFYCMD /home/pi/script.sh #substitute with the path to your script.
```
15. While the file is still open comment out the shutdown command. Because the server is running off a low power easy to deploy Pi I don't want it shutting off and I want it to remain on to reboot my server for as long as possible. I added the # to comment it out
```
# SHUTDOWNCMD "/sbin/shutdown -h +0"
```
16. Reload the upsmon config file with `upsmon -c reload`
### Setup NUT Client
1. Install NUT with `sudo apt-get install nut` 
2. To configure NUT as a client inside of /etc/nut/nut.conf paste
```
MODE=netclient
```
3. Now we need to tell it where to find the UPS. To do this open /etc/nut/upsmon.conf and type while using your Pi's IP address
```
MONITOR APC750@<ipaddress> 1 mon_slave monslave slave
```
4. Restart NUT with
```
service nut-client restart
```
### Conclusion
You should now have a working nut server. I haven't had much time to test so far but this configuration has been working for me. My Pi Zero W and usb hub only draw 1.5 W making this the ideal autoboot solution!
