#!/bin/sh


#Creo la carpeta RPI/binutils en caso que sea
#la primera vez que corre este script.
mkdir -p $(pwd)/RPI/binutils/

#Si NO es la primera vez, quizas tiene datos 
#por las dudas borramos todo y arrancamos de 0.
rm -rf /RPI/binutils/*

#Directorios para compilar y para desplegar (deploy)
mkdir -p $(pwd)/RPI/binutils/build
mkdir -p $(pwd)/RPI/binutils/deploy

#Bajamos el codigo fuente
wget https://ftp.gnu.org/gnu/binutils/binutils-2.43.tar.xz --directory-prefix=$(pwd)/RPI/binutils
cd $(pwd)/RPI/binutils
tar xvf binutils-2.43.tar.xz
cd build

#cd build
../binutils-2.43/configure --target=aarch64-linux-gnu --host=aarch64-linux-gnu --bindir=/usr/bin
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
