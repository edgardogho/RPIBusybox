#!/bin/sh

#Este script genera un sistema linux para Raspberry PI cross-compilando
#todos sus componentes (kernel, compilador, etc)
#Esta diseñado para correr en Ubuntu 24.04 (amd64/intel). No hay ningun
#soporte para ningun otro Sistema Operativo. 
#A medida que corre deja flags del progreso.

#Paso 00 -- Instalar Dependencias
echo "Instalando dependencias"
sudo apt -y install git bc bison flex libssl-dev make libc6-dev libncurses5-dev \
         crossbuild-essential-arm64 gawk texinfo xsltproc

#Creamos una variable para saber cuantos cores tiene esta computadora
CORES=$(nproc)

#Paso 01 -- Crea estructura del filesystem
echo "Verificando si existe la carpeta de particiones"

#La carpeta de particiones tiene la estructura varia (esqueleto) del
#sistemas de archivos que va a usar la RPI.

if [ ! -f $(pwd)/RPI/flagpart ]; then
	mkdir -p $(pwd)/RPI/part/bootfs
	mkdir -p $(pwd)/RPI/part/rootfs/usr
	mkdir -p $(pwd)/RPI/part/rootfs/dev
	mkdir -p $(pwd)/RPI/part/rootfs/tmp
	mkdir -p $(pwd)/RPI/part/rootfs/proc
	mkdir -p $(pwd)/RPI/part/rootfs/sys
	mkdir -p $(pwd)/RPI/part/rootfs/root
	mkdir -p $(pwd)/RPI/part/rootfs/mnt
	mkdir -p $(pwd)/RPI/part/rootfs/etc/init.d
	touch $(pwd)/RPI/flagpart
else
	echo "Ignorando paso"
fi

#Paso 02 -- Compilar a instalar binutils
#Binutils es un conjunto de programas utilitarios para el manejo
#de programas binarios. Incluye el linker (ld) que vamos a utilizar
#para que los programas puedan llamar a bibliotecas del sistema.

echo "Verificando si existe BinUtils"
if [ ! -f $(pwd)/RPI/flagbinutils ]; then
	#Creamos la carpeta si no existe
	mkdir -p $(pwd)/RPI/binutils/
	#Borramos el contenido si ya estaba de antes
	rm -rf /RPI/binutils/*
	#Creamos los directorios para compilar y desplegar
	mkdir -p $(pwd)/RPI/binutils/build
	mkdir -p $(pwd)/RPI/binutils/deploy
	#Descargamos el tarball con el codigo fuente
	#Usamos como mirror la universidad de wayne ya que
	#los servides de GNU son terriblemente lentos
	wget https://ftp.wayne.edu/gnu/binutils/binutils-2.47.tar.xz --directory-prefix=$(pwd)/RPI/binutils
	if [ $? -ne 0 ]; then
		echo "Error descargando binutils"
		exit 1
	fi
	#Descomprimimos y compilamos
	cd $(pwd)/RPI/binutils
	tar xvf binutils-2.47.tar.xz
	cd build
	echo "Haciendo el configure de binutils"
	../binutils-2.47/configure --target=aarch64-linux-gnu --host=aarch64-linux-gnu --bindir=/usr/bin
	if [ $? -ne 0 ]; then
		echo "Error configurando binutils"
		exit 1
	fi
	echo "Compilando binutils"
	make -j $CORES
	if [ $? -ne 0 ]; then
		echo "Error compilando binutils"
		exit 1
	fi
	echo "Desplegando binutils al filesystem"
	sudo make DESTDIR=$(pwd)/../../part/rootfs  install
	if [ $? -ne 0 ]; then
		echo "Error desplegando binutils"
		exit 1
	fi
	echo "Finalizado binutils"
	cd ../../..
	touch $(pwd)/RPI/flagbinutils
else
	echo "Flag de binutils encontrado, ignorando binutils"
fi

#Paso 03 -- Compilar el kernel
#El kernel se encarga de controlar el hardware y administrar los recursos
#del sistema operativo. En el caso de RPI 3 y 4  se utiliza el kernel compilado
#para el chip bcm2711, mientras que RPI 5 utiliza bcm2712. Vamos a compilar 
#ambos kernels e instalarlos en la misma particion

echo "Verificando si existe el kernel"
if [ ! -f $(pwd)/RPI/flagkernel ]; then
	#creamos el espacio de trabajo
	mkdir -p $(pwd)/RPI/kernel/
	sudo rm -rf $(pwd)/RPI/kernel/*
	#descargamos el codigo del kernel
	echo "Descargando el kernel"
	cd $(pwd)/RPI/kernel
	git clone --depth=1 https://github.com/raspberrypi/linux
	if [ $? -ne 0 ]; then
		echo "Error descargando el Kernel"
		exit 1
	fi
	cd linux
	#Limpiamos todo
	sudo make mrproper
	echo "Configurando para RPI 3 y 4"
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig
	if [ $? -ne 0 ]; then
		echo "Error configurando el Kernel para RPI3 y 4"
		exit 1
	fi
	echo "Compilando kernel para RPI 3 y 4"
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs -j $CORES
	if [ $? -ne 0 ]; then
		echo "Error configurando el Kernel para RPI3 y 4"
		exit 1
	fi
	echo "Desplegando kernel para RPI 3 y 4"
	sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=$(pwd)/../../part/rootfs modules_install -j $CORES
	if [ $? -ne 0 ]; then
		echo "Error configurando el Kernel para RPI3 y 4"
		exit 1
	fi
	sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_HDR_PATH=$(pwd)/../../part/rootfs/usr headers_install
	if [ $? -ne 0 ]; then
		echo "Error configurando el Kernel para RPI3 y 4"
		exit 1
	fi
	echo "Copiando kernel y dtbs para RPI 3 y 4"
	mkdir -p $(pwd)/../../part/bootfs/overlays
	sudo cp arch/arm64/boot/Image $(pwd)/../../part/bootfs/kernel8.img
	sudo cp arch/arm64/boot/dts/broadcom/*.dtb $(pwd)/../../part/bootfs/
	sudo cp arch/arm64/boot/dts/overlays/*.dtb* $(pwd)/../../part/bootfs/overlays/
	sudo cp arch/arm64/boot/dts/overlays/README $(pwd)/../../part/bootfs/overlays/
	
	#Ahora podemos repetir para RPI 5
	sudo make mrproper
	echo "Configurando para RPI 5"
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2712_defconfig
	if [ $? -ne 0 ]; then
		echo "Error configurando el Kernel para RPI 5"
		exit 1
	fi
	echo "Compilando kernel para RPI 5"
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs -j $CORES
	if [ $? -ne 0 ]; then
		echo "Error configurando el Kernel para RPI 5"
		exit 1
	fi
	echo "Desplegando kernel para RPI 5"
	sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=$(pwd)/../../part/rootfs modules_install -j $CORES
	if [ $? -ne 0 ]; then
		echo "Error configurando el Kernel para RPI 5"
		exit 1
	fi
	sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_HDR_PATH=$(pwd)/../../part/rootfs/usr headers_install
	if [ $? -ne 0 ]; then
		echo "Error configurando el Kernel para RPI 5"
		exit 1
	fi
	echo "Copiando kernel y dtbs para RPI 5 "
	sudo cp arch/arm64/boot/Image $(pwd)/../../part/bootfs/kernel_2712.img
	sudo cp arch/arm64/boot/dts/broadcom/*.dtb $(pwd)/../../part/bootfs/
	sudo cp arch/arm64/boot/dts/overlays/*.dtb* $(pwd)/../../part/bootfs/overlays/
	sudo cp arch/arm64/boot/dts/overlays/README $(pwd)/../../part/bootfs/overlays/
	
	cd ../../../
	touch $(pwd)/RPI/flagkernel
	echo "fin de compilacion del kernel"
else
	echo "ignorando compilacion de kernel"
fi

#Paso 04 -- Compilando GlibC
#GNU LibC es la biblioteca estandar de C creada por GNU.
#Esta biblioteca contiene el código de funciones estandares 
#del lenguaje C, como por ejemplo Printf, malloc, etc.
#El codigo compilado de esta biblioteca suele ir a libc.so.6

HEADERS=$(pwd)/RPI/part/rootfs/usr/include

echo "Verificando si existe GNU Lib C (glibc)"
if [ ! -f $(pwd)/RPI/flagglibc ]; then
	#Creamos la carpeta si no existe
	mkdir -p $(pwd)/RPI/glibc/
	#Borramos el contenido si ya estaba de antes
	rm -rf /RPI/binutils/*
	#Creamos los directorios para compilar y desplegar
	mkdir -p $(pwd)/RPI/glibc/build
	mkdir -p $(pwd)/RPI/glibc/deploy
	#Descargamos el tarball con el codigo fuente
	#Usamos como mirror la universidad de wayne ya que
	#los servides de GNU son terriblemente lentos
	wget https://ftp.wayne.edu/gnu/glibc/glibc-2.44.tar.xz --directory-prefix=$(pwd)/RPI/glibc
	if [ $? -ne 0 ]; then
		echo "Error descargando glibc"
		exit 1
	fi
	cd $(pwd)/RPI/glibc
	tar xvf glibc-2.44.tar.xz
	echo "Configurando glibc"
	cd build
	../glibc-2.44/configure --target=aarch64-linux-gnu --host=aarch64-linux-gnu --bindir=/usr/bin --enable-add-ons \
                        --with-headers=$HEADERS  --enable-kernel=4.14  --prefix=/ --includedir=/usr/include
    if [ $? -ne 0 ]; then
		echo "Error configurando glibc"
		exit 1
	fi  
	echo "Compilando glibc"
	make -j $CORES
	if [ $? -ne 0 ]; then
		echo "Error compilando glibc"
		exit 1
	fi   
	echo "Desplegando glibc"
	sudo make DESTDIR=$(pwd)/../../part/rootfs  install
	if [ $? -ne 0 ]; then
		echo "Error desplegando glibc"
		exit 1
	fi 
	cd ../../..
	touch $(pwd)/RPI/flagglibc                
else
	echo "ignorando compilacion de glibc"
fi

#Paso 05 -- Compilando gcc (GNU Compiler Collection)
#GCC es un conjunto de compiladores (c,c++,etc) mantenidos
#por el proyecto GNU. 
echo "Verificando si existe gcc"
if [ ! -f $(pwd)/RPI/flaggcc ]; then
	mkdir -p $(pwd)/RPI/gcc/
	rm -rf $(pwd)/RPI/gcc/*
	echo "Descargando gcc"
	wget https://ftp.wayne.edu/gnu/gcc/gcc-13.4.0/gcc-13.4.0.tar.xz --directory-prefix=$(pwd)/RPI/gcc
	if [ $? -ne 0 ]; then
		echo "Error descargando gcc"
		exit 1
	fi 
	cd $(pwd)/RPI/gcc
	tar xvf gcc-13.4.0.tar.xz
	cd gcc-13.4.0
	echo "Configurando gcc"
	./contrib/download_prerequisites
	./configure --target=aarch64-linux-gnu --host=aarch64-linux-gnu --disable-nls --disable-multilib --enable-languages=c,c++  
	if [ $? -ne 0 ]; then
		echo "Error configurando gcc"
		exit 1
	fi 
	echo "Compilando gcc"
	make -j $CORES
	if [ $? -ne 0 ]; then
		echo "Error compilando gcc"
		exit 1
	fi 
	echo "Desplegando gcc"
	sudo make DESTDIR=$(pwd)/../../part/rootfs  install all
	if [ $? -ne 0 ]; then
		echo "Error desplegando gcc"
		exit 1
	fi 
	cd ../../..
	touch $(pwd)/RPI/flaggcc
else
	echo "ignorando compilacion de gcc"
fi

#Paso 06 -- Compilando busybox 
#Busybox es un proyecto que integra en un unico binario
#muchas de las utilidades tipicas de unix (cp, mv, cd, etc) 
echo "Verificando si existe busybox"
if [ ! -f $(pwd)/RPI/flagbusybox ]; then
	mkdir -p $(pwd)/RPI/busybox/
	rm -rf $(pwd)/RPI/busybox/*
	echo "Descargando busybox"
	wget https://busybox.net/downloads/busybox-1.38.0.tar.bz2 --directory-prefix=$(pwd)/RPI/busybox
	if [ $? -ne 0 ]; then
		echo "Error descargando busybox"
		exit 1
	fi 
	cd $(pwd)/RPI/busybox
	tar -xvjf busybox-1.38.0.tar.bz2
	cd busybox-1.38.0
	echo "Configurando busybox"
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
	if [ $? -ne 0 ]; then
		echo "Error configurando busybox"
		exit 1
	fi 
	#A este archivo le hacemos algunos cambios minimos
	sed -i -e 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g' .config
	sed -i -e 's/CONFIG_BASH_IS_NONE=y/# CONFIG_BASH_IS_NONE is not set/g' .config
	sed -i -e 's/# CONFIG_BASH_IS_ASH is not set/CONFIG_BASH_IS_ASH=y/g' .config
	sed -i -e 's/#define BB_ADDITIONAL_PATH \"\"/#define BB_ADDITIONAL_PATH \":\/usr\/local\/bin\"/g' include/libbb.h
	#Si se compila con un kernel mayor o igual a 6.8 falla...
	#https://lists.busybox.net/pipermail/busybox-cvs/2024-January/041752.html
	#Workaround: desactivar TC
	sed -i -e 's/CONFIG_TC=y/# CONFIG_TC is not set/g' .config
	echo "Compilando busybox"
	make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j $CORES
	if [ $? -ne 0 ]; then
		echo "Error compilando busybox"
		exit 1
	fi 
	echo "Desplegando busybox"
	sudo make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- install CONFIG_PREFIX=$(pwd)/../../part/rootfs
	if [ $? -ne 0 ]; then
		echo "Error desplegando busybox"
		exit 1
	fi 
	sudo chmod 4755 $(pwd)/../../part/rootfs/bin/busybox
	
	cd ../../..
	touch $(pwd)/RPI/flagbusybox
else
	echo "Ignorando busybox"
fi

#Paso 07 -- Compilando udev 
#udev es un manejador de dispositivos dinamicos del kernel.
#Cuando un nuevo dispositivo aparece en el sistema 
#(ej: se conecta un joystick por USB) el kernel general un evento 
#de hot-plug. Este evento debe ser capturado por algun programa
#que reconozca el dispositivo, cargue los drivers, defina
#los permisos, etc. En linux se suele usar udev , pero ahora
#es parte del proyecto systemd. Como alternativa a esto
#usamod eudev (version de udev sin systemd). 
#Este programa utiliza libblkid para leer los detalles de un
#dispositivo de almacenamiento masivo (flashdrive, SSD, HDD, etc).
#Si bien busybox trae blkid no posee libblkid, asi que tomamos
#de util-linux solo libblkid primero.
 
echo "Verificando si existe udev"
if [ ! -f $(pwd)/RPI/flagudev ]; then
	mkdir -p $(pwd)/RPI/util-linux/
	rm -rf $(pwd)/RPI/util-linux/*
	mkdir -p $(pwd)/RPI/util-linux/build
	wget https://www.kernel.org/pub/linux/utils/util-linux/v2.42/util-linux-2.42.tar.gz --directory-prefix=$(pwd)/RPI/util-linux
	if [ $? -ne 0 ]; then
		echo "Error compilando util-linux"
		exit 1
	fi 
	cd $(pwd)/RPI/util-linux
	tar xvf util-linux-2.42.tar.gz
	cd build
	echo "Configurando util-linux"
	../util-linux-2.42/configure --target=aarch64-linux-gnu --host=aarch64-linux-gnu --disable-all-programs --enable-libblkid
	if [ $? -ne 0 ]; then
		echo "Error configurando util-linux"
		exit 1
	fi 
	make -j $CORES
	if [ $? -ne 0 ]; then
		echo "Error compilando util-linux"
		exit 1
	fi 
	echo "Desplegando util-linux"
	sudo make DESTDIR=$(pwd)/../../part/rootfs  install
	if [ $? -ne 0 ]; then
		echo "Error desplegando util-linux"
		exit 1
	fi 
	cd ../../..
	echo "Descargando eudev"
	mkdir -p $(pwd)/RPI/eudev/
	rm -rf $(pwd)/RPI/eudev/*
	mkdir -p $(pwd)/RPI/eudev/build
	wget https://github.com/eudev-project/eudev/releases/download/v3.2.14/eudev-3.2.14.tar.gz --directory-prefix=$(pwd)/RPI/eudev
	if [ $? -ne 0 ]; then
		echo "Error descargando eudev"
		exit 1
	fi 
	cd $(pwd)/RPI/eudev
	tar xvf eudev-3.2.14.tar.gz
	cd build
	../eudev-3.2.14/configure --target=aarch64-linux-gnu --host=aarch64-linux-gnu --disable-selinux
	if [ $? -ne 0 ]; then
		echo "Error configurando eudev"
		exit 1
	fi
	make  LDFLAGS="-L$(pwd)/../../part/rootfs/usr/lib" -j $CORES
	if [ $? -ne 0 ]; then
		echo "Error compilando eudev"
		exit 1
	fi
	
	sudo make DESTDIR=$(pwd)/../../part/rootfs  install
	if [ $? -ne 0 ]; then
		echo "Error desplegando eudev"
		exit 1
	fi
	cd ../../..
	touch $(pwd)/RPI/flagudev
else
	echo "ignorando eudev"
fi

#Paso 08 -- Armando el root filesystem
#Configurar busybox con un script de init
#Cargar el archivo de grupos, passwords
#montar los filesystems especiales (proc, tmpfs, dev)
#copiar los archivos del bootloader de RPI 3,4 y 5.
 
echo "Verificando si esta configurado el filesystem"
if [ ! -f $(pwd)/RPI/flagrootfs ]; then
	cp $(pwd)/binarios/bootcode.bin $(pwd)/RPI/part/bootfs/
	if [ $? -ne 0 ]; then
		echo "Error copiando archivo bootcode"
		exit 1
	fi
	cp $(pwd)/binarios/cmdline.txt $(pwd)/RPI/part/bootfs/
	if [ $? -ne 0 ]; then
		echo "Error copiando archivo cmdline"
		exit 1
	fi
	cp $(pwd)/binarios/config.txt $(pwd)/RPI/part/bootfs/
	if [ $? -ne 0 ]; then
		echo "Error copiando archivo config"
		exit 1
	fi
	cp $(pwd)/binarios/start4.elf $(pwd)/RPI/part/bootfs/
	if [ $? -ne 0 ]; then
		echo "Error copiando archivo start4"
		exit 1
	fi
	cp $(pwd)/binarios/start.elf $(pwd)/RPI/part/bootfs/
	if [ $? -ne 0 ]; then
		echo "Error copiando archivo start"
		exit 1
	fi
	cp $(pwd)/binarios/group $(pwd)/RPI/part/rootfs/etc/
	if [ $? -ne 0 ]; then
		echo "Error copiando archivo group"
		exit 1
	fi
	cp $(pwd)/binarios/inittab $(pwd)/RPI/part/rootfs/etc/
	if [ $? -ne 0 ]; then
		echo "Error copiando archivo inittab"
		exit 1
	fi
	cp $(pwd)/binarios/passwd $(pwd)/RPI/part/rootfs/etc/
	if [ $? -ne 0 ]; then
		echo "Error copiando archivo passwd"
		exit 1
	fi
	cp $(pwd)/binarios/rcS $(pwd)/RPI/part/rootfs/etc/init.d/
	if [ $? -ne 0 ]; then
		echo "Error copiando archivo group"
		exit 1
	fi
	chmod 755 $(pwd)/RPI/part/rootfs/etc/init.d/rcS
	if [ $? -ne 0 ]; then
		echo "Error cambiando permisos de rcS en /etc/init.d"
		exit 1
	fi
	touch $(pwd)/RPI/flagrootfs
	echo "Finalizado"
else
	echo "ignorando root filesystem"
fi

echo "Sistema armado en la carpeta RPI/part"
echo "Copie a BOOTFS el contenido de RPI/part/bootfs"
echo "Copie a ROOTFS el contenido de RPI/part/rootfs"
