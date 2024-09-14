#!/bin/sh

sudo apt install git bc bison flex libssl-dev make libc6-dev libncurses5-dev \
         crossbuild-essential-arm64 gawk texinfo

#Creo las carpetas donde se van a copiar los archivos para copiar
#a cada respectiva particion
mkdir -p $(pwd)/RPI/part/bootfs
mkdir -p $(pwd)/RPI/part/rootfs/usr
mkdir -p $(pwd)/RPI/part/rootfs/dev
mkdir -p $(pwd)/RPI/part/rootfs/tmp
mkdir -p $(pwd)/RPI/part/rootfs/proc
mkdir -p $(pwd)/RPI/part/rootfs/sys
mkdir -p $(pwd)/RPI/part/rootfs/root
mkdir -p $(pwd)/RPI/part/rootfs/mnt
mkdir -p $(pwd)/RPI/part/rootfs/etc/init.d
