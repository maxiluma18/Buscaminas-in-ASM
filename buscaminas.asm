.data
        mensaje_bienvenida: .asciz "Bienvenido a BUSCAMINAS!"
        mensaje_info: .asciz "\nJuego de consola. Descubre las casillas sin minas. Selecciona fila y columna. Si tocas una mina pierdes.Solo cuentan como vecinas las casillas arriba, abajo, izquierda y derecha."
        mensaje_pedir_nombre: .asciz "\nIngrese su nombre: (exactamente 5 letras) "
        mensaje_pedir_nivel: .asciz "\nNivel de dificultad (1=Facil, 2=Medio, 3=Dificil): "
        mensaje_pedir_tamanio: .asciz "\nSeleccione tamaño del mapa (1=8x8, 2=12x12): "
        mensaje_pedir_fila: .asciz "\nIngrese fila (1-8/12): "
        mensaje_pedir_columna: .asciz "Ingrese columna (1-8/12): "
        mensaje_mina: .asciz "\n¡BOOM! Has encontrado una mina. Fin del juego.\n"
        mensaje_casillas_restantes: .asciz "\nCasillas sin mina por descubrir: "
        mensaje_victoria: .asciz "\n¡Felicitaciones! Has ganado el juego.\n"
        mensaje_tiempo:   .asciz "Tiempo: "
        mensaje_segundos: .asciz " segundos"
        
        nombre_usuario: .space 6   @ 5 letras + null terminator
        nivel_dificultad: .space 3   @ 1 dígito + salto de línea + null
        tamanio_mapa: .space 3       @ 1 dígito + salto de línea + null
        valor_tamanio_tablero: .space 2        

        tablero8: .space 64      @ 8x8 - tablero con minas y números
        tablero12: .space 144    @ 12x12 - tablero con minas y números
        tablero_actual: .word 0   @ Puntero al tablero real en uso
        tablero8_oculto: .space 64      @ 8x8 - tablero que ve el usuario
        tablero12_oculto: .space 144    @ 12x12 - tablero que ve el usuario
        tablero_oculto: .word 0   @ Puntero al tablero oculto en uso

        cantidad_minas: .word 0     @ Guarda la cantidad de minas que debe tener el tablero
        CELDA_OCULTA: .byte '-'    @ Carácter para celda sin revelar
        buffer_ascii: .space 2
        espacio_ascii: .asciz " "
        salto_ascii: .asciz "\n"

        semilla_random: .word 1234567891    @valor inicial de semilla, cambia con random
        const_mul: .word 1103515245         @ valor multiplicación, este y el de suma añaden aleatoriedad
        const_add: .word 12345              @ valor suma 

        casillas_objetivo: .word 0    @ 10, 20 o 25 según nivel
        casillas_descubiertas: .word 0 @ contador de casillas sin mina descubiertas para ganar
        buffer_entrada: .space 4      @ para leer fila/columna (número de 2 dígitos + \n + \0)

        color_reset: .asciz "\033[0m"
        color_rojo: .asciz "\033[31m"
        color_verde: .asciz "\033[32m"
        color_amarillo: .asciz "\x1b[33m"   

        tiempo_inicio: .space 8 @tiempo inicio juego 
        tiempo_final:  .space 8 @tiempo final juego  
        tiempo_victoria: .space 8 @tiempo inicio - final 

.text

@ --------------------------------------------------------
@ tomar_tiempo_inicio: guarda el tiempo actual al iniciar la partida
@ Usa syscall #78 (gettimeofday) y lo guarda en tiempo_inicio
@ --------------------------------------------------------
tomar_tiempo_inicio:
    push {lr}                  @ Guardamos el valor de lr (dirección de retorno)
    ldr r0, =tiempo_inicio     
    mov r7, #78                @ syscall 78 = gettimeofday
    swi 0                      @ llamada al sistema, almacena el tiempo en tiempo_inicio
    pop {lr}                   @ Restauramos la dirección de retorno
    bx lr                      @ Volvemos de la subrutina

@ --------------------------------------------------------
@ mostrar_mensaje_bienvenida: le muestra el mensaje de bienvenida
@ --------------------------------------------------------
mostrar_mensaje_bienvenida:
    push {lr}
    mov r0, #1                  @ Avisa que sale
    ldr r1, =mensaje_bienvenida @ dirección del mensaje
    mov r2, #24                @ longitud del mensaje
    mov r7, #4                  @ syscall: write
    swi 0
    pop {lr}
    bx lr

@ --------------------------------------------------------
@ mostrar_mensaje_info: le muestra el mensaje de info
@ --------------------------------------------------------
mostrar_mensaje_info:
    push {lr}
    mov r0, #1                  @ Avisa que sale
    ldr r1, =mensaje_info       @ dirección del mensaje
    mov r2, #180                @ longitud del mensaje
    mov r7, #4                  @ syscall: write
    swi 0
    pop {lr}
    bx lr

@ ----------------------------------------------------------------------
@ pedir_nombre: pide el nombre al usuario y verifica que tenga 5 letras.
@ Si no cumple, borra lo ingresado y lo vuelve a pedir.
@ Usa: r0, r1, r2, r3
@ ----------------------------------------------------------------------
pedir_nombre:
repetir_nombre:
    mov r0, #1                            @ pongo 1 en r0 para stdout
    ldr r1, =mensaje_pedir_nombre         @ cargo el mensaje "Ingrese su nombre"
    mov r2, #44                           @ longitud del mensaje
    mov r7, #4                            @ syscall write
    swi 0

    mov r0, #0                            @ pongo 0 en r0 para stdin
    ldr r1, =nombre_usuario               @ guardo lo ingresado en nombre_usuario
    mov r2, #6                            @ puede tener hasta 5 letras + '\n'
    mov r7, #3                            @ syscall read
    swi 0

    ldr r0, =nombre_usuario               @ cargo dirección de nombre
    mov r2, #0                            @ contador = 0

contar_loop:
    ldrb r1, [r0, r2]                     @ leo un byte del nombre
    cmp r1, #0                            @ si es null terminator, corto
    beq fin_contar
    cmp r1, #10                           @ si es salto de línea, corto
    beq fin_contar
    add r2, r2, #1                        @ aumento el contador
    cmp r2, #6                            @ máximo 6 caracteres
    bne contar_loop

fin_contar:
    cmp r2, #5                            @ si son exactamente 5 caracteres
    beq nombre_valido                     @ entonces está bien

    @ si no son 5 letras, vaciamos el nombre y volvemos a pedir
    ldr r0, =nombre_usuario               @ dirección del nombre
    mov r1, #0                            @ valor nulo para borrar
    mov r3, #0                            @ índice

vaciar_loop:
    strb r1, [r0, r3]                     @ escribo 0 en cada byte
    add r3, r3, #1                        @ paso al siguiente
    cmp r3, #6                            @ hasta 6 bytes
    bne vaciar_loop

    b repetir_nombre                      @ vuelvo a pedir nombre

nombre_valido:
    bx lr                                 

@ --------------------------------------------------------
@ ajustar_semilla_con_nombre: suma los valores ASCII del nombre a la semilla para dar aleatoriedad cada vez que un usuario juega
@ Usa: r0-r3
@ --------------------------------------------------------
ajustar_semilla_con_nombre:
    push {r0-r3, lr}           @ guardo los registros que voy a usar
    ldr r0, =nombre_usuario    @ cargo en r0 la dirección del nombre del usuario
    mov r1, #0                 @ pongo 0 en r1, va a acumular la suma de ASCII
    mov r2, #0                 @ pongo 0 en r2, lo uso como índice

sumar_ascii_nombre:
    ldrb r3, [r0, r2]          @ cargo el byte (carácter) r3 = nombre[r2]
    add r1, r1, r3             @ sumo el ASCII a r1
    add r2, r2, #1             @ aumento el índice
    cmp r2, #5                 @ comparo si llegué a 5 letras
    blt sumar_ascii_nombre     @ si no llegué, sigo el loop

    ldr r0, =semilla_random    @ cargo dirección de la semilla
    ldr r2, [r0]               @ cargo el valor actual de la semilla en r2
    add r2, r2, r1             @ le sumo el acumulado del nombre
    str r2, [r0]               @ guardo la nueva semilla

    pop {r0-r3, lr}            @ recupero los registros
    bx lr    

@ ----------------------------------------------------------------------
@ pedir_nivel_dificultad: pide al usuario un nivel (1, 2 o 3).
@ Si el valor ingresado no es válido, vuelve a pedirlo.
@ Usa: r0, r1
@ ----------------------------------------------------------------------
pedir_nivel_dificultad:
repetir_nivel:
    mov r0, #1                            @ pongo 1 en r0 para mostrar mensaje (stdout)
    ldr r1, =mensaje_pedir_nivel         @ cargo el mensaje de nivel
    mov r2, #53                           @ longitud del mensaje
    mov r7, #4                            @ syscall write
    swi 0

    mov r0, #0                            @ pongo 0 en r0 para leer (stdin)
    ldr r1, =nivel_dificultad            @ guardo lo ingresado en nivel_dificultad
    mov r2, #3                            @ puede tener hasta 1 número + salto + null
    mov r7, #3                            @ syscall read
    swi 0

    ldr r0, =nivel_dificultad            @ cargo la dirección del buffer
    ldrb r1, [r0]                        @ leo el primer carácter ingresado

    cmp r1, #'1'                         @ si es '1' está ok
    beq nivel_valido
    cmp r1, #'2'                         @ si es '2' está ok
    beq nivel_valido
    cmp r1, #'3'                         @ si es '3' está ok
    beq nivel_valido

    b repetir_nivel                      @ si no es ninguno de esos, lo pide de nuevo

nivel_valido:
    bx lr                                

@ ----------------------------------------------------------------------
@ pedir_tamanio_mapa: le pide al usuario que elija el tamaño del mapa.'1' (8x8) o '2' (12x12). Si no pone eso, lo repite.
@ Usa: r0, r1
@ ----------------------------------------------------------------------
pedir_tamanio_mapa:
repetir_tamanio:
    mov r0, #1                            @ stdout
    ldr r1, =mensaje_pedir_tamanio       @ carga el mensaje para pedir tamaño
    mov r2, #48                           @ longitud del mensaje
    mov r7, #4                            @ syscall write
    swi 0

    mov r0, #0                            @ stdin
    ldr r1, =tamanio_mapa                @ guarda el input en tamanio_mapa
    mov r2, #3                            @ puede tener 1 dígito + \n + \0
    mov r7, #3                            @ syscall read
    swi 0

    ldr r0, =tamanio_mapa                @ cargo dirección del buffer
    ldrb r1, [r0]                        @ leo el primer carácter

    cmp r1, #'1'                         @ si puso '1', es válido (8x8)
    beq tamanio_valido
    cmp r1, #'2'                         @ si puso '2', es válido (12x12)
    beq tamanio_valido

    b repetir_tamanio                    @ si no es válido, vuelve a pedir

tamanio_valido:
    bx lr                                

@ --------------------------------------------------------
@ guardar_tamanio_tablero: guarda 8 o 12 en valor_tamanio_tablero según input '1' o '2'
@ usa: r1-r4
@ --------------------------------------------------------
guardar_tamanio_tablero:
    push {lr}                       @ Guardamos lr para luego poder volver correctamente
    ldr r1, =tamanio_mapa           @ Apuntamos a la variable donde está el ASCII ingresado ('1' o '2')
    ldrb r2, [r1]                   @ Cargamos el valor ASCII (carácter) del tamaño ingresado
    cmp r2, #'1'                    @ Comparamos si es '1'
    beq tamanio_es_8                @ Si es '1', vamos a guardar 8 en valor_tamanio_tablero
    cmp r2, #'2'                    @ Si no, comparamos si es '2'
    beq tamanio_es_12               @ Si es '2', vamos a guardar 12 en valor_tamanio_tablero
    b fin_guardar_tamanio           @ Si no es '1' ni '2', saltamos a salir sin hacer nada 

tamanio_es_8:
    ldr r3, =valor_tamanio_tablero  @ Apuntamos a la variable donde guardamos el tamaño
    mov r4, #8                      @ Preparamos el valor 8
    strb r4, [r3]                  @ Guardamos el 8 (un byte) en valor_tamanio_tablero
    b fin_guardar_tamanio           @ Saltamos a terminar

tamanio_es_12:
    ldr r3, =valor_tamanio_tablero  @ Apuntamos a la variable donde guardamos el tamaño
    mov r4, #12                     @ Preparamos el valor 12
    strb r4, [r3]                  @ Guardamos el 12 (un byte) en valor_tamanio_tablero
    b fin_guardar_tamanio           @ Saltamos a terminar

fin_guardar_tamanio:
    pop {lr}                       @ Recuperamos lr para volver
    bx lr                         

@ --------------------------------------------------------
@ crear_Tablero: asigna punteros a tableros y oculta según tamaño (8 o 12)
@ inicializa tableros real y oculto con valores por defecto
@ usa: r0-r8
@ --------------------------------------------------------
crear_Tablero:
    push {r4-r7, lr}               @ Guardamos registros r4 a r7 y lr en pila
    ldr r0, =valor_tamanio_tablero @ Cargamos la dirección de valor_tamanio_tablero
    ldrb r1, [r0]                  @ Leemos el tamaño del tablero (8 o 12)
    cmp r1, #8                    @ Comparamos si es 8
    beq usar_tablero8             @ Si es 8, saltamos a usar_tablero8
    cmp r1, #12                   @ Comparamos si es 12
    beq usar_tablero12            @ Si es 12, saltamos a usar_tablero12
    b fin_crearTablero            @ Si no es ni 8 ni 12, saltamos a fin

usar_tablero8:
    ldr r2, =tablero8             @ Cargamos la dirección de tablero8 (real)
    ldr r3, =tablero_actual       @ Cargamos la dirección de tablero_actual
    str r2, [r3]                  @ Guardamos el puntero a tablero8 en tablero_actual
    ldr r2, =tablero8_oculto      @ Cargamos la dirección de tablero8_oculto
    ldr r3, =tablero_oculto       @ Cargamos la dirección de tablero_oculto
    str r2, [r3]                  @ Guardamos el puntero a tablero8_oculto en tablero_oculto
    mov r4, #64                   @ Calculamos tamaño total: 8x8 = 64 bytes
    b inicializar_tablero         @ Saltamos a inicializar_tablero

usar_tablero12:
    ldr r2, =tablero12            @ Cargamos la dirección de tablero12 (real)
    ldr r3, =tablero_actual       @ Cargamos la dirección de tablero_actual
    str r2, [r3]                  @ Guardamos el puntero a tablero12 en tablero_actual
    ldr r2, =tablero12_oculto     @ Cargamos la dirección de tablero12_oculto
    ldr r3, =tablero_oculto       @ Cargamos la dirección de tablero_oculto
    str r2, [r3]                  @ Guardamos el puntero a tablero12_oculto en tablero_oculto
    mov r4, #144                  @ Calculamos tamaño total: 12x12 = 144 bytes

inicializar_tablero:
    mov r5, #0                    @ Inicializamos índice a 0
    mov r6, #0                    @ Valor 0 para tablero real (vacío)
    ldr r7, =CELDA_OCULTA         @ Cargamos la dirección del carácter de celda oculta
    ldrb r8, [r7]                 @ Leemos el carácter de celda oculta ('-')
    ldr r2, =tablero_actual       @ Cargamos la dirección del puntero al tablero real
    ldr r2, [r2]                  @ Cargamos el puntero al tablero real
    ldr r3, =tablero_oculto       @ Cargamos la dirección del puntero al tablero oculto
    ldr r3, [r3]                  @ Cargamos el puntero al tablero oculto

iniciar_tablero_loop:
    cmp r5, r4                   @ Comparamos índice con tamaño total del tablero
    bge fin_crearTablero          @ Si índice >= tamaño, terminamos
    strb r6, [r2, r5]            @ Guardamos 0 en la celda real actual
    strb r8, [r3, r5]            @ Guardamos '-' en la celda oculta actual
    add r5, r5, #1               @ Incrementamos índice
    b iniciar_tablero_loop        @ Repetimos para la siguiente celda

fin_crearTablero:
    pop {r4-r7, lr}               @ Recuperamos registros y lr
    bx lr

@ --------------------------------------------------------
@ calcular_y_colocar_minas: calcula cantidad minas según nivel y llama a colocar_minas
@ --------------------------------------------------------
calcular_y_colocar_minas:
    push {r4-r7, lr}
    ldr r4, =valor_tamanio_tablero   @ cargo dirección de tamaño tablero
    ldrb r5, [r4]                    @ leo tamaño tablero (8 o 12) en r5
    mov r3, r5                      @ copio tamaño para multiplicar
    mul r6, r3, r5                  @ r6 = total celdas (tamaño * tamaño)
    ldr r7, =nivel_dificultad       @ cargo dirección de nivel dificultad
    ldrb r0, [r7]                   @ leo ASCII nivel ('1', '2' o '3')
    sub r0, r0, #'0'                @ convierto ASCII a número (1,2 o 3)
    mov r1, #20                    @ porcentaje default 20%
    cmp r0, #2
    moveq r1, #30                  @ si nivel=2, porcentaje=30%
    cmp r0, #3
    moveq r1, #50                  @ si nivel=3, porcentaje=50%
calcular_minas:
    mov r3, r6                      @ copio total celdas a r3
    mul r2, r3, r1                  @ multiplico total_celdas * porcentaje
    mov r3, #100
    udiv r2, r2, r3                 @ divido por 100 para % final
    cmp r2, #0
    moveq r2, #1                   @ mínimo 1 mina si resultado 0
    ldr r3, =cantidad_minas
    str r2, [r3]                   @ guardo cantidad minas
    mov r0, r2                     @ paso cantidad minas en r0 para colocar
    bl colocar_minas               @ llamo a colocar minas
    b fin_calcular
fin_calcular:
    pop {r4-r7, lr}
    bx lr

@ --------------------------------------------------------
@ colocar_minas: recibe en r0 la cantidad de minas a colocar
@ Coloca minas (valor 9) en posiciones aleatorias en el tablero_actual
@ --------------------------------------------------------
colocar_minas:
    push {r4-r9, lr}           @ guardamos registros usados

    mov r1, r0                 @ r1 = cantidad de minas a colocar
    ldr r4, =valor_tamanio_tablero
    ldrb r5, [r4]              @ r5 = tamaño del tablero (8 o 12)
    mov r3, r5
    mul r6, r3, r5             @ r6 = total de celdas (tamaño * tamaño)

    ldr r7, =tablero_actual
    ldr r7, [r7]               @ r7 = puntero al tablero real

    mov r8, #0                 @ r8 = contador de minas colocadas

colocar_loop:
    cmp r8, r1                 @ ya colocamos todas las minas?
    beq fin_colocar            @ si si, terminamos

    mov r5, r6                 @ r5 = total de celdas
    bl generar_random          @ genera número aleatorio en r0

    cmp r0, r5
    bhs colocar_loop           @ si está fuera del rango, intentamos de nuevo

    mov r4, r0                 @ guardamos posición aleatoria en r4

    ldrb r11, [r7, r4]         @ leemos la celda del tablero
    cmp r11, #9
    beq colocar_loop           @ si ya hay una mina ahí, saltamos

    mov r0, r4
    bl verificar_adyacentes   @ vemos si hay minas cerca
    cmp r0, #0
    beq colocar_loop           @ si hay minas cerca, descartamos esta posición

    mov r11, #9
    strb r11, [r7, r4]         @ colocamos una mina (9) en esa celda

    add r8, r8, #1             @ sumamos una mina al contador

    ldr r3, =cantidad_minas
    ldr r3, [r3]               @ cargamos cantidad total que debemos colocar
    cmp r8, r3
    beq fin_colocar            @ si ya colocamos todas, terminamos

    b colocar_loop             @ sino, seguimos colocando

fin_colocar:
    pop {r4-r9, lr}
    bx lr

@ -------------------------------------------------------
@ generar_random: rutina simple que devuelve en r0 un número aleatorio entre 0 y máximo-1 (máximo en r5)
@ --------------------------------------------------------
generar_random:
    push {r1-r4, lr}          @ guardamos registros usados
    ldr r1, =semilla_random
    ldr r2, [r1]              @ r2 = semilla actual

    ldr r3, =const_mul
    ldr r3, [r3]              @ r3 = constante multiplicadora

    mul r0, r2, r3            @ r0 = semilla * multiplicador
    ldr r3, =const_add
    ldr r3, [r3]              @ r3 = constante a sumar

    add r0, r0, r3            @ r0 = resultado + constante
    str r0, [r1]              @ guardamos la nueva semilla actualizada
    cmp r0, #0
    blt convertir_positivo     @ si el resultado es negativo, lo hacemos positivo

numero_correcto:
    udiv r2, r0, r5           @ r2 = r0 / máximo (división entera)
    mul r3, r2, r5            @ r3 = r2 * máximo
    sub r0, r0, r3            @ r0 = resto (número aleatorio entre 0 y máximo-1)
    pop {r1-r4, lr}           @ restauramos registros
    bx lr                    

convertir_positivo:
    rsb r0, r0, #0            @ r0 = 0 - r0, convierte negativo a positivo
    b numero_correcto         @ saltamos para calcular resto

@ --------------------------------------------------------
@ verificar_adyacentes: verifica que no haya 2 o más minas adyacentes a la posición r0
@ devuelve 1 si hay menos de 2 minas adyacentes, 0 si hay 2 o más
@ --------------------------------------------------------
verificar_adyacentes:
    push {r4-r8, lr}           @ guardamos registros usados
    mov r4, r0                 @ guardamos la posición en r4
    ldr r5, =valor_tamanio_tablero
    ldrb r5, [r5]              @ cargamos tamaño del tablero en r5 (8 o 12)
    ldr r6, =tablero_actual
    ldr r6, [r6]               @ cargamos puntero al tablero en r6

    udiv r7, r4, r5            @ fila = pos / tamaño
    mul r8, r7, r5             @ fila * tamaño
    sub r8, r4, r8             @ columna = pos - (fila * tamaño)

    mov r1, #0                 @ contador minas adyacentes = 0

    cmp r7, #0                 @ si fila == 0 (primera fila)
    beq check_abajo            @ saltar a chequear abajo si es primera fila

    sub r3, r4, r5             @ posición arriba = pos - tamaño
    ldrb r2, [r6, r3]          @ cargar valor celda arriba
    cmp r2, #9                 @ comparar con 9 (mina)
    bne check_abajo            @ si no es mina saltar a abajo
    add r1, r1, #1             @ sumar mina

check_abajo:
    add r2, r7, #1             @ fila siguiente = fila + 1
    cmp r2, r5                 @ si fila siguiente >= tamaño
    bge check_izquierda        @ saltar si no hay fila abajo
    add r3, r4, r5             @ posición abajo = pos + tamaño
    ldrb r2, [r6, r3]          @ cargar celda abajo
    cmp r2, #9                 @ comparar con mina
    bne check_izquierda        @ si no mina saltar a izquierda
    add r1, r1, #1             @ sumar mina

check_izquierda:
    cmp r8, #0                 @ si columna == 0 (primera columna)
    beq check_derecha          @ saltar si no hay izquierda
    sub r3, r4, #1             @ posición izquierda = pos - 1
    ldrb r2, [r6, r3]          @ cargar celda izquierda
    cmp r2, #9                 @ comparar con mina
    bne check_derecha          @ si no mina saltar a derecha
    add r1, r1, #1             @ sumar mina

check_derecha:
    add r2, r8, #1             @ columna siguiente = columna + 1
    cmp r2, r5                 @ si columna siguiente >= tamaño
    bge verificar_resultado    @ saltar si no hay derecha
    add r3, r4, #1             @ posición derecha = pos + 1
    ldrb r2, [r6, r3]          @ cargar celda derecha
    cmp r2, #9                 @ comparar con mina
    bne verificar_resultado    @ si no mina saltar a resultado
    add r1, r1, #1             @ sumar mina

verificar_resultado:
    cmp r1, #2                 @ comparar minas adyacentes con 2
    blt sin_minas_adyacentes   @ si menos de 2 minas, válido
    mov r0, #0                 @ 2 o más minas: inválido
    b fin_verificar_adyacentes

sin_minas_adyacentes:
    mov r0, #1                 @ válido

fin_verificar_adyacentes:
    pop {r4-r8, lr}            @ restauramos registros
    bx lr

@ --------------------------------------------------------
@ mostrar_oculto: muestra el tablero oculto con filas y columnas numeradas y varia segun el juego en ejecucion
@ --------------------------------------------------------
mostrar_oculto:
    push {r4-r12, lr}                  @ guardar registros usados

    ldr r4, =valor_tamanio_tablero
    ldrb r5, [r4]                     @ cargar tamaño del tablero (8 o 12) en r5
    mul r6, r5, r5                    @ calcular total celdas = tamaño * tamaño
    mov r9, #0                        @ contador celdas empieza en 0
    ldr r8, =tablero_oculto
    ldr r8, [r8]                     @ puntero al tablero oculto en r8

    mov r10, #0                      @ contador columnas empieza en 0

    mov r0, #1
    ldr r1, =espacio_ascii
    mov r2, #1
    mov r7, #4
    swi 0                            @ imprimir espacio (para alinear encabezado)

    mov r0, #1
    ldr r1, =espacio_ascii
    mov r2, #1
    mov r7, #4
    swi 0                            @ imprimir otro espacio

    mov r0, #1
    ldr r1, =espacio_ascii
    mov r2, #1
    mov r7, #4
    swi 0                            @ imprimir un tercer espacio

imprimir_columnas:
    cmp r10, r5                      @ comparar columnas con tamaño
    bge fin_columnas                 @ si terminó, saltar fin

    add r11, r10, #1                @ calcular número columna 

    mov r1, r11
    mov r2, #10
    udiv r3, r1, r2                 @ obtener decena
    mul r4, r3, r2
    sub r4, r1, r4                  @ obtener unidad
    add r3, r3, #'0'                @ convertir decena a ASCII
    add r4, r4, #'0'                @ convertir unidad a ASCII
    ldr r1, =buffer_ascii
    strb r3, [r1]                   @ guardar decena en buffer
    strb r4, [r1, #1]               @ guardar unidad en buffer+1

    mov r0, #1
    mov r2, #2
    mov r7, #4
    swi 0                           @ imprimir número columna (2 caracteres)

    mov r0, #1
    ldr r1, =espacio_ascii
    mov r2, #1
    mov r7, #4
    swi 0                           @ imprimir espacio después número

    add r10, r10, #1                @ incrementar contador columnas
    b imprimir_columnas             @ repetir ciclo

fin_columnas:
    mov r0, #1
    ldr r1, =salto_ascii
    mov r2, #1
    mov r7, #4
    swi 0                           @ imprimir salto de línea

    mov r9, #0                      @ reiniciar contador de celdas

mostrar_oculto_loop:
    cmp r9, r6                      @ comparar contador con total celdas
    bge fin_mostrar_oculto          @ si terminó, salir

    udiv r11, r9, r5                @ fila actual = contador / tamaño
    mul r12, r11, r5                @ fila * tamaño
    cmp r9, r12
    bne mostrar_celda_oculta        @ si no es inicio fila, saltar

    add r0, r11, #1                 @ fila + 
    mov r1, r0
    mov r2, #10
    udiv r3, r1, r2                 @ decena fila
    mul r4, r3, r2
    sub r4, r1, r4                  @ unidad fila
    add r3, r3, #'0'                @ decena a ASCII
    add r4, r4, #'0'                @ unidad a ASCII
    ldr r1, =buffer_ascii
    strb r3, [r1]                   @ guardar decena en buffer
    strb r4, [r1, #1]               @ guardar unidad en buffer+1

    mov r0, #1
    mov r2, #2
    mov r7, #4
    swi 0                           @ imprimir número fila

    mov r0, #1
    ldr r1, =espacio_ascii
    mov r2, #1
    mov r7, #4
    swi 0                           @ imprimir espacio después número fila

mostrar_celda_oculta:
    mov r0, #1
    ldr r1, =espacio_ascii
    mov r2, #2
    mov r7, #4
    swi 0                           @ imprimir espacio antes celda

    ldrb r0, [r8, r9]              @ cargar caracter celda en r0

    cmp r0, #'*'                   @ si es mina '*'
    beq color_mina_roja

    cmp r0, #'#'                   @ si es número '#'
    beq color_num_verde

    cmp r0, #'0'                   @ si es '0'
    beq color_0_amarillo

    b continuar_mostrar_oculto

color_mina_roja:
    mov r0, #1
    ldr r1, =color_rojo
    mov r2, #5
    mov r7, #4
    swi 0                           @ cambiar color a rojo
    b continuar_mostrar_oculto

color_num_verde:
    mov r0, #1
    ldr r1, =color_verde
    mov r2, #5
    mov r7, #4
    swi 0                           @ cambiar color a verde
    b continuar_mostrar_oculto

color_0_amarillo:
    mov r0, #1
    ldr r1, =color_amarillo
    mov r2, #5
    mov r7, #4
    swi 0                           @ cambiar color a amarillo
    b continuar_mostrar_oculto

continuar_mostrar_oculto:
    ldrb r0, [r8, r9]              @ cargar caracter celda
    ldr r1, =buffer_ascii
    strb r0, [r1]                  @ guardar caracter en buffer

    mov r0, #1
    mov r2, #1
    mov r7, #4
    swi 0                           @ imprimir caracter celda

    mov r0, #1
    ldr r1, =color_reset
    mov r2, #4
    mov r7, #4
    swi 0                           @ resetear color

    mov r0, #1
    ldr r1, =espacio_ascii
    mov r2, #1
    mov r7, #4
    swi 0                           @ imprimir espacio después celda

    add r10, r9, #1                @ r10 = contador celdas + 1
    udiv r0, r10, r5               @ r0 = (r9+1) / tamaño (fila actual)
    mov r1, r0
    mul r0, r1, r5                @ r0 = fila * tamaño
    cmp r10, r0
    bne incrementar_contador_celdas    @ si no es fin fila, seguir

    mov r0, #1
    ldr r1, =salto_ascii
    mov r2, #1
    mov r7, #4
    swi 0                           @ imprimir salto de línea

incrementar_contador_celdas:
    add r9, r9, #1                @ incrementar contador celdas
    b mostrar_oculto_loop          @ repetir ciclo

fin_mostrar_oculto:
    mov r0, #1
    ldr r1, =salto_ascii
    mov r2, #1
    mov r7, #4
    swi 0                           @ salto de línea final

    pop {r4-r12, lr}              @ restaurar registros
    bx lr

@ --------------------------------------------------------
@ pedir_fila_columna: pide y valida fila y columna al usuario
@ Retorna en r0 la posición calculada en el tablero
@ --------------------------------------------------------
pedir_fila_columna:
    push {r4-r7, lr}                @ guardar registros usados

    ldr r4, =valor_tamanio_tablero
    ldrb r4, [r4]                   @ cargar tamaño máximo del tablero en r4 (8 o 12)

pedir_fila:
    mov r0, #1
    ldr r1, =mensaje_pedir_fila
    mov r2, #23                    @ longitud del mensaje
    mov r7, #4                     @ syscall write
    swi 0                          @ imprimir mensaje pedir fila

    mov r0, #0
    ldr r1, =buffer_entrada
    mov r2, #4                     @ máximo 3 chars + null
    mov r7, #3                     @ syscall read
    swi 0                          @ leer fila del usuario

    ldr r0, =buffer_entrada
    mov r5, #0                     @ inicializar número fila en 0

    ldrb r1, [r0]                  @ cargar primer dígito ASCII
    cmp r1, #'\n'                  @ si es enter, inválido
    beq pedir_fila                 @ repetir pedir fila
    sub r1, r1, #'0'               @ convertir ASCII a número
    cmp r1, #0
    blt pedir_fila                 @ si menor a 0, repetir
    cmp r1, #9
    bgt pedir_fila                 @ si mayor a 9, repetir
    mov r5, r1                     @ guardar primer dígito en r5

    ldrb r1, [r0, #1]              @ cargar segundo carácter
    cmp r1, #'\n'                  @ si enter, sólo un dígito
    beq validar_numero             @ ir a validar

    sub r1, r1, #'0'               @ convertir ASCII a número
    cmp r1, #0
    blt pedir_fila                 @ si inválido, repetir
    cmp r1, #9
    bgt pedir_fila                 @ si inválido, repetir

    mov r2, #10
    mul r5, r2                    @ multiplicar primer dígito por 10
    add r5, r1                    @ sumar segundo dígito

validar_numero:
    cmp r5, #1                    @ validar que fila >= 1
    blt pedir_fila                @ si menor, repetir
    cmp r5, r4                    @ validar que fila <= tamaño tablero
    bgt pedir_fila                @ si mayor, repetir
    sub r5, r5, #1                @ ajustar a índice base 0

pedir_columna:
    mov r0, #1
    ldr r1, =mensaje_pedir_columna
    mov r2, #26                   @ longitud del mensaje
    mov r7, #4                    @ syscall write
    swi 0                         @ imprimir mensaje pedir columna

    mov r0, #0
    ldr r1, =buffer_entrada
    mov r2, #4                    @ máximo 3 chars + null
    mov r7, #3                    @ syscall read
    swi 0                         @ leer columna

    ldr r0, =buffer_entrada
    mov r6, #0                    @ inicializar número columna en 0

    ldrb r1, [r0]                 @ cargar primer dígito ASCII
    cmp r1, #'\n'                 @ si enter, inválido
    beq pedir_columna             @ repetir pedir columna
    sub r1, r1, #'0'              @ convertir ASCII a número
    cmp r1, #0
    blt pedir_columna             @ si inválido, repetir
    cmp r1, #9
    bgt pedir_columna             @ si inválido, repetir
    mov r6, r1                    @ guardar primer dígito

    ldrb r1, [r0, #1]             @ cargar segundo carácter
    cmp r1, #'\n'                 @ si enter, sólo un dígito
    beq validar_numero_col        @ ir a validar

    sub r1, r1, #'0'              @ convertir ASCII a número
    cmp r1, #0
    blt pedir_columna             @ si inválido, repetir
    cmp r1, #9
    bgt pedir_columna             @ si inválido, repetir

    mov r2, #10
    mul r6, r2                    @ multiplicar primer dígito por 10
    add r6, r1                    @ sumar segundo dígito

validar_numero_col:
    cmp r6, #1                    @ validar que columna >= 1
    blt pedir_columna            @ si menor, repetir
    cmp r6, r4                    @ validar que columna <= tamaño tablero
    bgt pedir_columna            @ si mayor, repetir
    sub r6, r6, #1                @ ajustar a índice base 0

    mov r0, r5                    @ r0 = fila
    mul r0, r4                    @ r0 = fila * tamaño
    add r0, r6                    @ r0 = fila * tamaño + columna

    pop {r4-r7, lr}
    bx lr

@ --------------------------------------------------------
@ verificar_mina: verifica si hay una mina en la posición dada
@ Recibe en r0 la posición a verificar
@ Retorna en r0: 1 si hay mina, 0 si no
@ --------------------------------------------------------
verificar_mina:
    push {r4-r5, lr}        @ guardar registros usados y lr

    mov r4, r0              @ guardar posición en r4

    ldr r5, =tablero_actual @ cargar dirección del puntero al tablero real
    ldr r5, [r5]            @ cargar puntero al arreglo del tablero

    ldrb r0, [r5, r4]       @ cargar el byte en la posición r4 del tablero

    cmp r0, #9              @ comparar con el valor que indica mina (9)
    moveq r0, #1            @ si es mina, poner 1 en r0
    movne r0, #0            @ si no es mina, poner 0 en r0

    pop {r4-r5, lr}         @ restaurar registros y lr
    bx lr                   @ retornar

@ --------------------------------------------------------
@ verificar_celda_repetida: verifica si la celda ya fue revelada
@ Recibe en r0 la posición a verificar
@ Retorna en r0: 1 si ya fue revelada, 0 si no
@ --------------------------------------------------------
verificar_celda_repetida:
    push {r4-r6, lr}        @ guardo r4, r5, r6 y lr para protegerlos

    mov r4, r0              @ guardo la posición a verificar en r4

    ldr r5, =tablero_oculto @ cargo la dirección del puntero al tablero oculto
    ldr r5, [r5]            @ cargo el puntero al arreglo del tablero oculto
    ldrb r0, [r5, r4]       @ cargo el valor de la celda oculta en la posición r4

    ldr r1, =CELDA_OCULTA   @ cargo la dirección del carácter que representa celda oculta
    ldrb r1, [r1]           @ cargo el carácter que indica celda oculta

    cmp r0, r1              @ comparo si la celda está oculta
    beq celda_oculta        @ si está oculta salto a esa etiqueta

    ldr r6, =tablero_actual @ cargo dirección puntero tablero real
    ldr r6, [r6]            @ cargo puntero al arreglo del tablero real
    ldrb r0, [r6, r4]       @ cargo el valor de la celda real en esa posición
    cmp r0, #9              @ comparo si es mina
    moveq r0, #3            @ si es mina, retorno 3
    movne r0, #1            @ si no es mina, retorno 1 (revelada no mina)
    b fin_verificar         @ voy al final

celda_oculta:
    ldr r6, =tablero_actual @ cargo dirección puntero tablero real
    ldr r6, [r6]            @ cargo puntero al arreglo del tablero real
    ldrb r0, [r6, r4]       @ cargo valor de la celda real en esa posición
    cmp r0, #9              @ comparo si es mina
    moveq r0, #2            @ si es mina, retorno 2 (mina en oculta)
    movne r0, #0            @ si no es mina, retorno 0 (no revelada y no mina)

fin_verificar:
    pop {r4-r6, lr}         @ recupero registros guardados y lr
    bx lr                   @ retorno

@ --------------------------------------------------------
@ revelar_celda: revela una celda en el tablero oculto
@ Recibe en r0 la posición a revelar
@ --------------------------------------------------------
revelar_celda:
    push {r4-r6, lr}        @ guardo r4, r5, r6 y lr

    mov r4, r0              @ guardo la posición a revelar en r4

    ldr r5, =tablero_actual @ cargo la dirección del puntero al tablero real
    ldr r5, [r5]            @ cargo el puntero al arreglo del tablero real
    ldrb r6, [r5, r4]       @ cargo el valor real de la celda en r6

    cmp r6, #9              @ comparo si es mina (valor 9)
    moveq r6, #'*'          @ si es mina, lo reemplazo por '*'
    movne r6, r6            @ si no, dejo el mismo valor

    cmp r6, #'*'            @ si es '*', no convierto a ASCII
    beq guardar_valor

    add r6, r6, #'0'        @ si es un número (0-8), lo convierto a ASCII

guardar_valor:
    ldr r5, =tablero_oculto @ cargo dirección del puntero al tablero oculto
    ldr r5, [r5]            @ cargo puntero al arreglo del tablero oculto
    strb r6, [r5, r4]       @ escribo el valor ASCII en la celda correspondiente

    pop {r4-r6, lr}         @ recupero registros y lr
    bx lr                   @ retorno


@ --------------------------------------------------------
@ marcar_celda_no_mina: marca una celda adyacente segura con '#'
@ Recibe en r0 la posición a marcar
@ --------------------------------------------------------
marcar_celda_no_mina:
    push {r4, lr}
    mov r4, r0               @ guardar posición

    ldr r1, =tablero_oculto
    ldr r1, [r1]             @ puntero a tablero oculto

    mov r0, #'#'             @ carácter '#' para marcar celda segura, pero evita su uso
    strb r0, [r1, r4]        @ guardar en tablero oculto

    pop {r4, lr}
    bx lr

@ --------------------------------------------------------
@ revelar_adyacentes: revela las celdas adyacentes
@ minas se revelan con '*', las seguras con '#'
@ Recibe en r0 la posición base
@ --------------------------------------------------------
revelar_adyacentes:
    push {r4-r9, lr}         @ guardo registros a usar

    mov r4, r0               @ guardo posición base en r4

    ldr r5, =valor_tamanio_tablero
    ldrb r5, [r5]            @ r5 = tamaño del tablero (8 o 12)

    ldr r6, =tablero_actual
    ldr r6, [r6]             @ r6 = puntero a tablero real

    ldr r7, =tablero_oculto
    ldr r7, [r7]             @ r7 = puntero a tablero oculto

    udiv r8, r4, r5          @ r8 = fila (posición / tamaño)
    mul r9, r8, r5
    sub r9, r4, r9           @ r9 = columna

    cmp r8, #0
    beq verificar_abajo      @ si está en fila 0, no hay arriba

    sub r0, r4, r5           @ r0 = posición arriba
    ldrb r1, [r6, r0]        @ r1 = valor en tablero real (arriba)
    cmp r1, #9
    beq revelar_mina_arriba  @ si es mina, revelo mina arriba

    ldrb r2, [r7, r0]        @ r2 = valor en tablero oculto (arriba)
    cmp r2, #'-'
    bne verificar_abajo      @ si no está oculta, paso a abajo

    bl marcar_celda_no_mina  @ marco como celda sin mina
    b verificar_abajo

revelar_mina_arriba:
    bl revelar_celda
    b verificar_abajo

verificar_abajo:
    add r2, r8, #1
    cmp r2, r5
    bge verificar_izquierda  @ si excede tamaño, no hay abajo

    add r0, r4, r5           @ r0 = posición abajo
    ldrb r1, [r6, r0]        @ r1 = valor real
    cmp r1, #9
    beq revelar_mina_abajo

    ldrb r2, [r7, r0]
    cmp r2, #'-'
    bne verificar_izquierda

    bl marcar_celda_no_mina
    b verificar_izquierda

revelar_mina_abajo:
    bl revelar_celda
    b verificar_izquierda

verificar_izquierda:
    cmp r9, #0
    beq verificar_derecha    @ si está en primera columna, no hay izquierda

    sub r0, r4, #1
    ldrb r1, [r6, r0]        @ r1 = valor real
    cmp r1, #9
    beq revelar_mina_izquierda

    ldrb r2, [r7, r0]
    cmp r2, #'-'
    bne verificar_derecha

    bl marcar_celda_no_mina
    b verificar_derecha

revelar_mina_izquierda:
    bl revelar_celda
    b verificar_derecha

verificar_derecha:
    add r2, r9, #1
    cmp r2, r5
    bge fin_revelar_adyacentes  @ si excede tamaño, no hay derecha

    add r0, r4, #1
    ldrb r1, [r6, r0]
    cmp r1, #9
    beq revelar_mina_derecha

    ldrb r2, [r7, r0]
    cmp r2, #'-'
    bne fin_revelar_adyacentes

    bl marcar_celda_no_mina
    b fin_revelar_adyacentes

revelar_mina_derecha:
    bl revelar_celda

fin_revelar_adyacentes:
    pop {r4-r9, lr}
    bx lr

@ --------------------------------------------------------
@ inicializar_objetivo: establece cantidad de casillas a descubrir según nivel
@ --------------------------------------------------------
inicializar_objetivo:
    push {r4-r5, lr}
    
    ldr r4, =nivel_dificultad
    ldrb r4, [r4]
    sub r4, r4, #'0'       @ convertir ASCII a número
    
    mov r5, #10            @ nivel 1 = 10 casillas
    cmp r4, #2
    moveq r5, #20          @ nivel 2 = 20 casillas
    cmp r4, #3
    moveq r5, #25          @ nivel 3 = 25 casillas

    ldr r4, =casillas_objetivo
    str r5, [r4]           @ guardar objetivo
    
    ldr r4, =casillas_descubiertas
    mov r5, #0
    str r5, [r4]           @ inicializar contador

    pop {r4-r5, lr}
    bx lr
@ --------------------------------------------------------
@ ciclo_juego: maneja la lógica principal del juego
@ --------------------------------------------------------
ciclo_juego:
    push {r4-r8, lr}                       @ guardamos registros que vamos a usar

    bl inicializar_objetivo                @ inicializa la cantidad de casillas a descubrir

ciclo_principal:
    bl mostrar_oculto                      @ muestra el tablero al usuario

    @ Mostrar mensaje de casillas restantes
    mov r0, #1
    ldr r1, =mensaje_casillas_restantes
    mov r2, #35                            @ longitud del mensaje
    mov r7, #4
    swi 0

    @ Calcular casillas restantes: objetivo - descubiertas
    ldr r4, =casillas_objetivo
    ldr r4, [r4]
    ldr r5, =casillas_descubiertas
    ldr r5, [r5]
    sub r0, r4, r5                         @ r0 = casillas restantes

    @ Convertir número a ASCII de 2 dígitos
    mov r1, r0
    mov r2, #10
    udiv r3, r1, r2                        @ decenas
    mul r4, r3, r2
    sub r4, r1, r4                         @ unidades

    add r3, r3, #'0'                       @ pasar decenas a ASCII
    add r4, r4, #'0'                       @ pasar unidades a ASCII

    ldr r1, =buffer_ascii
    strb r3, [r1]
    strb r4, [r1, #1]

    @ Mostrar cantidad
    mov r0, #1
    mov r2, #2
    mov r7, #4
    swi 0

    @ Pedir jugada (fila y columna)
    bl pedir_fila_columna                 @ devuelve posición en r0
    mov r4, r0                            @ guardamos posición en r4

    @ Verificar si es una celda repetida
    bl verificar_celda_repetida
    cmp r0, #1
    beq ciclo_principal                   @ si ya estaba revelada, repetir turno

    @ Verificar si hay una mina
    mov r0, r4
    bl verificar_mina
    cmp r0, #1
    beq fin_perdido                       @ si hay mina, perdió

    @ Si no hay mina:
    mov r0, r4
    bl revelar_celda                      @ revelar el valor de esa celda

    mov r0, r4
    bl revelar_adyacentes                 @ revelar vecinos si es seguro

    @ Aumentar casillas descubiertas
    ldr r0, =casillas_descubiertas
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]

    @ Verificar si se ganó (descubiertas == objetivo)
    ldr r2, =casillas_objetivo
    ldr r2, [r2]
    cmp r1, r2
    beq fin_victoria                      @ si se llegó al objetivo, ganó

    b ciclo_principal                     @ si no, sigue jugando

@ --- Derrota ---
fin_perdido:
    mov r0, #1
    ldr r1, =color_rojo                   @ cambiar color a rojo
    mov r2, #5
    mov r7, #4
    swi 0

    mov r0, #1
    ldr r1, =mensaje_mina                 @ mensaje de derrota
    mov r2, #49
    mov r7, #4
    swi 0

    mov r0, #1
    ldr r1, =color_reset                  @ reset color
    mov r2, #4
    mov r7, #4
    swi 0
    b fin_juego_perdido                   @ va a mostrar las minas

@ --- Victoria ---
fin_victoria:
    mov r0, #1
    ldr r1, =color_verde
    mov r2, #5
    mov r7, #4
    swi 0                           @ cambiar color a verde
    
    mov r0, #1
    ldr r1, =mensaje_victoria             @ mensaje de victoria
    mov r2, #39
    mov r7, #4
    swi 0

    pop {r4-r8, lr}
    bx lr

@ --- Final después de derrota ---
fin_juego_perdido:
    pop {r4-r8, lr}
    b mostrar_minas                       @ ir a mostrar todas las minas

@ --------------------------------------------------------
@ mostrar_minas: muestra el tablero real (con minas o no)
@ Las minas se muestran con '*', las demás casillas con '-'
@ --------------------------------------------------------
mostrar_minas:
    push {r4-r8, r10-r11, lr}         @ Guardar registros de trabajo y el link register

    ldr r5, =valor_tamanio_tablero
    ldrb r5, [r5]                     @ r5 = tamaño del tablero (8 o 12)

    mul r6, r5, r5                    @ r6 = cantidad total de celdas (tamaño^2)

    mov r9, #0                        @ r9 = contador de celdas (índice del tablero)

    ldr r8, =tablero_actual
    ldr r8, [r8]                      @ r8 apunta al tablero real (con valores del juego)

mostrar_minas_loop:
    cmp r9, r6                        @ ¿Terminamos de recorrer el tablero?
    bge fin_mostrar_minas            @ Si sí, salimos del loop

    @ Resetear color antes de mostrar cada celda
    mov r0, #1
    ldr r1, =color_reset
    mov r2, #4
    mov r7, #4
    swi 0

mostrar_celda:
    ldrb r0, [r8, r9]                 @ Cargar valor de la celda actual del tablero real

    cmp r0, #9
    moveq r0, #'*'                    @ Si es una mina, mostrar '*'
    movne r0, #'-'                    @ Si no, mostrar '-'

    ldr r1, =buffer_ascii
    strb r0, [r1]                     @ Guardar el caracter a imprimir

    mov r0, #1
    mov r2, #1
    mov r7, #4
    swi 0                             @ Mostrar caracter de la celda

    @ Mostrar espacio después del carácter
    mov r0, #1
    ldr r1, =espacio_ascii
    mov r2, #1
    mov r7, #4
    swi 0

    @ Ver si llegamos al final de la fila (salto de línea)
    add r10, r9, #1         @ r10 = r9 + 1 → celda siguiente
    udiv r0, r10, r5        @ r0 = fila a la que pertenece esa celda (división entera)
    mov r1, r0              @ copiar resultado de la división
    mul r0, r1, r5          @ r0 = r1 * r5 = comienzo de esa fila
    cmp r10, r0             @ comparamos si la celda es justo el comienzo de la nueva fila
    bne continuar_mostrar_minas

    mov r0, #1
    ldr r1, =salto_ascii
    mov r2, #1
    mov r7, #4
    swi 0                             @ Salto de línea si estamos al final de la fila

continuar_mostrar_minas:
    add r9, r9, #1
    b mostrar_minas_loop             @ Pasar a la siguiente celda

fin_mostrar_minas:
    @ Resetear color y hacer un salto de línea final
    mov r0, #1
    ldr r1, =color_reset
    mov r2, #4
    mov r7, #4
    swi 0

    mov r0, #1
    ldr r1, =salto_ascii
    mov r2, #1
    mov r7, #4
    swi 0

    pop {r4-r8, r10-r11, lr}         @ Restaurar registros
    b fin                            @ Saltar a final del programa o parte posterior

@ --------------------------------------------------------
@ tomar_tiempo_final_y_guardar: toma el tiempo final y calcula duración
@ Guarda el resultado (en segundos) en tiempo_victoria
@ --------------------------------------------------------
tomar_tiempo_final_y_guardar:
    push {r0-r3, lr}           @ Guardar registros usados y dirección de retorno

    ldr r0, =tiempo_final      
    mov r7, #78                
    swi 0                      @ guarda en tiempo_final el tiempo actual

    ldr r1, =tiempo_final
    ldr r2, [r1]               @ r2 = segundos actuales (tiempo final)

    ldr r3, =tiempo_inicio
    ldr r4, [r3]               @ r4 = segundos al inicio del juego

    sub r5, r2, r4             @ r5 = tiempo total en segundos (duración del juego)

    ldr r6, =tiempo_victoria
    str r5, [r6]               @ guardar duración en tiempo_victoria

    pop {r0-r3, lr}            @ restaurar registros
    bx lr                      @ volver de la subrutina

@ --------------------------------------------------------
@ mostrar_tiempo: muestra el tiempo_victoria en consola
@ --------------------------------------------------------
mostrar_tiempo:
    push {r4-r6, lr}                   @ Guardar registros de trabajo y el link register

    mov r0, #1
    ldr r1, =mensaje_tiempo            @ Mostrar el mensaje "Tiempo: "
    mov r2, #8                         @ Longitud del mensaje
    mov r7, #4                         @ syscall write
    swi 0

    ldr r0, =tiempo_victoria           @ Cargar dirección donde se guardó el tiempo final
    ldr r0, [r0]                       @ Cargar valor de segundos en r0

    ldr r1, =buffer_ascii              @ Dirección del buffer donde voy a armar los dígitos ASCII

    mov r4, #100                       @ Dividir por 100 para obtener las centenas
    udiv r3, r0, r4                    @ r3 = cantidad de centenas

    ldr r6, =100                       @ Multiplico centenas * 100 y resto
    mul r5, r3, r6
    sub r0, r0, r5                     @ r0 queda con las decenas y unidades

    add r7, r3, #'0'                   @ Convertir centenas a ASCII
    strb r7, [r1]                      @ Guardar en buffer[0]

    mov r4, #10                        @ Dividir por 10 para obtener las decenas
    udiv r3, r0, r4                    @ r3 = cantidad de decenas

    ldr r6, =10
    mul r5, r3, r6
    sub r0, r0, r5                     @ r0 ahora queda con la unidad

    add r7, r3, #'0'                   @ Convertir decenas a ASCII
    strb r7, [r1, #1]                  @ Guardar en buffer[1]

    add r0, r0, #'0'                   @ Convertir unidades a ASCII
    strb r0, [r1, #2]                  @ Guardar en buffer[2]

    mov r0, #1
    mov r2, #3                         @ Imprimir los 3 dígitos del tiempo
    mov r7, #4
    swi 0

    mov r0, #1
    ldr r1, =mensaje_segundos          @ Mostrar la palabra " segundos"
    mov r2, #9
    mov r7, #4
    swi 0

    mov r0, #1
    ldr r1, =salto_ascii               @ Hacer un salto de línea
    mov r2, #1
    mov r7, #4
    swi 0

    pop {r4-r6, lr}                    @ Restaurar registros y volver
    bx lr

.global main
main:
    bl tomar_tiempo_inicio
    bl mostrar_mensaje_bienvenida
    bl mostrar_mensaje_info
    bl pedir_nombre
    bl ajustar_semilla_con_nombre
    bl pedir_nivel_dificultad
    bl pedir_tamanio_mapa
    bl guardar_tamanio_tablero
    bl crear_Tablero      
    bl calcular_y_colocar_minas
    bl ciclo_juego
    bl tomar_tiempo_final_y_guardar
    bl mostrar_tiempo
    b fin
fin:
    mov r7, #1      @ syscall: exit
    swi 0