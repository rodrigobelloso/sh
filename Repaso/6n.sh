#!/bin/bash

#
# Uso básico de un switch.
#

dia="lunes"

case $dia in
    "lunes")
        echo "Inicio de semana."
        ;;
    "viernes")
        echo "¡Por fin es viernes!"
        ;;
    "sábado" | "domingo")
        echo "¡Es finde!"
        ;;
    *)
        echo "Es un día entre semana. :/"
        ;;
esac

