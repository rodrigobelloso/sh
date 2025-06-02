# Enunciados:

## 1. Crea un script que cumpla los siguientes requisitos:

- Procesará un número indeterminado de argumentos en línea de comando, que serán números (no es necesario comprobar que lo son). Continuará haciéndolo mientras el argumento que llegue sea mayor que el que acaba de salir. Al encontrar un argumento igual o menor, termina con el mensaje en pantalla "acabado".
- Obtendrá la suma total de números, excluyendo el último que hace parar el proceso. Emitirá dicha suma en un fichero llamado resultado txt, en el que pondremos simplemente:

  ```
  suma total = <el resultado de la suma>
  ```

- Al finalizar, tras poner "acabado", mostrará todos los números usados en pantalla, un operador de suma (+), una línea y debajo el resultado de la suma.

  ```
  n1
  n2
  n3
  + _________
  resultado
  ```

## 2. Escribe un script que saque por pantalla la siguiente formación (se muestra demo de ejecución):

```
Mete un número: 4

****
 * *
  **
   *
```

Se valorarán realizaciones parciales:

- +3,33 forma triangular similar aunque no tenga hueco interior.
- +3,33 estructura de programa correcta para el resultado aunque la formación en pantalla no sea correcta (esto es número de bucles y/o condicionales y estructura entre ellos)

## 3. Escribe un script:

- Que pida un nombre al usuario.
- Busque dicho nombre entre los usuarios del sistema y si existe retorne solamente la ruta a su $HOME
- Busque dicho nombre y si no existe intente crear un usuario con línea idéntica a la de root, pero con ese nombre como login.
