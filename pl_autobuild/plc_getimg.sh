#!/bin/bash

#tftpserver = 

mount -t iso9660 -o loop /plc/data/var/www/html/download-planetlab-i386/PlanetLab\ Test-BootCD-4.2.iso /mnt/
cp /mnt/overlay.img `hostname`.img
cp /mnt/bootcd.img .
cp /mnt/kernel pl_kernel

# tftp 
