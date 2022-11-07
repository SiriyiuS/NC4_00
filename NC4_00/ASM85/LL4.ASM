;
;
;
        .org    h'0
        mvi     A,h'80  ; Date initiale pentru deplasare
LUCRU:
        out     h'00
        RAR             ; Deplasare cu un pas
        nop
        jmp     LUCRU   ;
        .end
