# QNAS Scripts

Scripts for the QNAP NAS

## USB Support

At the time writing this script (end 2020) there were no supported WIFI dongles
for TBS-453DX. Thus I bought some good-looking device, but this did not work.

So I analyzed the software of the NAS and found two resources:
 - a whitelist of QTS (thus only devices listed there could work)
 - parsing the kernel modules would show the USB devices for which a driver exists

The devices of the whitelist shall be a subset of the devices which have a driver.


## USB Whitelisting

The script `./qnas_get_usb_whitelist.sh` lists all device, which are whitelisted
by QNAP. This is done in the start-script at `/etc/init.d/usb\_device\_check.sh`.

In other words: When a device of this list is connected, the associated driver is
loaded. This driver may work - but may also fail (due to hardware or software
reasons). BUT - for devices which are not in this list, for sure no driver is loaded
and for sure they will not work!
