; This is a basic template file for writing 48K Spectrum code.

AppFilename             equ "NewFile"                   ; What we're called (for file generation)

AppFirst                equ $8000                       ; First byte of code (uncontended memory)

                        zeusemulate "48K","ULA+"        ; Set the model and enable ULA+


; Start planting code here. (When generating a tape file we start saving from here)

                        org AppFirst                    ; Start of application

AppEntry                call setUp

;Funcion setup (se ejecuta una sola vez)
setUp                   ld a,2
                        call CHANOPEN
                        call printPala
                        call printMarcador
                        call Bucle
                        call IniciarPelota
                        call SacarPelota


;bucle infinito del juego
vloop                   call changePosPala
                        call MoverPelota




                        call delay
                        jp vloop
                        jp fin
;================== Rutinas de movimiento pala ===================
;Muestra la pala
printPala               ld de, pala
                        ld bc, 4
                        call PRINT
                        ret
;Pinta blanco donde estaba la pala
destruirPala            ld de, blanco
                        ld bc, 4
                        call PRINT
                        ret
;Mueva la posicion de la pala y llama a las funciones de borrado y pintar
changePosPala           ld a,0DFH
                        in a, (0FEH)
                        ld b,a
                        bit 0,a ; letra P
                        jp z, moverPalaDerecha ; salta si Pulso P
                        bit 1,a; letra O
                        jp z, moverPalaIzquierda ; salta si Pulso O
                        ret
moverPalaDerecha        call destruirPala  ; borra la pala
                        ld IX,blanco
                        ld A,(IX+2)
                        cp 30
                        jp z retornarPalaMov ;si la pala/blanco estan en la pos 30 no mover
                        inc A                ;cambiar la nueva posicion de la pala
                        ld (IX + 2),A
                        ld IX,pala
                        ld A,(IX+2)
                        inc A
                        ld (IX + 2),A
                        call printPala       ;mostrar la pala en la nueva pos
                        ret
moverPalaIzquierda      call destruirPala    ; borra la pala
                        ld IX,blanco
                        ld A,(IX+2)
                        cp 0
                        jp z retornarPalaMov  ;si la pala/blanco estan en la pos 0 no mover
                        dec A                  ;cambiar la nueva posicion de la pala
                        ld (IX + 2),A
                        ld IX,pala
                        ld A,(IX+2)
                        dec A
                        ld (IX + 2),A
retornarPalaMov         call printPala         ;mostrar la pala en la nueva pos
                        ret
;===========================================================================================
;===========================================================================================

; Rutina para iniciar aleatoriamente la direccion de la pelota


IniciarPelota           LD A, 10                        ; Colocar Pelota en su sitio
                        LD (Pelota+1), A                ;
                        LD A, 16                        ;
                        LD (Pelota+2), A                ;

                        LD DE, Pelota                   ; Imprime Pelota
                        LD BC, 4                        ;
                        CALL PRINT                      ;

                        CALL RandomBit                  ; Elige dir random en EjeX
                        JR C, TrueEjeX                  ;
                        LD A, -1                        ;

IniciarPelota2          LD (DirEjeX), A                 ;
                        CALL RandomBit                  ; Elige dir random en EjeY
                        JR C, TrueEjeY                  ;
                        LD A, -1                        ;
IniciarPelotaFin        LD (DirEjeY),A                  ;
                        RET                             ;


TrueEjeX                LD A, 1                         ;
                        JP IniciarPelota2               ;

TrueEjeY                LD A, 1                         ;
                        JP IniciarPelotaFin             ;

; ----------------------------------------------------------------------

; Rutina de movimiento de la pelota

MoverPelota             LD A, (Pelota+1)                ; EjeY
                        LD (BorrarPelota+1), A          ;
                        LD HL, (DirEjeX)                ;
                        ADD L                           ;
                        CP 1                            ; Si LLega al borde de arriba rebota
                        JR Z, RebotarArriba             ;
                        CP 21                           ; Si LLega al borde de abajo rebota
                        JR Z, RebotarAbajo              ;
                        LD (Pelota+1), A                ;


MoverPelotaI            LD A, (Pelota+2)                ; EjeX
                        LD (BorrarPelota+2), A          ;
                        LD HL, (DirEjeY)                ;
                        ADD L                           ;
                        CP 0                            ;
                        JR Z, RebotarDerecha                  ;
                        CP 32                           ;
                        JR Z, RebotarIzquierda                  ;
                        LD (Pelota+2), A                ;

                        LD DE, Pelota                   ; Imprime Pelota
                        LD BC, 4                        ;
                        CALL PRINT                      ;

                        LD DE, BorrarPelota             ; Borra Pelota
                        LD BC, 4                        ;
                        CALL PRINT                      ;
                        CALL printPala ; Para no borrar la pala
                        RET                             ;

RebotarArriba           LD A, 1                         ; Cambia la direccion hacia abajo, y vuelve a llamar a mover pelota
                        LD (DirEjeX), A                 ;
                        JP MoverPelota                  ;

RebotarPala             call SumarPunto
                        LD A, -1                        ; Cambia la direccion hacia arriba, y vuelve a llamar a mover pelota
                        LD (DirEjeX), A                 ;
                        JP MoverPelota                  ;

RebotarDerecha          LD A, 1                         ;
                        LD (DirEjeY), A                 ;
                        JP MoverPelotaI                  ;

RebotarIzquierda        LD A, -1                        ;
                        LD (DirEjeY), A                 ;
                        JP MoverPelotaI                  ;

; ----------------------------------------------------------------------
RebotarAbajo            LD a, (Pelota+1) ; Compara la Y de la pelota con la pala
                        LD b, a
                        LD a, (pala+1)
                        cp B
                        jp nz VidaMenos
                        LD a, (Pelota+2) ; Compara la X de la pelota con la pala
                        LD b, a
                        LD a, (pala+2)
                        cp B
                        jp nz VidaMenos
                        jp RebotarPala   ; Si da con la pala reboratPala
VidaMenos               pop BC                          ; Sacar la direcciondel Call de la pila
                                                        ;Para borrar la pelota
                        LD A, (Pelota+1)                ; EjeY
                        LD (BorrarPelota+1), A
                        LD A, (Pelota+2)                ; EjeX
                        LD (BorrarPelota+2), A
                        LD DE, BorrarPelota             ; Borra Pelota
                        LD BC, 4                        ;
                        call PRINT                      ;
                        call QuitarVida                 ;
                        call IniciarPelota              ;
                        call SacarPelota                ;
                        jp vloop                        ;
; ----------------------------------------------------------------------
; Sacar Pelota

SacarPelota             LD A, 10                        ; Colocar Pelota en su sitio
                        LD (Pelota+1), A                ;
                        LD A, 16                        ;
                        LD (Pelota+2), A                ;

                        LD DE, Pelota                   ; Imprime Pelota
                        LD BC, 4                        ;
                        CALL PRINT                      ;
                        RET                             ;
; ----------------------------------------------------------------------

; Imprimir marcadores de vida y puntos
; ----------------------------------------------------------------------
printMarcador           ld de,Puntos                    ;        Imprime el marcador superior izquierda
                        ld bc,4                         ;
                        call PRINT                      ;

                        ld de,printEspacio              ;       Imprime texto
                        ld bc,46                        ;
                        call PRINT                      ;

                        ld de,Vidas                     ;        Imprime el marcador superior derecha
                        ld bc,4                         ;
                        call PRINT                      ;
                        RET
; ----------------------------------------------------------------------

; SumarPunto
; ----------------------------------------------------------------------
  SumarPunto            LD A, (Puntos+3)                ;  Incremento de puntos
                        INC A                           ;
                        LD (Puntos+3), A                ;
                        ld de, Puntos                   ;
                        ld bc, 4                        ;
                        call PRINT                      ;
                        RET                             ;
; ----------------------------------------------------------------------

; QuitarVida
; ---------------------------------------------------------------------
  QuitarVida            LD A, (Vidas+3)                 ; Decremento de vidas
                        DEC A                           ;
                        CP '0'                          ;
                        LD (Vidas+3), A                 ;
                        JP Z, GameOver                  ; Si vidas es 0 pierde la partida
                        ld de, Vidas                    ;
                        ld bc, 4                        ;
                        call PRINT                      ;
                        RET                             ;
; ----------------------------------------------------------------------

; Game Over
; ---------------------------------------------------------------------
 GameOver               LD DE, printGameOver            ; Imprime Game Over
                        LD BC, 46                       ;
                        CALL PRINT                      ;
                        CALL Reseteo                    ;
                        JP setUp                        ;
; ----------------------------------------------------------------------

;Bucle
; ---------------------------------------------------------------------
Bucle                   LD bc, $7FFE                    ; Tiene que pular el espacio para salir del bucle
                        IN a,(C)                        ;
                        AND %01                         ;
                        JR NZ,Bucle                     ;
                        ld de,borrarEspacio             ; para quitar el texto
                        ld bc,46                        ;
                        call PRINT                      ;
                        RET                             ;
; ---------------------------------------------------------------------

; Reseteo
; ---------------------------------------------------------------------
  Reseteo               CALL Bucle                      ;   Marcadores por defecto
                        LD A, "0"                       ;
                        LD (Puntos+3), A                ;
                        LD A, "3"                       ;
                        LD (Vidas+3), A                 ;
                        RET                             ;
; ---------------------------------------------------------------------


;===========================================================================================
RandomBit               LD A,R                          ;
                        RRA                             ;
                        RET                             ;

; El retardo
delay                   ld b,5                          ; Duracion del retard0
delay0                  halt                            ; Espera una interrupcion.
                        djnz delay0                     ; salta.
                        ret                             ; return.

; Final del programa
fin                     halt                            ; Replace these lines with your code
                        jp fin                     ;


; Variables y Constantes
CHANOPEN                equ 5633
PRINT                   equ 8252
pala                    defb 22, 20, 15, "="  ; Valores por defecto
blanco                  defb 22, 20, 15, " "
semifilaControles       equ 0DFH

BorrarPelota            defb 22,10,15, " "              ;
Pelota                  defb 22,10,15, "o"              ;
printEspacio            defb 22,10,1,"PULSE LA BARRA ESPACIADORA PARA COMENZAR...";
borrarEspacio           defb 22,10,1,"                                           ";
printGameOver           defb 22,10,1,"          GAME OVER                        ";

DirEjeX                 defb 0                          ;
DirEjeY                 defb 0                          ;

Puntos                  defb 22,1,1,"0"                 ;
Vidas                   defb 22,1,31,"3"                ;
DefectoPuntos                  defb 22,1,1,"0"                 ;
DefectoVidas                   defb 22,1,31,"3"                ;






















; Stop planting code after this. (When generating a tape file we save bytes below here)
AppLast                 equ *-1                         ; The last used byte's address

; Generate some useful debugging commands

                        profile AppFirst,AppLast-AppFirst+1     ; Enable profiling for all the code

; Setup the emulation registers, so Zeus can emulate this code correctly

Zeus_PC                 equ AppEntry                            ; Tell the emulator where to start
Zeus_SP                 equ $FF40                               ; Tell the emulator where to put the stack

; These generate some output files

                        ; Generate a SZX file
                        output_szx AppFilename+".szx",$0000,AppEntry    ; The szx file

                        ; If we want a fancy loader we need to load a loading screen
;                        import_bin AppFilename+".scr",$4000            ; Load a loading screen

                        ; Now, also generate a tzx file using the loader
                        output_tzx AppFilename+".tzx",AppFilename,"",AppFirst,AppLast-AppFirst,1,AppEntry ; A tzx file using the loader


