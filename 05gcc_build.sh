#!/bin/sh

#Creo la carpeta RPI/gcc en caso que sea
#la primera vez que corre este script.
mkdir -p $(pwd)/RPI/gcc/

#Si NO es la primera vez, quizas tiene datos 
#por las dudas borramos todo y arrancamos de 0.
rm -rf $(pwd)/RPI/gcc/*

#Directorios para compilar y para desplegar (deploy)
mkdir -p $(pwd)/RPI/gcc/deploy

#Bajamos el codigo fuente
wget https://ftp.gnu.org/gnu/gcc/gcc-11.4.0/gcc-11.4.0.tar.xz --directory-prefix=$(pwd)/RPI/gcc
cd $(pwd)/RPI/gcc
tar xvf gcc-11.4.0.tar.xz
cd gcc-11.4.0
./contrib/download_prerequisites
./configure --target=aarch64-linux-gnu --host=aarch64-linux-gnu --disable-nls --disable-multilib --enable-languages=c,c++  

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
sudo make DESTDIR=$(pwd)/../../part/rootfs  install all
