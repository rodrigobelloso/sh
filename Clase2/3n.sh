#!/bin/bash

#
# Script para descubrir como funciona el filtrado de archivos.
#

clear

ls * # Muestra todos los archivos.
ls *.sh # Muestra todos los archivos que terminan en .sh
ls 2* # Muestra todos los archivos que empiezan con 2.
ls 2*.sh # Muestra todos los archivos que empiezan con 2 y terminan en .sh.
ls !2* # Muestra todos los archivos que no empiezan con 2.

ls ? # Muestra todos los archivos que tienen 1 caracter.
ls ?? # Muestra todos los archivos que tienen 2 caracteres.
ls 3? # Muestra todos los archivos que empiezan con 3 y tienen 2 caracteres.

ls [n,1] # Muestra todos los archivos que tienen n o 1.

exit 0
