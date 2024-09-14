#!/bin/sh

#Creo la carpeta RPI/glibc en caso que sea
#la primera vez que corre este script.
mkdir -p $(pwd)/RPI/glibc/

#Si NO es la primera vez, quizas tiene datos 
#por las dudas borramos todo y arrancamos de 0.
rm -rf $(pwd)/RPI/glibc/*

#Directorios para compilar y para desplegar (deploy)
mkdir -p $(pwd)/RPI/glibc/build
mkdir -p $(pwd)/RPI/glibc/deploy

HEADERS=$(pwd)/RPI/part/rootfs/usr/include

#Bajamos el codigo fuente
wget https://ftp.gnu.org/gnu/glibc/glibc-2.40.tar.xz --directory-prefix=$(pwd)/RPI/glibc
cd $(pwd)/RPI/glibc
tar xvf glibc-2.40.tar.xz


cd build
../glibc-2.40/configure --target=aarch64-linux-gnu --host=aarch64-linux-gnu --bindir=/usr/bin --enable-add-ons \
                        --with-headers=$HEADERS  --enable-kernel=4.14  --prefix=/ --includedir=/usr/include
echo "Revisar que el configure haya terminado bien"
echo "Si hubo errores usar Ctrl+C para cancelar "
echo "Sino cualquier tecla para continuar"
read x
echo "Ingrese cuantos procesos en paralelo quiere usar"
echo "Ej: si tiene una cpu con 4 nucleos, ingrese 4"
read jobs
make -j $jobs
echo "Revisar que haya compilado correctamente"
echo "Cancelar con Ctrl+C, o enter para seguir"
read x
sudo make DESTDIR=$(pwd)/../../part/rootfs  install
