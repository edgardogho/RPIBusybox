#!/bin/bash

#Creo la carpeta RPI/kernel en caso que sea
#la primera vez que corre este script.
mkdir -p $(pwd)/RPI/kernel/

#Si NO es la primera vez, quizas tiene datos 
#por las dudas borramos todo y arrancamos de 0.
rm -rf $(pwd)/RPI/kernel/*


#Bajamos el codigo fuente
cd $(pwd)/RPI/kernel
git clone --depth=1 https://github.com/raspberrypi/linux

echo "La compilacion del kernel depende del chip"
echo "Ingrese el numero de RPI, ej: para RPI 5 ingrese 5 y enter"
read x

cd linux
#Limpiamos todo
make mrproper
if [ "$x" == "5" ]
then
	echo "Compilando para RPI 5"
	KERNEL=kernel_2712
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2712_defconfig
	
else
	echo "Compilando para RPI 3 o 4"
	KERNEL=kernel8
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig
fi

echo "Ingrese cuantos procesos en paralelo quiere usar"
echo "Ej: si tiene una cpu con 4 nucleos, ingrese 4"
read jobs

make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs -j $jobs
sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=$(pwd)/../../part/rootfs modules_install -j $jobs
#Exportar los Headers que hacen falta para GLIBC
sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_HDR_PATH=$(pwd)/../../part/rootfs/usr headers_install

#copiamos el monolitico y dtbs
mkdir -p $(pwd)/../../part/bootfs/overlays
sudo cp arch/arm64/boot/Image $(pwd)/../../part/bootfs/$KERNEL.img
sudo cp arch/arm64/boot/dts/broadcom/*.dtb $(pwd)/../../part/bootfs/
sudo cp arch/arm64/boot/dts/overlays/*.dtb* $(pwd)/../../part/bootfs/overlays/
sudo cp arch/arm64/boot/dts/overlays/README $(pwd)/../../part/bootfs/overlays/
