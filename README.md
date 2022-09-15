# nut-start-server
In this project I will be using a headless Raspberry Pi Zero W that I had lying around to act as a nut server to shut down and start up servers based on current UPS battery level

## Setup Headless Pi
1. Install your preferred img writer. I will be using balenaEtcher although the offical raspberry pi one might be easier.
#### balenaEtcher
1. [Download Etcher](https://www.balena.io/etcher/)
2. [Download whatever version of Raspberry Pi OS thats compatible](https://www.raspberrypi.com/software/operating-systems/)
3. Open Etcher and write the extracted os image to your sd card
4. If its not already mount the boot partition on the sd card
5. Create an empty file named `ssh` to enable ssh on first boot for headless on the root of the boot partition
6. If using wifi instead of ethernet create a file named `wpa_supplicant.conf` and add the following changing {NETWORK-SSID} and {NETWORK-PASSWORD}
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
