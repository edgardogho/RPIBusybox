#!/bin/sh

#Instalamos los binarios en el bootfs
sudo cp $(pwd)/binarios/bootfs/* $(pwd)/RPI/part/bootfs/
sudo cp $(pwd)/binarios/rootfs/group $(pwd)/RPI/part/rootfs/etc/
sudo cp $(pwd)/binarios/rootfs/inittab $(pwd)/RPI/part/rootfs/etc/
sudo cp $(pwd)/binarios/rootfs/passwd $(pwd)/RPI/part/rootfs/etc/
sudo cp $(pwd)/binarios/rootfs/rcS $(pwd)/RPI/part/rootfs/etc/init.d/
sudo chmod 755 $(pwd)/RPI/part/rootfs/etc/init.d/rcS
