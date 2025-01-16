#!/bin/bash

#
# Script que devuelve el parametro introducido excepto si es 777.
#

while [ "$1" != "777" ] && [ $# -gt 0 ]
do
    echo "$1"
    shift
done