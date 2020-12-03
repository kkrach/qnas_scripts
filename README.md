# QNAS Scripts

Scripts for the QNAP NAS

## USB Support

At the time writing this script (end 2020) there were no supported WIFI dongles
for TBS-453DX. Thus I bought the some good-looking device, but this was not
supported.

So I checked the linux and found two resources:
 - a whitelist of QNAP (thus all devices listed there are supported)
 - parsing the kernel modules would show the USB devices for which a driver exists


## USB Whitelisting

The script `./qnas_get_usb_whitelist.sh` lists all device, which are whitelisted
by QNAP. This is done in the start-script at /etc/init.d/usb\_device\_check.sh.

In other words: When a device of this list is connected, the associated driver is
loaded. This driver may work - but may also fail (due to hardware or software
reasons. BUT - for devices which are not in this list, for sure no driver is loaded
and for sure they will not work!
