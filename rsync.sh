#!/bin/bash

#
# Script para sincronizar archivos al servidor de clase.
#

rsync -avz --progress ./ rodrigobo@10.130.1.200:~/sh
