; Lucrarea de laborator Nr.1
;       gr. TST181, 10.09.2020
;
        .equ    h'0040,init
        .org    h'0000
        jmp     init            ;
;        jmp     h'0040          ;

        .org    h'0040
init:
        lxi     H,h'0030        ; Incarcarea adresei in perechea HL
        mvi     A,h'0F          ; Date in registrul A
        mov     M,A             ; Inscrierea datelor in memorie pe
                                ; adresa 0030h
        nop                     ;
        hlt                     ;
        .org    h'0030          ; Rezervarea unui octet pe adresa 0030h
        .db     h'00            ; Continutul initial [M]=h'00
        .END
