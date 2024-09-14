#!/bin/sh

#Creo la carpeta RPI/busybox en caso que sea
#la primera vez que corre este script.
mkdir -p $(pwd)/RPI/busybox/

#Si NO es la primera vez, quizas tiene datos 
#por las dudas borramos todo y arrancamos de 0.
rm -rf $(pwd)/RPI/busybox/*


#Bajamos el codigo fuente
wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2 --directory-prefix=$(pwd)/RPI/busybox
cd $(pwd)/RPI/busybox
tar -xvjf busybox-1.36.1.tar.bz2
cd busybox-1.36.1

#Creamos el archivo .config por defecto que viene en busybox
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig 

#A este archivo le hacemos algunos cambios minimos
sed -i -e 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g' .config
sed -i -e 's/CONFIG_BASH_IS_NONE=y/# CONFIG_BASH_IS_NONE is not set/g' .config
sed -i -e 's/# CONFIG_BASH_IS_ASH is not set/CONFIG_BASH_IS_ASH=y/g' .config
sed -i -e 's/#define BB_ADDITIONAL_PATH \"\"/#define BB_ADDITIONAL_PATH \":\/usr\/local\/bin\"/g' include/libbb.h


echo "Revisar que el configure haya terminado bien"
echo "Si hubo errores usar Ctrl+C para cancelar "
echo "Sino cualquier tecla para continuar"
read x
echo "Ingrese cuantos procesos en paralelo quiere usar"
echo "Ej: si tiene una cpu con 4 nucleos, ingrese 4"
read jobs
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j $jobs
echo "Revisar que haya compilado correctamente"
echo "Cancelar con Ctrl+C, o enter para seguir"
read x
sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- install CONFIG_PREFIX=$(pwd)/../../part/rootfs
sudo chmod 4755 $(pwd)/../../part/rootfs/bin/busybox

