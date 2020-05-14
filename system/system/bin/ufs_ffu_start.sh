#!/system/bin/sh
#
# Copyright (c) 2013-2019, Motorola LLC  All rights reserved.
#

SCRIPT=${0#/system/bin/}
MODEL=`cat /sys/block/sda/device/model | tr -d ' '`
REV=`cat /sys/block/sda/device/rev`

sync
if [ "$MODEL" == "KLUBG4G1CE-B0B1" -o "$MODEL" == "KLUCG4J1CB-B0B1" ] ; then
	UFS_SIZE="32G"
	VENDOR="SAMSUNG"
elif [ "$MODEL" == "KLUCG4J1ED-B0C1" ] ; then
	UFS_SIZE="64G"
	VENDOR="SAMSUNG"
elif [ "$MODEL" == "KLUDG8V1EE-B0C1" ] ; then
	UFS_SIZE="128G"
	VENDOR="SAMSUNG"
elif [ "$MODEL" == "KM5V7001DM-B621" ] ; then
	UFS_SIZE="128G"
	VENDOR="SAMSUNG"
elif [ "$MODEL" == "KM2V7001CM-B706" ] ; then
	UFS_SIZE="128G"
	VENDOR="SAMSUNG"
	if [ "$REV" -eq "0900" ] ; then
		/product/bin/sg_write_buffer -v -m dmc_offs_defer -I /vendor/firmware/$VENDOR-$MODEL-$UFS_SIZE-09-TO-08.fw /dev/block/sda
	fi
elif [ "$MODEL" == "SDINDDC4-128G" ] ; then
	UFS_SIZE="128G"
	VENDOR="WDC"
elif [ "$MODEL" == "KLUEG8UHDB-C2D1" ] ; then
	UFS_SIZE="256G"
	VENDOR="SAMSUNG"
elif [ "$MODEL" == "KM5V8001DM-B622" ] ; then
	UFS_SIZE="128G"
	VENDOR="SAMSUNG"
elif [ "$MODEL" == "KM2V8001CM-B707" ] ; then
	UFS_SIZE="128G"
	VENDOR="SAMSUNG"
fi

FW_FILE=/vendor/etc/motorola/firmware/$VENDOR-$MODEL-$UFS_SIZE.fw

# Flash the firmware
echo "Starting upgrade..." > /dev/kmsg
echo $FW_FILE > /dev/kmsg
if [ "$VENDOR" == "WDC" ] ; then
	/product/bin/ufs_wd  ffu -t 0 -p ./dev/block/sda -w $FW_FILE
else
	/product/bin/sg_write_buffer -v -m dmc_offs_defer -I $FW_FILE  /dev/block/sda
fi

if [ $? -eq "0" ];then
	echo "UFS $FW_FILE updated done, reboot now !" > /dev/kmsg
	sleep 1
	echo b >/proc/sysrq-trigger
else
	echo "Error: fails to send $FW_FILE " > /dev/kmsg
fi
exit
