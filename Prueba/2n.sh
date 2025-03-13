#!/bin/bash

#
# Script que dependiendo del número introducido te devuelve un comentario acerca de la temperatura.
#

echo "Introduce un valor numérico"
read -r valor

if [ "$valor" -lt 10 ]; then
  echo "Hace frío"

elif [ "$valor" -ge 10 ] && [ "$valor" -le 18 ]; then
  echo "Templadillo"

elif [ "$valor" -gt 18 ] && [ "$valor" -lt 25 ]; then
  echo "Hace muy bueno"

elif [ "$valor" -ge 25 ] && [ "$valor" -le 30 ]; then
  echo "Calorcillo"

elif [ "$valor" -gt 30 ]; then
  echo "Te torras"

else
  echo "El valor introducido no es compatible con el rango."
fi

exit 0
