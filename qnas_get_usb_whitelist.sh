#!/bin/bash -ue
#
# This script extracts the whitelisted USB devices from the QNAP nas 
#
#

if [ $# -ne 3 ] ; then
	echo "Usage: $0 USER DEVICE OUTFILE"
	echo
	echo "USER    e.g. 'admin'"
	echo "DEVICE  e.g. '192.168.178.122'"
	echo "OUTFILE e.g. 'qnap_usb_whitelist.txt'"
	echo
	echo "The tmp directory can be deleted at any time safely."
	exit 1
fi

QUSER=$1
QDEVICE=$2
OUTFILE=$3

# Ensure that we re-create the file after a week
TOKEN=$(date '+%y%m%d_%U')

# Resources
USB_IDS_ADD=./resources/usb_ids_additional.txt
# Temporary files
USB_IDS_ORIG=./tmp/qnas_${TOKEN}_usb_ids_original.txt
USB_IDS=./tmp/qnas_${TOKEN}_usb_ids.txt
QNAS_IDS=./tmp/qnas_${TOKEN}_ids.txt
QETCSCRIPT=./tmp/qnas_${TOKEN}_etc_init.d_usb_device_check.sh
QUSBIDS=./tmp/qnas_${TOKEN}_usbids.txt
QUSBIDS_SORTED=./tmp/qnas_${TOKEN}_usbids_sorted.txt
QRESOLVED=./tmp/qnas_${TOKEN}_resolved_ids.txt
QSORTED=./tmp/qnas_${TOKEN}_sorted_ids.txt

if [ ! -e ./tmp ] ; then
	echo -n "Creating local tmp Directory..."
	mkdir tmp
	echo " created."
fi

#
# Download and reformat list of USB IDs
#
if [ ! -e $USB_IDS ] ; then
	echo "Downloading names for USB-IDs..."
	if [ ! -e $USB_IDS_ORIG ] ; then
		curl http://www.linux-usb.org/usb.ids | sed 's/^\t/>/' | grep '^>\?[0-9a-f]\{4\}' > $USB_IDS_ORIG
	fi
	while read -r LINE ; do
		if [ "${LINE:0:1}" != ">" ] ; then
			LAST_MID=${LINE:0:4}
			LAST_MNAME=${LINE:5}
			echo $LINE >> $USB_IDS
		else
			echo ${LAST_MID}:${LINE:1:5} ${LAST_MNAME} ${LINE:6} >> $USB_IDS
		fi
	done < $USB_IDS_ORIG
fi

#
# Download start-script from NAS
#
if [ ! -e $QETCSCRIPT ] ; then
	echo "Downloading startscript..."
	ssh $QUSER@$QDEVICE "cat /etc/init.d/usb_device_check.sh" > $QETCSCRIPT
fi

#
# Get USBIDs from start-script
#
echo -n "Reading UDB-IDs from start-script.."
rm -f $QUSBIDS
for DRIVER in $(cat $QETCSCRIPT | grep -o "^[^_ ]*_Vid" | sed "s/_Vid//") ; do
	VIDS=$(grep "^${DRIVER}_Vid" $QETCSCRIPT | sed "s/.*_Vid=(\|)//g")
	PIDS=$(grep "^${DRIVER}_Pid" $QETCSCRIPT | sed "s/.*_Pid=(\|)//g")

	for VID in $VIDS ; do
		for PID in $PIDS ; do
			echo "$VID:$PID $DRIVER" >> $QUSBIDS
		done
	done
done
cat $QUSBIDS | sort | uniq > $QUSBIDS_SORTED
echo " $(wc -l $QUSBIDS_SORTED | grep -o "^[0-9]*") lines read."

#
# Match USB-ID list from QNas
#
echo -n "Resolving names for USB-IDs..."
rm -rf $QRESOLVED
while read -r LINE ; do
	USBVID=${LINE:0:4}
	USBPID=${LINE:5:4}
	USBID="$USBVID:$USBPID"
	DRIVER=${LINE:10}

	if grep -q "^$USBID" $USB_IDS ; then
		echo "$(grep "^$USBID" $USB_IDS) (from $DRIVER)" >> $QRESOLVED
	elif [ -e $USB_IDS_ADD ] && grep -q "^$USBID" $USB_IDS_ADD ; then
		echo "$(grep "^$USBID" $USB_IDS_ADD) (from $DRIVER)" >> $QRESOLVED
	elif grep -q "^$USBVID " $USB_IDS ; then
		echo "$USBID $(grep "^$USBVID " $USB_IDS | sed 's/.... //') Devicename Unknown (from $DRIVER)" >> $QRESOLVED
	else
		echo "$USBID Vendor and device unknown (from $DRIVER)" >> $QRESOLVED
	fi
done < $QUSBIDS_SORTED
echo " $(wc -l $QRESOLVED | grep -o "^[0-9]*") lines resolved."
echo -n "Sorting resolved names..."
cat $QRESOLVED | sort | uniq > $QSORTED
echo " $(wc -l $QSORTED | grep -o "^[0-9]*") lines sorted."

#
# Creating output file
#
rm -rf $OUTFILE
echo "#" >> $OUTFILE
echo "# White-listed USB Devices of QNAP NAS $QDEVICE" >> $OUTFILE
echo "#" >> $OUTFILE
echo "# Created on $(date '+%y-%m-%d %H:%M')" >> $OUTFILE
echo "#" >> $OUTFILE
echo "" >> $OUTFILE
echo "# Resolved USB-IDs:" >> $OUTFILE
cat $QSORTED | grep -vi "unknown" >> $OUTFILE
echo "" >> $OUTFILE
echo "# Unresolved USB-IDs:" >> $OUTFILE
cat $QSORTED | grep  -i "unknown" >> $OUTFILE

echo
echo "Written output to $OUTFILE"

