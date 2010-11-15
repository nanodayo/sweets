#!/bin/bash

tftp_dir=""
plc=`hostname`
kernel=pl_kernel
bootcd=bootcd

if [ $1 ];
then
	conf=$1
else
	echo "Usage:$0 <plnode_conf> (<plchost> <tftp_dir_path>)"
	exit
fi

if [ $2 ];
then
	plc=$2
fi

if [ $3 ];
then
	tftp_dir=$3
fi

cdir=`pwd`
mkdir -p /tmp/$1/usr/
cp $1 /tmp/$1/usr/plnode.txt
cd /tmp/$1
find . -print | cpio -o --file=../$1.initrd_new --format=newc
cd ../
gzip -c9 $1.initrd_new > $cdir/$1.img

cd $cdir

echo "default planet
prompt 0
label planet
	kernel $tftp_dir$kernel
	APPEND ramdisk_size=100589 initrd=$tftp_dir$bootcd.img,$tftp_dir$plc.img,$tftp_dir$1.img root=/dev/ram0 rw
" > $1_X_$plc.pxeconf
