#!/bin/bash

#variables
hostname='192.168.0.75'
macAddress='C1:F0:EF:B5:D9:45' #optional
wakeOnLan=1 #0 turns wakeonlan off. 1 turns it on.
user='power' #iDRAC user
bootCharge='50' #Charge of the UPS before it will start turning on servers



currentCharge=$(upsc APCsmall@localhost 2>&1 | grep 'battery.charge:' | grep -Eo '[0-9]{1,}')

if [ $currentCharge -gt $bootCharge ]
then
  if [ $wakeOnLan -eq 1 ]
  then
    if [ ping -c 1 $hostname &> /dev/null ]
      then
	if ! wakeonlan -v &> /dev/null
	then
	  sudo apt-get install wakeonlan
	fi
        wakeonlan $macAddress
    fi
  else
    if [[ $(ssh $user@$hostname 'serveraction powerstatus') == *"OFF"* ]]
    then
      ssh $user@$hostname 'serveraction powerup'
    fi
  fi
fi
