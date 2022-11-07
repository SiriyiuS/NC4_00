;               Музыкальный звонок на микроконтроллере вер. 3.00       
;                                           (С) С. Тинкован 10.08.2011 
;======================================================================
        PCON    equ 087h        ;                                     ;
        F_Temp  equ 000h        ; 20.0h Флажок длительности 10 мс     ;
        F_Play  equ 001h        ; 20.1h Флажок активации Play         ;
        F_Nt_D  equ 002h        ; 20.2h Флажок звучания               ;
        F_Nt_P  equ 003h        ; 20.3h Флажок молчания               ;
        F_Legat equ 004h        ; 20.4h Флажок активации Nota_Legato  ;
        F_Pauza equ 005h        ; 20.4h Флажок активации Nota_Pauza   ;
        Ind_M_L equ R4          ; Указатель массива мелодий _L        ;
        Ind_M_H equ R5          ; Указатель массива мелодий _H        ;
        Nt_D    equ R6          ; Длитетельность звучания Nt_D        ;
        Nt_P    equ R7          ; Длительность молчания Nt_P          ;
        Ld_Nt_L equ 008h        ; Kdiv_Nt_L                           ;
        Ld_Nt_H equ 009h        ; Kdiv_Nt_H                           ;
        Ld_Fn_L equ 00Ah        ; Kdiv_Fn_L                           ;
        Ld_Fn_H equ 00Bh        ; Kdiv_Fn_H                           ;
        Ind_C_L equ 00Ch        ; Текущий указатель массива _L        ;
        Ind_C_H equ 00Dh        ; Текущий указатель массива _H        ;
        Ind_P_L equ 00Eh        ; Предыдущий указатель массива _L     ;
        Ind_P_H equ 00Fh        ; Предыдущий указатель массива _H     ;
;======================================================================
;---------------------------------------------------------------------;
        org     0000h           ; Переход на начало процедуры         ;
        ljmp    initiere        ; инициализации                       ;
        org     00Bh            ;-------------------------------------;
        ljmp    sunet           ; Подпрограмма обслуживания T/C0      ;
        org     013h            ;-------------------------------------;
        ljmp    fixare          ; Подпрограмма обслуживания INT1      ;
        org     01Bh            ;-------------------------------------;
        ajmp    durata          ; Подпрограмма обслуживания T/C1      ;
;============================++++=====================================;
sunet:  clr     TR0             ; Остановка T/C0                      ;
        mov     TL0,Ld_Fn_L     ; Загрузка Kdiv звука, byte_L         ;
        mov     TH0,Ld_Fn_H     ; Загрузка Kdiv звука, byte_H         ;
        setb    TR0             ; Запуск T/C0                         ;
        cpl     P1.7            ; Инверсия P1.7                       ;
        reti                    ; Выход из прерывания                 ;
;==========================================================++++++======
durata: clr     TR1             ; Остановка T/C1                      ;
        mov     TL1,Ld_Nt_L     ; Загрузка Kdiv темпа, byte_L         ;
        mov     TH1,Ld_Nt_H     ; Загрузка Kdiv темпа, byte_H         ;
        setb    TR1             ; Запуск T/C1                         ;
        setb    F_Temp          ; Активация флажка отсчета темпа      ;
        reti                    ; Выход из прерывания                 ;
;=========================================================+============
fixare: nop                                                          ;
        nop                                                          ;
        nop                                                          ;
        nop                                                          ;
        mov     Ind_M_L,Ind_P_L ; Запоминание предыдущего указателя  ;
        mov     Ind_M_H,Ind_P_H ; в указатель-память                 ;
        reti                    ; Возврат из прерывания              ;
;=====================================================================
initiere:
        mov     P1,#0FFh        ; Установка начального значения P1   ;
        mov     PCON,#000h      ; PCON=0
        mov     TMOD,#011h      ; Установка режима 1 для T/C0 и T/C1 ;
        mov     TCON,#005h      ; Установка INT0 и INT1 по фронту    ;
        mov     SCON,#040h      ; Установка УСАПП                    ;
        mov     IP,#01Fh        ; Установка приоритетов прерывания   ;
        mov     IE,#08Eh        ; Разрешение прерываний              ;
        mov     SP,#030h        ; Перестановка указателя стека       ;
;---------------------------------------------------------------------
        mov     020h,#000h      ; Очистка всех флажков пользователя  ;
        jnb     P3.2,iii_0      ; Проверка первой подачи напряжения  ;
        ajmp    lansare         ; 
iii_0:  mov     Ind_C_L,#0BAh   ; Задание начального адреса массива  ;
        mov     Ind_C_H,#002h   ;                                    ;
        mov     Ind_P_L,Ind_C_L ; Дублирование в предыдущем указателе;
        mov     Ind_P_H,Ind_C_H ;                                    ;
        mov     Ind_M_L,Ind_C_L ; Дублирование в запомин. Указателе  ;
        mov     Ind_M_H,Ind_C_H ;                                    ;
lansare:
        mov     Ind_P_L,Ind_C_L ; Заоминание предыдущего адреса для  ;
        mov     Ind_P_H,Ind_C_H ; повторного запуска                 ;
        jb      P3.3,Ld_NN      ; Контроль повторения мелодии:       ;
        mov     Ind_P_L,Ind_M_L ; P3.3=1, позиция Ind_C неизменна    ;
        mov     Ind_P_H,Ind_M_H ; P3.3=0, Ind_C=Ind_M                ;
        mov     Ind_C_L,Ind_P_L ;                                    ;
        mov     Ind_C_H,Ind_P_H ;                                    ;
Ld_NN:  mov     DPL,Ind_C_L     ;                                    ;
        mov     DPH,Ind_C_H     ;                                    ;

        setb    P3.4            ; Blocarea tastei "Start"            ;
        setb    F_Play          ; Активирование F_Play=1             ;
        clr     P1.6            ; Включение светодиода "Play"        ;
;=====================================================================
                                ; ### Загрузка кода ноты ###         ;
Ld_Nota:nop                     ; Проверка F_Play:                   ;
        jnb     F_Play,Ld_Nota  ;    F_Play=0, на цикл ожидания      ;
                                ;    F_Play=1, на загрузку нот       ;
        mov     DPL,Ind_C_L     ; Загрузка в in DPTR текущего адреса ;
        mov     DPH,Ind_C_H     ;                                    ;
        clr     A               ;                                    ;
        movc    A,@A+DPTR       ; Извлечение Byte_1                  ;
        mov     R2,A            ; и запись в регистр R2              ;
        clr     A               ;                                    ;
        inc     DPTR            ;                                    ;
        movc    A,@A+DPTR       ; Извлечение Byte_2                  ;
        mov     R3,A            ; и запись в регистр R3              ;
        inc     DPTR            ; позиционирование DPTR на адрес сле-;
        mov     Ind_C_L,DPL     ; дующей ноты, запоминание в регистры;
        mov     Ind_C_H,DPH     ; текущего указателя массива         ;
;---------------------------------------------------------------------
        mov     A,R2            ; ### Проверка конца мелодии ###     ;
        anl     A,#00Fh         ; Выделение битов 0000 xxxx (byte1)  ;
        cjne    A,#00Fh,Ld_Tmp  ; Сравнение с кодом "Конец мелодии"  ;
;---------------------------------------------------------------------
        mov     DPL,Ind_C_L     ; ### Проверка конца массива ###     ;
        mov     DPH,Ind_C_H     ; Проверка двух байт подряд на       ;
        clr     A               ; наличие кода FFh                   ;
        movc    A,@A+DPTR       ;                                    ;
        cjne    A,#0FFh,Ld_N0   ; Первый байт= FFh?                  ;
        clr     A               ;  да, проверка второго байта        ;
        inc     DPTR            ;                                    ;
        movc    A,@A+DPTR       ;                                    ;
        cjne    A,#0FFh,Ld_N0   ; Второй байт= FFh?                  ;
        mov     Ind_C_L,#0BAh   ;  да, загрузка начального значения  ;
        mov     Ind_C_H,#002h   ;      указателя массива             ;
Ld_N0:
        mov     020h,#000h      ; Очистка флажков пользователя       ;
        mov     P1,#0FFh        ; Остановка звука и индикации        ;

        clr     P3.4            ; Deblocarea tastei "Start"          ;

        clr     TR0             ; Остановка таймера-счетчика T/C0    ;
        clr     TR1             ; Остановка таймера-счетчика T/C1    ;
        mov     PCON,#003h      ; Перевод в режим микропотребления   ;
        ajmp    Ld_Nota         ; Переход на процедуру загрузки ноты ;
;---------------------------------------------------------------------
Ld_Tmp: mov     A,R2            ; ### Загрузка темпа мелодии ###     ;
        anl     A,#0F0h         ; Выделение битов 4...7 первого байта;
        swap    A               ; Перестановка тетрад и сдвиг влево  ;
        rl      A               ; на один разряд                     ;
        push    Acc             ; Запоминание аккумулятора в стеке   ;
        mov     DPTR,#0220h     ; Загрузка начала таблицы ТЕМР в DPTR;
        movc    A,@A+DPTR       ; Извлечение из таблицы Ld_Nt_L      ;
        mov     Ld_Nt_L,A       ; и запоминание в ОЗУ                ;
        pop     Acc             ; Востановление аккумулятора из стека;
        inc     A               ; Следующая ячейка таблицы           ;
        movc    A,@A+DPTR       ; Извлечение из таблицы Ld_Nt_H      ;
        mov     Ld_Nt_H,A       ; и запоминание в ОЗУ                ;
;---------------------------------------------------------------------
Ld_Drt: mov     DPTR,#01A0h     ; ### Загрузка звучания и молчания ###
        mov     A,R2            ; Образование смещения из битов 0...3;
        anl     A,#00Fh         ; первого байта и битов 6,7 второго  ;
                                ; байта:                             ;
                                ;    0000 xxxx                       ;
        rl      A               ;    000x xxx0                       ;
        rl      A               ;    00xx xx00                       ;
        rl      A               ;    0xxx x000                       ;
        mov     R1,A            ; Временое запоминание промежуточного;
        mov     A,R3            ; значения.                          ;
        anl     A,#0C0h         ;    yy00 0000                       ;
        rl      A               ;    y000 000y                       ;
        rl      A               ;    0000 00yy                       ;
        rl      A               ;    0000 0yy0                       ;
        orl     A,R1            ;    0xxx xyyL                       ;
        push    Acc             ; Запоминание смещения в стеке       ;
        movc    A,@A+DPTR       ; Извлечение из таблицы значения Nt_D;
        mov     Nt_D,A          ; и запоминание в ОЗУ                ;
        pop     Acc             ; Восстановление смещения из стека   ;
        inc     A               ; и перевод на следующую ячейку      ;
        movc    A,@A+DPTR       ; Извлечение из таблицы значения Nt_P;
        mov     Nt_P,A          ; и запоминание в ОЗУ                ;
;---------------------------------------------------------------------
;                                 ### Загрузка Kdiv частоты ноты ### ;
Ld_Frc: mov     DPTR,#0240h     ; Загрузка начала таблицы в DPTR     ;
        mov     A,R3            ;                                    ;
        anl     A,#03Fh         ; Выделение битов 0...5 второго байта;
        rl      A               ; и сдвиг влево на один разряд       ;
        push    Acc             ; Запоминание смещения в стеке       ;
        movc    A,@A+DPTR       ; Извлечение Kdiv_L и запись значения;
        mov     Ld_Fn_L,A       ; Ld_Fn_L в ОЗУ                      ;
        pop     Acc             ; Восстановление смещения из стека и ;
        inc     A               ; перевод на следующую ячейку        ;
        movc    A,@A+DPTR       ; Извлечение из таблицы Kdiv_H и     ;
        mov     Ld_Fn_H,A       ; запись значения Ld_Fn_H в ОЗУ      ;
        mov     TL0,Ld_Fn_L     ; Загрузка в C/T0 Kdiv_L из ОЗУ      ;
        mov     TH0,Ld_Fn_H     ; Загрузка в C/T0 Kdiv_H из ОЗУ      ;
        mov     TL1,Ld_Nt_L     ; Загрузка в C/T1 длительности Nt_L  ;
        mov     TH1,Ld_Nt_H     ; Загрузка в C/T1 длительности Nt_H  ;
;---------------------------------------------------------------------
set_F:  anl     020h,#002h      ; Очистка всех флажков кроме F_Play  ;
        mov     A,R3            ;                                    ;
        anl     A,#0C0h         ;                                    ;
        cjne    A,#000h,set_F1  ; Анализ кода "Pauza"                ;
        setb    F_Nt_P          ; Активация F_Nt_P                   ;
        setb    F_Pauza         ; Активация F_Pauza                  ;
        ajmp    set_TR          ;                                    ;
set_F1: cjne    A,#040h,set_F2  ; Анализ кода "Legatto"              ;
        setb    F_Nt_D          ; Активация F_Nt_D                   ;
        setb    F_Legat         ; Активация F_Legat                  ;
        ajmp    set_TR          ;                                    ;
set_F2: cjne    A,#080h,set_F3  ; Анализ кода "Non Legatto"          ;
set_F4: setb    F_Nt_D          ; Активация F_Nt_D                   ;
        setb    F_Nt_P          ; Активация F_Nt_ P                  ;
        ajmp    set_TR          ;                                    ;
Set_F3: cjne    A,#0C0h,Set_F6  ; Анализ кода "Stacatto"             ;
        ajmp    set_F4          ;                                    ;
set_F6: mov     020h,#000h      ; Если тип ноты не опознан, то оста- ;
        mov     P1,#0FFh        ; новка звука и индикации и переход  ;
        ajmp    Ld_Nota         ; на загрузку ноты                   ;
set_TR: setb    TR1             ; Запуск   C/T1                      ;
        clr     F_Temp          ; Очистка F_Temp                     ;
        jnb     F_Legat,set_F5  ; Проверка F_Legat                   ;
        setb    TR0             ; Запуск   C/T0                      ;
set_F5: jnb     F_Nt_D,set_DP   ; Проверка F_Nt_D                    ;
        setb    TR0             ;                                    ;
set_DP: nop                     ;                                    ;
;=====================================================================
;       ###     Цикл Проигрывания ноты    ###                        ;
;---------------------------------------------------------------------
        jb      F_Pauza,lucr_D0 ; ### Цикл Звучание ноты ###         ;
lucr_D: nop                     ;                                    ;
        jnb     F_Nt_D,lucr_D   ; Прверка   F_Nt_D=1: нет, ожидание  ;
                                ;                     да, продолжение;
        jnb     F_Temp,lucr_D   ; Проверка  F_Temp=1: нет, ожидание  ;
                                ;                     да, продолжение;
        dec     Nt_D            ; Декремент и проверка   Nt_D        ;
        clr     F_Temp          ;                                    ;
        cjne    Nt_D,#0FFh,Lucr_D; Проверка Nt_D<0:   да, ожидание   ;
lucr_D0:                        ;                    нет, продолжение;
        clr     F_Nt_D          ; Очистка     F_Nt_D                 ;
        clr     TR0             ; Остановка T/C0                     ;
        setb    P1.7            ; Блокировка формирования звука      ;
;--------------------------------------------------------------------;
        jb      F_Legat,lucr_P0 ; ### Цикл молчание ноты ###         ;
lucr_P: nop                     ;                                    ;
        jnb     F_Nt_P,lucr_P   ; Проверка F_Nt_P=1: нет, ожидание   ;
                                ;                     да, продолжение;
        jnb     F_Temp,lucr_P   ; Проверка F_Temp=1: нет, ожиданиеe  ;
                                ;                     да, продолжение;
        dec     Nt_P            ; Декремент и проверка   Nt_P        ;
        clr     F_Temp          ;                                    ;
        cjne    Nt_P,#0FFh,Lucr_P; Проверка Nt_P<0:   да, ожидание   ;
lucr_P0:                        ;                    нет, продолжение;
        anl     020h,#002h      ; Очистка всех флажков пользователя  ;
        clr     TR1             ; за исключением F_Play              ;
        ajmp    Ld_Nota         ; Переход на загрузку ноты           ;
;=====================================================================
        org     01A0h           ; ТАБЛИЦА ДЛИТЕЛЬНОСТИ НОТЫ          ;
                                ; ####  1/1                          ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      080h            ; 00 1 pauza     Nt_P                ;
        db      080h            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      070h            ; 10 0 nonlegato Nt_D                ;
        db      010h            ; 10 1 nonlegato Nt_P                ;
        db      060h            ; 11 0 stakatto  Nt_D                ;
        db      020h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/2* (3/4)                   ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      060h            ; 00 1 pauza     Nt_P                ;
        db      060h            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      054h            ; 10 0 nonlegato Nt_D                ;
        db      00Ch            ; 10 1 nonlegato Nt_P                ;
        db      048h            ; 11 0 stakatto  Nt_D                ;
        db      018h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/2  (2/4)                   ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      040h            ; 00 1 pauza     Nt_P                ;
        db      040h            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      038h            ; 10 0 nonlegato Nt_D                ;
        db      008h            ; 10 1 nonlegato Nt_P                ;
        db      030h            ; 11 0 stakatto  Nt_D                ;
        db      010h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/4* (3/8)                   ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      030h            ; 00 1 pauza     Nt_P                ;
        db      030h            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      02Ah            ; 10 0 nonlegato Nt_D                ;
        db      006h            ; 10 1 nonlegato Nt_P                ;
        db      024h            ; 11 0 stakatto  Nt_D                ;
        db      00Ch            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/3* (1/1 triol)             ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      02Bh            ; 00 1 pauza     Nt_P                ;
        db      02Bh            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      025h            ; 10 0 nonlegato Nt_D                ;
        db      005h            ; 10 1 nonlegato Nt_P                ;
        db      020h            ; 11 0 stakatto  Nt_D                ;
        db      00Ah            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/4  (2/8)                   ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      020h            ; 00 1 pauza     Nt_P                ;
        db      020h            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      01Ch            ; 10 0 nonlegato Nt_D                ;
        db      004h            ; 10 1 nonlegato Nt_P                ;
        db      018h            ; 11 0 stakatto  Nt_D                ;
        db      008h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/8* (3/16)                  ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      018h            ; 00 1 pauza     Nt_P                ;
        db      018h            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      015h            ; 10 0 nonlegato Nt_D                ;
        db      003h            ; 10 1 nonlegato Nt_P                ;
        db      012h            ; 11 0 stakatto  Nt_D                ;
        db      006h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/6  (1/2 triol)             ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      015h            ; 00 1 pauza     Nt_P                ;
        db      015h            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      012h            ; 10 0 nonlegato Nt_D                ;
        db      002h            ; 10 1 nonlegato Nt_P                ;
        db      00Fh            ; 11 0 stakatto  Nt_D                ;
        db      005h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/8  (2/16)                  ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      010h            ; 00 1 pauza     Nt_P                ;
        db      010h            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      00Eh            ; 10 0 nonlegato Nt_D                ;
        db      002h            ; 10 1 nonlegato Nt_P                ;
        db      00Ch            ; 11 0 stakatto  Nt_D                ;
        db      004h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/16*(3/32)                  ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      00Ch            ; 00 1 pauza     Nt_P                ;
        db      00Ch            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      00Ah            ; 10 0 nonlegato Nt_D                ;
        db      001h            ; 10 1 nonlegato Nt_P                ;
        db      009h            ; 11 0 stakatto  Nt_D                ;
        db      003h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/12 (1/4 triol)             ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      00Ah            ; 00 1 pauza     Nt_P                ;
        db      00Ah            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      008h            ; 10 0 nonlegato Nt_D                ;
        db      001h            ; 10 1 nonlegato Nt_P                ;
        db      007h            ; 11 0 stakatto  Nt_D                ;
        db      002h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/16 (2/32)                  ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      008h            ; 00 1 pauza     Nt_P                ;
        db      008h            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      007h            ; 10 0 nonlegato Nt_D                ;
        db      001h            ; 10 1 nonlegato Nt_P                ;
        db      006h            ; 11 0 stakatto  Nt_D                ;
        db      002h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/32*(3/64)                  ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      006h            ; 00 1 pauza     Nt_P                ;
        db      006h            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      007h            ; 10 0 nonlegato Nt_D                ;
        db      001h            ; 10 1 nonlegato Nt_P                ;
        db      005h            ; 11 0 stakatto  Nt_D                ;
        db      001h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/24 (1/8 triol)             ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      005h            ; 00 1 pauza     Nt_P                ;
        db      005h            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      004h            ; 10 0 nonlegato Nt_D                ;
        db      001h            ; 10 1 nonlegato Nt_P                ;
        db      004h            ; 11 0 stakatto  Nt_D                ;
        db      001h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/32 (2/64)                  ;
        db      000h            ; 00 0 pauza     Nt_D                ;
        db      004h            ; 00 1 pauza     Nt_P                ;
        db      004h            ; 01 0 legato    Nt_D                ;
        db      000h            ; 01 1 legato    Nt_P                ;
        db      003h            ; 10 0 nonlegato Nt_D                ;
        db      001h            ; 10 1 nonlegato Nt_P                ;
        db      003h            ; 11 0 stakatto  Nt_D                ;
        db      001h            ; 11 1 stakatto  Nt_P                ;
                                ; ####  1/64                         ;
        db      000h            ; 00 0 pauza     Nt_D               ?;
        db      002h            ; 00 1 pauza     Nt_P               ?;
        db      002h            ; 01 0 legato    Nt_D               ?;
        db      000h            ; 01 1 legato    Nt_P               ?;
        db      001h            ; 10 0 nonlegato Nt_D               ?;
        db      001h            ; 10 1 nonlegato Nt_P               ?;
        db      001h            ; 11 0 stakatto  Nt_D               ?;
        db      001h            ; 11 1 stakatto  Nt_P               ?;
;---------------------------------------------------------------------
        org     0220h           ; ТАЛИЦА ТЕМПА МЕЛОДИИ               ;
        db      0AEh            ;  45    byte_L                      ;
        db      05Dh            ;  1,33s byte_H                      ;
        db      0F6h            ;  60    byte_L                      ;
        db      085h            ;  1,00s byte_H                      ;
        db      060h            ;  75    byte_L                      ;
        db      09Eh            ;  0,80s byte_H                      ;
        db      07Bh            ;  80    byte_L                      ;
        db      0A4h            ;  0,74s byte_H                      ;
        db      03Fh            ;  90    byte_L                      ;
        db      0AEh            ;  0,67s byte_H                      ;
        db      074h            ;  105   byte_L                      ;
        db      0BAh            ;  0,57s byte_H                      ;
        db      0C7h            ;  120   byte_L                      ;
        db      0C1h            ;  0,50s byte_H                      ;
        db      052h            ;  135   byte_L                      ;
        db      0CAh            ;  0,44s byte_H                      ;
        db      0B7h            ;  140   byte_L                      ;
        db      0CBh            ;  0,42s byte_H                      ;
        db      034h            ;  150   byte_L                      ;
        db      0CFh            ;  0,40s byte_H                      ;
        db      099h            ;  165   byte_L                      ;
        db      0D3h            ;  0,36s byte_H                      ;
        db      062h            ;  180   byte_L                      ;
        db      0D7h            ;  0,33s byte_H                      ;
        db      078h            ;  195   byte_L                      ;
        db      0DAh            ;  0,31s byte_H                      ;
        db      028h            ;  210   byte_L                      ;
        db      0DDh            ;  0,29s byte_H                      ;
        db      07Ah            ;  225   byte_L                      ;
        db      0DFh            ;  0,27s byte_H                      ;
        db      084h            ;  240   byte_L                      ;
        db      0E1h            ;  0,25s byte_H                      ;
;---------------------------------------------------------------------
        org     0240h           ; ТАБЛИЦА ЧАСТОТ НОТЫr               ;
        db      02Ch            ; Do (K) byte_L  0                   ;
        db      0E2h            ;        byte_H                      ;
        db      0D9h            ; Do#(K) byte_L  1                   ;
        db      0E3h            ;        byte_H                      ;
        db      06Eh            ; Re (K) byte_L  2                   ;
        db      0E5h            ;        byte_H                      ;
        db      0ECh            ; Re#(K) byte_L  3                   ;
        db      0E6h            ;        byte_H                      ;
        db      055h            ; Mi (K) byte_L  4                   ;
        db      0E8h            ;        byte_H                      ;
        db      0A9h            ; Fa (K) byte_L  5                   ;
        db      0E9h            ;        byte_H                      ;
        db      0EBh            ; Fa#(K) byte_L  6                   ;
        db      0EAh            ;        byte_H                      ;
        db      019h            ; Sol(K) byte_L  7                   ;
        db      0ECh            ;        byte_H                      ;
        db      038h            ; Sol#K) byte_L  8                   ;
        db      0EDh            ;        byte_H                      ;
        db      047h            ; La (K) byte_L  9                   ;
        db      0EEh            ;        byte_H                      ;
        db      046h            ; La#(K) byte_L  A                   ;
        db      0EFh            ;        byte_H                      ;
        db      036h            ; Si (K) byte_L  B                   ;
        db      0F0h            ;        byte_H                      ;
        db      01Ah            ; Do (M) byte_L  C                   ;
        db      0F1h            ;        byte_H                      ;
        db      0F0h            ; Do#(M) byte_L  D                   ;
        db      0F1h            ;        byte_H                      ;
        db      0BBh            ; Re (M) byte_L  E                   ;
        db      0F2h            ;        byte_H                      ;
        db      07Ah            ; Re#(M) byte_L  F                   ;
        db      0F3h            ;        byte_H                      ;
        db      02Eh            ; Mi (M) byte_L  10                  ;
        db      0F4h            ;        byte_H                      ;
        db      0D9h            ; Fa (M) byte_L  11                  ;
        db      0F4h            ;        byte_H                      ;
        db      079h            ; Fa#(M) byte_L  12                  ;
        db      0F5h            ;        byte_H                      ;
        db      011h            ; Sol(M) byte_L  13                  ;
        db      0F6h            ;        byte_H                      ;
        db      0A0h            ; Sol#M) byte_L  14                  ;
        db      0F6h            ;        byte_H                      ;
        db      027h            ; La (M) byte_L  15                  ;
        db      0F7h            ;        byte_H                      ;
        db      0A7h            ; La#(M) byte_L  16                  ;
        db      0F7h            ;        byte_H                      ;
        db      01Fh            ; Si (M) byte_L  17                  ;
        db      0F8h            ;        byte_H                      ;
        db      091h            ; Do (1) byte_L  18                  ;
        db      0F8h            ;        byte_H                      ;
        db      0FCh            ; Do#(1) byte_L  19                  ;
        db      0F8h            ;        byte_H                      ;
        db      061h            ; Re (1) byte_L  1A                  ;
        db      0F9h            ;        byte_H                      ;
        db      0C1h            ; Re#(1) byte_L  1B                  ;
        db      0F9h            ;        byte_H                      ;
        db      01Bh            ; Mi (1) byte_L  1C                  ;
        db      0FAh            ;        byte_H                      ;
        db      070h            ; Fa (1) byte_L  1D                  ;
        db      0FAh            ;        byte_H                      ;
        db      0C1h            ; Fa#(1) byte_L  1E                  ;
        db      0FAh            ;        byte_H                      ;
        db      00Ch            ; Sol(1) byte_L  1F                  ;
        db      0FBh            ;        byte_H                      ;
        db      054h            ; Sol#1) byte_L  20                  ;
        db      0FBh            ;        byte_H                      ;
        db      098h            ; La (1) byte_L  21                  ;
        db      0FBh            ;        byte_H                      ;
        db      0D7h            ; La#(1) byte_L  22                  ;
        db      0FBh            ;        byte_H                      ;
        db      014h            ; Si (1) byte_L  23                  ;
        db      0FCh            ;        byte_H                      ;
        db      04Ch            ; Do (2) byte_L  24                  ;
        db      0FCh            ;        byte_H                      ;
        db      082h            ; Do#(2) byte_L  25                  ;
        db      0FCh            ;        byte_H                      ;
        db      0B5h            ; Re (2) byte_L  26                  ;
        db      0FCh            ;        byte_H                      ;
        db      0E4h            ; Re#(2) byte_L  27                  ;
        db      0FCh            ;        byte_H                      ;
        db      012h            ; Mi (2) byte_L  28                  ;
        db      0FDh            ;        byte_H                      ;
        db      03Ch            ; Fa (2) byte_L  29                  ;
        db      0FDh            ;        byte_H                      ;
        db      064h            ; Fa#(2) byte_L  2A                  ;
        db      0FDh            ;        byte_H                      ;
        db      08Ah            ; Sol(2) byte_L  2B                  ;
        db      0FDh            ;        byte_H                      ;
        db      0AEh            ; Sol#2) byte_L  2C                  ;
        db      0FDh            ;        byte_H                      ;
        db      0D0h            ; La (2) byte_L  2D                  ;
        db      0FDh            ;        byte_H                      ;
        db      0F0h            ; La#(2) byte_L  2E                  ;
        db      0FDh            ;        byte_H                      ;
        db      00Eh            ; Si (2) byte_L  2F                  ;
        db      0FEh            ;        byte_H                      ;
        db      02Ah            ; Do (3) byte_L  30                  ;
        db      0FEh            ;        byte_H                      ;
        db      045h            ; Do#(3) byte_L  31                  ;
        db      0FEh            ;        byte_H                      ;
        db      05Fh            ; Re (3) byte_L  32                  ;
        db      0FEh            ;        byte_H                      ;
        db      076h            ; Re#(3) byte_L  33                  ;
        db      0FEh            ;        byte_H                      ;
        db      08Ch            ; Mi (3) byte_L  34                  ;
        db      0FEh            ;        byte_H                      ;
        db      0A2h            ; Fa (3) byte_L  35                  ;
        db      0FEh            ;        byte_H                      ;
        db      0B6h            ; Fa#(3) byte_L  36                  ;
        db      0FEh            ;        byte_H                      ;
        db      0C9h            ; Sol(3) byte_L  37                  ;
        db      0FEh            ;        byte_H                      ;
        db      0DBh            ; Sol#3) byte_L  38                  ;
        db      0FEh            ;        byte_H                      ;
        db      0ECh            ; La (3) byte_L  39                  ;
        db      0FEh            ;        byte_H                      ;
        db      0FCh            ; La#(3) byte_L  3A                  ;
        db      0FEh            ;        byte_H                      ;
        db      00Bh            ; Si (3) byte_L  3B                  ;
        db      0FFh            ;        byte_H                      ;
        db      017h            ; Do (4) byte_L  3C                  ;
        db      0FFh            ;        byte_H                      ;
;=====================================================================
        org     02BAh           ; МАССИВ МЕЛОДИЙ                     ;
;---------------------------------------------------------------------
; *** П. Мориа. Aloette (Жаворонок) ****
        db      05Ah            ; 1/12
        db      000h            ; Pauza    L
        db      05Ah            ; 1/14
        db      0AAh            ; Fa#  (2) N
        db      05Ah            ; 1/14
        db      0A8h            ; Mi   (2) N
        db      05Ah            ; 1/14
        db      0A6h            ; Re   (2) N
        db      05Ah            ; 1/14
        db      0A8h            ; Mi   (2) N
        db      05Ah            ; 1/14
        db      0AAh            ; Fa#  (2) N
        db      05Ah            ; 1/12
        db      06Ah            ; Fa#  (2) L
        db      05Ah            ; 1/14
        db      0AAh            ; Fa#  (2) N
        db      05Ah            ; 1/12
        db      06Bh            ; Sol  (2) L
        db      05Ah            ; 1/14
        db      0ABh            ; Sol  (2) N
        db      05Ah            ; 1/12
        db      000h            ; Pauza    L
        db      05Ah            ; 1/14
        db      0A6h            ; Re   (2) N
        db      058h            ; 1/9
        db      0A6h            ; Re   (2) N
        db      058h            ; 1/8
        db      065h            ; Do#  (2) L
        db      058h            ; 1/9
        db      0A5h            ; Do#  (2) N
        db      058h            ; 1/8
        db      06Ah            ; Fa#  (2) L
        db      052h            ; 1/2
        db      06Ah            ; Fa#  (2) L
        db      05Bh            ; 1/16
        db      000h            ; Pauza    L
        db      05Ah            ; 1/12
        db      000h            ; Pauza    L
        db      05Ah            ; 1/12
        db      066h            ; Re   (2) L
        db      05Ah            ; 1/12
        db      065h            ; Do#  (2) L
        db      05Ah            ; 1/12
        db      063h            ; Si   (1) L
        db      05Ah            ; 1/12
        db      065h            ; Do#  (2) L
        db      05Ah            ; 1/14
        db      0A6h            ; Re   (2) N
        db      05Ah            ; 1/12
        db      066h            ; Re   (2) L
        db      05Ah            ; 1/14
        db      0A6h            ; Re   (2) N
        db      05Ah            ; 1/12
        db      068h            ; Mi   (2) L
        db      05Ah            ; 1/14
        db      0A8h            ; Mi   (2) N
        db      05Ah            ; 1/12
        db      000h            ; Pauza    L
        db      05Ah            ; 1/14
        db      0A3h            ; Si   (1) N
        db      058h            ; 1/9
        db      0A3h            ; Si   (1) N
        db      058h            ; 1/8
        db      062h            ; La#  (1) L
        db      058h            ; 1/9
        db      0A2h            ; La#  (1) N
        db      058h            ; 1/8
        db      05Eh            ; Fa#  (1) L
        db      052h            ; 1/2
        db      05Eh            ; Fa#  (1) L
        db      05Fh            ; Tempou= 90
        db      05Eh            ; Melody END
;
;---------------------------------------------------------------------
; *** И. С. Бах. Шутка ****
        db      088h            ; 1/08 Sd 1/11
        db      0F2h            ; Re   (3) S
        db      08Bh            ; 1/16  L 1/16
        db      075h            ; Fa   (3) L
        db      08Bh            ; 1/16  L 1/16
        db      072h            ; Re   (3) L
        db      088h            ; 1/08 Sd 1/11
        db      0EDh            ; La   (2) S
        db      08Bh            ; 1/16  L 1/16
        db      072h            ; Re   (3) L
        db      08Bh            ; 1/16  L 1/16
        db      06Dh            ; La   (2) L
        db      088h            ; 1/08 Sd 1/11
        db      0E9h            ; Fa   (2) S
        db      08Bh            ; 1/16  L 1/16
        db      06Dh            ; La   (2) L
        db      08Bh            ; 1/16  L 1/16
        db      069h            ; Fa   (2) L
        db      085h            ; 1/04 Nd 1/5
        db      0A6h            ; Re   (2) N
        db      08Bh            ; 1/16  L 1/16
        db      061h            ; La   (1) L
        db      08Bh            ; 1/16  L 1/16
        db      066h            ; Re   (2) L
        db      08Bh            ; 1/16  L 1/16
        db      069h            ; Fa   (2) L
        db      08Bh            ; 1/16  L 1/16
        db      066h            ; Re   (2) L
        db      08Bh            ; 1/16  L 1/16
        db      068h            ; Mi   (2) L
        db      08Bh            ; 1/16  L 1/16
        db      066h            ; Re   (2) L
        db      08Bh            ; 1/16  L 1/16
        db      068h            ; Mi   (2) L
        db      08Bh            ; 1/16  L 1/16
        db      066h            ; Re   (2) L
        db      08Bh            ; 1/16  L 1/16
        db      065h            ; Do#  (2) L
        db      08Bh            ; 1/16  L 1/16
        db      068h            ; Mi   (2) L
        db      08Bh            ; 1/16  L 1/16
        db      06Bh            ; Sol  (2) L
        db      08Bh            ; 1/16  L 1/16
        db      068h            ; Mi   (2) L
        db      088h            ; 1/08 Sd 1/11
        db      0E9h            ; Fa   (2) S
        db      088h            ; 1/08 Sd 1/11
        db      0E6h            ; Re   (2) S
        db      088h            ; 1/08 Sd 1/11
        db      0F2h            ; Re   (3) S
        db      08Bh            ; 1/16  L 1/16
        db      075h            ; Fa   (3) L
        db      08Bh            ; 1/16  L 1/16
        db      072h            ; Re   (3) L
        db      088h            ; 1/08 Sd 1/11
        db      0EDh            ; La   (2) S
        db      08Bh            ; 1/16  L 1/16
        db      072h            ; Re   (3) L
        db      08Bh            ; 1/16  L 1/16
        db      06Dh            ; La   (2) L
        db      088h            ; 1/08 Sd 1/11
        db      0E9h            ; Fa   (2) S
        db      08Bh            ; 1/16  L 1/16
        db      06Dh            ; La   (2) L
        db      08Bh            ; 1/16  L 1/16
        db      069h            ; Fa   (2) L
        db      085h            ; 1/04 Nd 1/5
        db      0A6h            ; Re   (2) N
        db      08Fh            ; Tempou= 140
        db      0A6h            ; Melody END
;
;---------------------------------------------------------------------
; *** Бокерини. Менуэт ****
        db      03Bh            ; 1/16  L 1/16
        db      06Dh            ; La   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      06Ch            ; Sol# (2) L
        db      03Bh            ; 1/16  L 1/16
        db      06Dh            ; La   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      06Fh            ; Si   (2) L
        db      038h            ; 1/08  L 1/8
        db      06Dh            ; La   (2) L
        db      035h            ; 1/04 Nd 1/5
        db      0A1h            ; La   (1) N
        db      038h            ; 1/08  L 1/8
        db      065h            ; Do#  (2) L
        db      038h            ; 1/08 Sd 1/11
        db      0E5h            ; Do#  (2) S
        db      038h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) N
        db      038h            ; 1/08  L 1/8
        db      068h            ; Mi   (2) L
        db      038h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) N
        db      035h            ; 1/04 Nd 1/5
        db      0A6h            ; Re   (2) N
        db      03Bh            ; 1/16  L 1/16
        db      066h            ; Re   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      065h            ; Do#  (2) L
        db      03Bh            ; 1/16  L 1/16
        db      066h            ; Re   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      068h            ; Mi   (2) L
        db      038h            ; 1/08  L 1/8
        db      066h            ; Re   (2) L
        db      035h            ; 1/04 Nd 1/5
        db      09Ch            ; Mi   (1) N
        db      038h            ; 1/08  L 1/8
        db      063h            ; Si   (1) L
        db      038h            ; 1/08 Sd 1/11
        db      0E3h            ; Si   (1) S
        db      038h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) N
        db      038h            ; 1/08  L 1/8
        db      066h            ; Re   (2) L
        db      038h            ; 1/08  L 1/8
        db      065h            ; Do#  (2) L
        db      038h            ; 1/08  L 1/4
        db      065h            ; Do#  (2) L
        db      03Fh            ; Tempou= 80
        db      065h            ; Melody END
;---------------------------------------------------------------------
; *** Л. Бетховен. Fur Elsa ****
        db      03Bh            ; 1/16  L 1/16
        db      068h            ; Mi   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      067h            ; Re#  (2) L
        db      03Bh            ; 1/16  L 1/16
        db      068h            ; Mi   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      067h            ; Re#  (2) L
        db      03Bh            ; 1/16  L 1/16
        db      068h            ; Mi   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      063h            ; Si   (1) L
        db      03Bh            ; 1/16  L 1/16
        db      066h            ; Re   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      064h            ; Do   (2) L
        db      038h            ; 1/08  L 1/8
        db      061h            ; La   (1) L
        db      03Bh            ; 1/16  P 1/16
        db      000h            ; Pauza    P
        db      03Bh            ; 1/16  L 1/16
        db      058h            ; Do   (1) L
        db      03Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      03Bh            ; 1/16  L 1/16
        db      061h            ; La   (1) L
        db      038h            ; 1/08  L 1/8
        db      063h            ; Si   (1) L
        db      03Bh            ; 1/16  P 1/16
        db      000h            ; Pauza    P
        db      03Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      03Bh            ; 1/16  L 1/16
        db      060h            ; Sol# (1) L
        db      03Bh            ; 1/16  L 1/16
        db      061h            ; La   (1) L
        db      038h            ; 1/08  L 1/8
        db      064h            ; Do   (2) L
        db      03Bh            ; 1/16  P 1/16
        db      000h            ; Pauza    P
        db      03Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      03Bh            ; 1/16  L 1/16
        db      068h            ; Mi   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      067h            ; Re#  (2) L
        db      03Bh            ; 1/16  L 1/16
        db      068h            ; Mi   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      067h            ; Re#  (2) L
        db      03Bh            ; 1/16  L 1/16
        db      068h            ; Mi   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      063h            ; Si   (1) L
        db      03Bh            ; 1/16  L 1/16
        db      066h            ; Re   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      064h            ; Do   (2) L
        db      038h            ; 1/08  L 1/8
        db      061h            ; La   (1) L
        db      03Bh            ; 1/16  P 1/16
        db      000h            ; Pauza    P
        db      03Bh            ; 1/16  L 1/16
        db      058h            ; Do   (1) L
        db      03Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      03Bh            ; 1/16  L 1/16
        db      061h            ; La   (1) L
        db      038h            ; 1/08  L 1/8
        db      063h            ; Si   (1) L
        db      03Bh            ; 1/16  P 1/16
        db      000h            ; Pauza    P
        db      03Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      03Bh            ; 1/16  L 1/16
        db      064h            ; Do   (2) L
        db      03Bh            ; 1/16  L 1/16
        db      063h            ; Si   (1) L
        db      035h            ; 1/04  L 1/4
        db      061h            ; La   (1) L
        db      03Fh            ; Tempou= 80
        db      061h            ; Melody END
;
;---------------------------------------------------------------------
; *** Ж. М. Жарр. Магнитные поля ****
        db      06Bh            ; 1/16  L 1/16
        db      05Dh            ; Fa   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Fh            ; Sol  (1) L
        db      06Bh            ; 1/16  L 1/16
        db      061h            ; La   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Fh            ; Sol  (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Dh            ; Fa   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      061h            ; La   (1) L
        db      068h            ; 1/08  L 1/8
        db      061h            ; La   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Dh            ; Fa   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Fh            ; Sol  (1) L
        db      06Bh            ; 1/16  L 1/16
        db      061h            ; La   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Fh            ; Sol  (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Dh            ; Fa   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      061h            ; La   (1) L
        db      06Bh            ; 1/16  L 1/8
        db      061h            ; La   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Dh            ; Fa   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Fh            ; Sol  (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Dh            ; Fa   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Fh            ; Sol  (1) L
        db      068h            ; 1/08  L 1/8
        db      05Fh            ; Sol  (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Dh            ; Fa   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Fh            ; Sol  (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Dh            ; Fa   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Fh            ; Sol  (1) L
        db      068h            ; 1/08  L 1/8
        db      05Fh            ; Sol  (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ah            ; Re   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Dh            ; Fa   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ah            ; Re   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Dh            ; Fa   (1) L
        db      068h            ; 1/08  L 1/8
        db      05Dh            ; Fa   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ah            ; Re   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Dh            ; Fa   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ah            ; Re   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Dh            ; Fa   (1) L
        db      065h            ; 1/04  L 1/4
        db      05Dh            ; Fa   (1) L
        db      068h            ; 1/08  L 1/8
        db      05Dh            ; Fa   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      06Bh            ; 1/16  L 1/16
        db      05Ah            ; Re   (1) L
        db      062h            ; 1/02  L 1/2
        db      058h            ; Do   (1) L
        db      06Fh            ; Tempou= 120
        db      058h            ; Melody END
;---------------------------------------------------------------------
; *** Джо Дассен. Если не было тебя ****
        db      068h            ; 1/08 Nd 1/9
        db      095h            ; La   (M) N
        db      068h            ; 1/08 Nd 1/9
        db      09Ah            ; Re   (1) N
        db      068h            ; 1/08 Nd 1/9
        db      09Ch            ; Mi   (1) N
        db      068h            ; 1/08 Nd 1/9
        db      09Dh            ; Fa   (1) N
        db      065h            ; 1/04 Nd 1/5
        db      09Ch            ; Mi   (1) N
        db      068h            ; 1/08 Nd 1/9
        db      09Ah            ; Re   (1) N
        db      068h            ; 1/08  L 1/8
        db      055h            ; La   (M) L
        db      063h            ; 1/04*Nd 1/3
        db      095h            ; La   (M) N
        db      068h            ; 1/08 Nd 1/9
        db      095h            ; La   (M) N
        db      068h            ; 1/08 Nd 1/9
        db      09Ah            ; Re   (1) N
        db      068h            ; 1/08 Nd 1/9
        db      09Ch            ; Mi   (1) N
        db      068h            ; 1/08 Nd 1/9
        db      09Dh            ; Fa   (1) N
        db      068h            ; 1/08 Nd 1/9
        db      0A1h            ; La   (1) N
        db      065h            ; 1/04  L 1/4
        db      064h            ; Do   (2) L
        db      068h            ; 1/08 Nd 1/9
        db      0A2h            ; La#  (1) N
        db      068h            ; 1/08  L 1/8
        db      05Ch            ; Mi   (1) L
        db      062h            ; 1/02  L 1/2
        db      05Ch            ; Mi   (1) L
        db      06Fh            ; Tempou= 120
        db      05Ch            ; Melody END
;
;---------------------------------------------------------------------
; *** Ламбада ****
        db      0B2h            ; 1/02 Nd 1/3
        db      0AFh            ; Si   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0ADh            ; La   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0ABh            ; Sol  (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0AAh            ; Fa#  (2) 
        db      0B5h            ; 1/04 Nd 1/5
        db      0A8h            ; Mi   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0ABh            ; Sol  (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0AAh            ; Fa#  (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A3h            ; Si   (1) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A1h            ; La   (1) 
        db      0B2h            ; 1/02  L 1/2
        db      063h            ; Si   (1) 
        db      0B5h            ; 1/04 Nd 1/5
        db      0A3h            ; Si   (1) 
        db      0B5h            ; 1/04 Nd 1/5
        db      0A3h            ; Si   (1) 
        db      0B2h            ; 1/02 Nd 1/3
        db      0AFh            ; Si   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0ADh            ; La   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0ABh            ; Sol  (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0AAh            ; Fa#  (2) 
        db      0B5h            ; 1/04 Nd 1/5
        db      0A8h            ; Mi   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0ABh            ; Sol  (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0AAh            ; Fa#  (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A3h            ; Si   (1) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A1h            ; La   (1) 
        db      0B2h            ; 1/02  L 1/2
        db      063h            ; Si   (1) 
        db      0B5h            ; 1/04 Nd 1/5
        db      0A3h            ; Si   (1) 
        db      0B5h            ; 1/04 Nd 1/5
        db      0A3h            ; Si   (1) 
        db      0B5h            ; 1/04 Nd 1/5
        db      0ADh            ; La   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0ADh            ; La   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0ABh            ; Sol  (2) 
        db      0B5h            ; 1/04 Nd 1/5
        db      0A4h            ; Do   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A4h            ; Do   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      0B5h            ; 1/04 Nd 1/5
        db      0AFh            ; Si   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0ADh            ; La   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0ABh            ; Sol  (2) 
        db      0B5h            ; 1/04 Nd 1/5
        db      0A4h            ; Do   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0ABh            ; Sol  (2) 
        db      0BBh            ; 1/16 Nd 1/19
        db      0AAh            ; Fa#  (2) 
        db      0BBh            ; 1/16 Nd 1/19
        db      0AAh            ; Fa#  (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      0B8h            ; 1/08  L 1/8
        db      066h            ; Re   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      0B8h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      0B2h            ; 1/02  L 1/2
        db      068h            ; Mi   (2) 
        db      0B2h            ; 1/02 Nd 1/2
        db      0A8h            ; Mi   (2) 
        db      0BFh            ; Tempou= 180
        db      0A8h            ; Melody END
;---------------------------------------------------------------------
; *** Ф. Лэй. История любви ****
        db      068h            ; 1/08 Nd 1/9
        db      0A2h            ; La#  (1) 
        db      068h            ; 1/08 Nd 1/9
        db      09Ah            ; Re   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      09Ah            ; Re   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      0A2h            ; La#  (1) 
        db      062h            ; 1/02  L 1/2
        db      062h            ; La#  (1) 
        db      068h            ; 1/08 Nd 1/9
        db      0A2h            ; La#  (1) 
        db      068h            ; 1/08 Nd 1/9
        db      09Ah            ; Re   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      09Ah            ; Re   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      0A2h            ; La#  (1) 
        db      068h            ; 1/08 Nd 1/9
        db      0A2h            ; La#  (1) 
        db      068h            ; 1/08 Nd 1/9
        db      09Ah            ; Re   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      09Bh            ; Re#  (1) 
        db      068h            ; 1/08 Nd 1/9
        db      09Ah            ; Re   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      098h            ; Do   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      098h            ; Do   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      098h            ; Do   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      0A1h            ; La   (1) 
        db      062h            ; 1/02  L 1/2
        db      061h            ; La   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      0A1h            ; La   (1) 
        db      06Fh            ; Tempou= 120
        db      0A1h            ; Melody END
;---------------------------------------------------------------------
; *** П. Чайковский. Танец маленьких лебедей ****
        db      048h            ; 1/08 Sd 1/11
        db      0E1h            ; La   (1) 
        db      048h            ; 1/08 Sd 1/11
        db      0E1h            ; La   (1) 
        db      048h            ; 1/08 Sd 1/11
        db      0E1h            ; La   (1) 
        db      046h            ; 1/08*Nd 1/6
        db      0A1h            ; La   (1) 
        db      04Eh            ; 1/32  L 1/32
        db      060h            ; Sol# (1) 
        db      04Eh            ; 1/32  L 1/32
        db      061h            ; La   (1) 
        db      048h            ; 1/08 Sd 1/11
        db      0E3h            ; Si   (1) 
        db      048h            ; 1/08 Sd 1/11
        db      0E1h            ; La   (1) 
        db      048h            ; 1/08 Sd 1/11
        db      0E0h            ; Sol# (1) 
        db      048h            ; 1/08 Sd 1/11
        db      0E3h            ; Si   (1) 
        db      048h            ; 1/08 Sd 1/11
        db      0E3h            ; Si   (1) 
        db      048h            ; 1/08 Sd 1/11
        db      0E3h            ; Si   (1) 
        db      046h            ; 1/08*Nd 1/6
        db      0A3h            ; Si   (1) 
        db      04Eh            ; 1/32  L 1/32
        db      061h            ; La   (1) 
        db      04Eh            ; 1/32  L 1/32
        db      063h            ; Si   (1) 
        db      048h            ; 1/08 Sd 1/11
        db      0E5h            ; Do#  (2) 
        db      048h            ; 1/08 Sd 1/11
        db      0E3h            ; Si   (1) 
        db      048h            ; 1/08 Sd 1/11
        db      0E1h            ; La   (1) 
        db      048h            ; 1/08 Sd 1/11
        db      0E5h            ; Do#  (2) 
        db      048h            ; 1/08 Sd 1/11
        db      0EAh            ; Fa#  (2) 
        db      048h            ; 1/08 Sd 1/11
        db      0E9h            ; Fa   (2) 
        db      042h            ; 1/02  L 1/2
        db      065h            ; Do#  (2) 
        db      04Fh            ; Tempou= 90
        db      065h            ; Melody END
;---------------------------------------------------------------------
; *** В. А. Моцарт. Симфония №40 ****
        db      0C8h            ; 1/08  L 1/8
        db      067h            ; Re#  (2) 
        db      0C8h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0A6h            ; Re   (2) 
        db      0C8h            ; 1/08  L 1/8
        db      067h            ; Re#  (2) 
        db      0C8h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0A6h            ; Re   (2) 
        db      0C8h            ; 1/08  L 1/8
        db      067h            ; Re#  (2) 
        db      0C8h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0A6h            ; Re   (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0AEh            ; La#  (2) 
        db      0C5h            ; 1/04  P 1/4
        db      000h            ; Pauza    
        db      0C8h            ; 1/08  L 1/8
        db      06Eh            ; La#  (2) 
        db      0C8h            ; 1/08  L 1/8
        db      06Dh            ; La   (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0ABh            ; Sol  (2) 
        db      0C8h            ; 1/08  L 1/8
        db      06Bh            ; Sol  (2) 
        db      0C8h            ; 1/08 Nd 1/9
        db      0A9h            ; Fa   (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0A7h            ; Re#  (2) 
        db      0C8h            ; 1/08  L 1/8
        db      067h            ; Re#  (2) 
        db      0C8h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0A4h            ; Do   (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0A4h            ; Do   (2) 
        db      0C5h            ; 1/04  P 1/4
        db      000h            ; Pauza    
        db      0C8h            ; 1/08  L 1/8
        db      066h            ; Re   (2) 
        db      0C8h            ; 1/08 Nd 1/9
        db      0A4h            ; Do   (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0A4h            ; Do   (2) 
        db      0C8h            ; 1/08  L 1/8
        db      066h            ; Re   (2) 
        db      0C8h            ; 1/08 Nd 1/9
        db      0A4h            ; Do   (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0A4h            ; Do   (2) 
        db      0C8h            ; 1/08  L 1/8
        db      066h            ; Re   (2) 
        db      0C8h            ; 1/08 Nd 1/9
        db      0A4h            ; Do   (2) 
        db      0C5h            ; 1/04  L 1/4
        db      064h            ; Do   (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0ADh            ; La   (2) 
        db      0C5h            ; 1/04  P 1/4
        db      000h            ; Pauza    
        db      0C8h            ; 1/08  L 1/8
        db      06Dh            ; La   (2) 
        db      0C8h            ; 1/08 Nd 1/9
        db      0ABh            ; Sol  (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0AAh            ; Fa#  (2) 
        db      0C8h            ; 1/08 Nd 1/9
        db      0AAh            ; Fa#  (2) 
        db      0C8h            ; 1/08 Nd 1/9
        db      0A7h            ; Re#  (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0A6h            ; Re   (2) 
        db      0C8h            ; 1/08  L 1/8
        db      066h            ; Re   (2) 
        db      0C8h            ; 1/08 Nd 1/9
        db      0A4h            ; Do   (2) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0A2h            ; La#  (1) 
        db      0C5h            ; 1/04 Nd 1/5
        db      0A2h            ; La#  (1) 
        db      0CFh            ; Tempou= 195
        db      0A2h            ; Melody END
;---------------------------------------------------------------------
; *** П. Мориа. Менуэт ****
        db      0BEh            ; 1/32  L 1/33  1
        db      068h            ; Mi   (2)      2
        db      0BEh            ; 1/32  L 1/33  1
        db      06Ah            ; Fa#  (2)      2
        db      0BBh            ; 1/16  L 1/16  1
        db      068h            ; Mi   (2)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A7h            ; Re#  (2)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A8h            ; Mi   (2)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0AAh            ; Fa#  (2)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0ACh            ; Sol# (2)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A0h            ; Sol# (1)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A5h            ; Do#  (2)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A3h            ; Si   (1)      2
        db      0BEh            ; 1/32  L 1/33  1
        db      063h            ; Si   (1)      2
        db      0BEh            ; 1/32  L 1/33  1
        db      065h            ; Do#  (2)      2
        db      0BBh            ; 1/16  L 1/16  1
        db      063h            ; Si   (1)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A1h            ; La   (1)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A1h            ; La   (1)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A0h            ; Sol# (1)      2
        db      0B2h            ; 1/02  L 1/2   1
        db      061h            ; La   (1)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A1h            ; La   (1)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A3h            ; Si   (1)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0AAh            ; Fa#  (2)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A7h            ; Re#  (2)      2
        db      0B8h            ; 1/08  L 1/8   1
        db      063h            ; Si   (1)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A5h            ; Do#  (2)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A1h            ; La   (1)      2
        db      0B8h            ; 1/08 Nd 1/9   1
        db      0A3h            ; Si   (1)      2
        db      0B0h            ; 1/01 Nd 1/1   1
        db      0A0h            ; Sol# (1)      2
        db      0BFh            ; Tempou= 180   1
        db      060h            ; Melody END    2
;---------------------------------------------------------------------
; *** М. Огинский. Полонез ****
        db      063h            ; 1/04* L 1/3
        db      068h            ; Mi   (2) 
        db      06Bh            ; 1/16  L 1/16
        db      067h            ; Re#  (2) 
        db      06Bh            ; 1/16  L 1/16
        db      068h            ; Mi   (2) 
        db      068h            ; 1/08  L 1/8
        db      069h            ; Fa   (2) 
        db      068h            ; 1/08  L 1/8
        db      068h            ; Mi   (2) 
        db      068h            ; 1/08 Sd 1/11
        db      0E4h            ; Do   (2) 
        db      06Bh            ; 1/16  L 1/16
        db      064h            ; Do   (2) 
        db      06Bh            ; 1/16  L 1/16
        db      063h            ; Si   (1) 
        db      063h            ; 1/04* L 1/3
        db      061h            ; La   (1) 
        db      068h            ; 1/08  L 1/8
        db      064h            ; Do   (2) 
        db      068h            ; 1/08 Sd 1/11
        db      0E8h            ; Mi   (2) 
        db      068h            ; 1/08 Sd 1/11
        db      0E8h            ; Mi   (2) 
        db      063h            ; 1/04* L 1/3
        db      06Dh            ; La   (2) 
        db      068h            ; 1/08  L 1/8
        db      068h            ; Mi   (2) 
        db      068h            ; 1/08 Sd 1/11
        db      0EBh            ; Sol  (2) 
        db      068h            ; 1/08 Sd 1/11
        db      0EAh            ; Fa#  (2) 
        db      063h            ; 1/04* L 1/3
        db      069h            ; Fa   (2) 
        db      06Fh            ; Tempou= 120
        db      069h            ; Melody END
;---------------------------------------------------------------------
; *** Попкорн ****
        db      0A8h            ; 1/08 Nd 1/9
        db      0A5h            ; Do#  (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A3h            ; Si   (1) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A5h            ; Do#  (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A0h            ; Sol# (1) 
        db      0A8h            ; 1/08 Nd 1/9
        db      09Ch            ; Mi   (1) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A0h            ; Sol# (1) 
        db      0A5h            ; 1/04 Nd 1/5
        db      099h            ; Do#  (1) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A5h            ; Do#  (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A3h            ; Si   (1) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A5h            ; Do#  (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A0h            ; Sol# (1) 
        db      0A8h            ; 1/08 Nd 1/9
        db      09Ch            ; Mi   (1) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A0h            ; Sol# (1) 
        db      0A5h            ; 1/04 Nd 1/5
        db      099h            ; Do#  (1) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A5h            ; Do#  (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A7h            ; Re#  (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A7h            ; Re#  (2) 
        db      0ABh            ; 1/16 Nd 1/19
        db      0A8h            ; Mi   (2) 
        db      0ABh            ; 1/16 Nd 1/19
        db      0A8h            ; Mi   (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A5h            ; Do#  (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A7h            ; Re#  (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A5h            ; Do#  (2) 
        db      0ABh            ; 1/16 Nd 1/19
        db      0A7h            ; Re#  (2) 
        db      0ABh            ; 1/16 Nd 1/19
        db      0A7h            ; Re#  (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A3h            ; Si   (1) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A5h            ; Do#  (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A3h            ; Si   (1) 
        db      0ABh            ; 1/16 Nd 1/19
        db      0A5h            ; Do#  (2) 
        db      0ABh            ; 1/16 Nd 1/19
        db      0A5h            ; Do#  (2) 
        db      0A8h            ; 1/08 Nd 1/9
        db      0A1h            ; La   (1) 
        db      0A5h            ; 1/04 Nd 1/5
        db      0A5h            ; Do#  (2) 
        db      0AFh            ; Tempou= 165
        db      0A5h            ; Melody END
;---------------------------------------------------------------------
; *** Ф. Папетти. Райская мелодия ****
        db      078h            ; 1/08  L 1/8
        db      063h            ; Si   (1) 
        db      078h            ; 1/08  L 1/8
        db      062h            ; La#  (1) 
        db      078h            ; 1/08  L 1/8
        db      063h            ; Si   (1) 
        db      076h            ; 1/08* L 1/5
        db      068h            ; Mi   (2) 
        db      07Bh            ; 1/16  L 1/16
        db      063h            ; Si   (1) 
        db      078h            ; 1/08  L 1/8
        db      062h            ; La#  (1) 
        db      078h            ; 1/08  L 1/8
        db      063h            ; Si   (1) 
        db      072h            ; 1/02  L 1/2
        db      061h            ; La   (1) 
        db      072h            ; 1/02  L 1/2
        db      061h            ; La   (1) 
        db      078h            ; 1/08  L 1/8
        db      061h            ; La   (1) 
        db      078h            ; 1/08  L 1/8
        db      063h            ; Si   (1) 
        db      07Bh            ; 1/16  L 1/16
        db      062h            ; La#  (1) 
        db      076h            ; 1/08* L 1/5
        db      063h            ; Si   (1) 
        db      07Bh            ; 1/16  L 1/16
        db      062h            ; La#  (1) 
        db      076h            ; 1/08* L 1/5
        db      063h            ; Si   (1) 
        db      078h            ; 1/08  L 1/8
        db      062h            ; La#  (1) 
        db      078h            ; 1/08  L 1/8
        db      063h            ; Si   (1) 
        db      072h            ; 1/02  L 1/2
        db      05Fh            ; Sol  (1) 
        db      072h            ; 1/02  L 1/2
        db      05Fh            ; Sol  (1) 
        db      075h            ; 1/04 Nd 1/5
        db      09Fh            ; Sol  (1) 
        db      076h            ; 1/08* L 1/5
        db      05Fh            ; Sol  (1) 
        db      07Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) 
        db      078h            ; 1/08  L 1/8
        db      05Fh            ; Sol  (1) 
        db      078h            ; 1/08  L 1/8
        db      05Ch            ; Mi   (1) 
        db      076h            ; 1/08* L 1/5
        db      05Fh            ; Sol  (1) 
        db      07Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) 
        db      072h            ; 1/02  L 1/2
        db      05Eh            ; Fa#  (1) 
        db      075h            ; 1/04  L 1/4
        db      05Eh            ; Fa#  (1) 
        db      07Ah            ; 1/12  L 1/12
        db      059h            ; Do#  (1) 
        db      07Ah            ; 1/12  L 1/12
        db      05Ch            ; Mi   (1) 
        db      07Ah            ; 1/12  L 1/12
        db      05Fh            ; Sol  (1) 
        db      075h            ; 1/04  L 1/4
        db      05Eh            ; Fa#  (1) 
        db      078h            ; 1/08  L 1/8
        db      05Eh            ; Fa#  (1) 
        db      07Bh            ; 1/16  L 1/16
        db      05Fh            ; Sol  (1) 
        db      07Bh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) 
        db      072h            ; 1/02  L 1/2
        db      059h            ; Do#  (1) 
        db      072h            ; 1/02  L 1/2
        db      05Eh            ; Fa#  (1) 
        db      072h            ; 1/02  L 1/2
        db      05Eh            ; Fa#  (1) 
        db      07Fh            ; Tempou= 135
        db      05Eh            ; Melody END
;
;---------------------------------------------------------------------
; *** Space. Волшебный полет ****
        db      098h            ; 1/08 Nd 1/9
        db      0A1h            ; La   (1) 
        db      098h            ; 1/08 Nd 1/9
        db      0A1h            ; La   (1) 
        db      098h            ; 1/08  L 1/8
        db      064h            ; Do   (2) 
        db      098h            ; 1/08  L 1/8
        db      068h            ; Mi   (2) 
        db      098h            ; 1/08  L 1/8
        db      064h            ; Do   (2) 
        db      098h            ; 1/08  L 1/8
        db      063h            ; Si   (1) 
        db      098h            ; 1/08  L 1/8
        db      061h            ; La   (1) 
        db      095h            ; 1/04 Nd 1/5
        db      0A1h            ; La   (1) 
        db      098h            ; 1/08  L 1/8
        db      061h            ; La   (1) 
        db      098h            ; 1/08  L 1/8
        db      064h            ; Do   (2) 
        db      098h            ; 1/08  L 1/8
        db      068h            ; Mi   (2) 
        db      098h            ; 1/08  L 1/8
        db      064h            ; Do   (2) 
        db      098h            ; 1/08  L 1/8
        db      063h            ; Si   (1) 
        db      098h            ; 1/08  L 1/8
        db      061h            ; La   (1) 
        db      095h            ; 1/04 Nd 1/5
        db      0A1h            ; La   (1) 
        db      098h            ; 1/08  L 1/8
        db      061h            ; La   (1) 
        db      098h            ; 1/08  L 1/8
        db      064h            ; Do   (2) 
        db      095h            ; 1/04  L 1/4
        db      069h            ; Fa   (2) 
        db      098h            ; 1/08  L 1/8
        db      068h            ; Mi   (2) 
        db      098h            ; 1/08  L 1/8
        db      066h            ; Re   (2) 
        db      095h            ; 1/04  L 1/4
        db      069h            ; Fa   (2) 
        db      098h            ; 1/08  L 1/8
        db      068h            ; Mi   (2) 
        db      098h            ; 1/08  L 1/8
        db      066h            ; Re   (2) 
        db      098h            ; 1/08  L 1/8
        db      069h            ; Fa   (2) 
        db      098h            ; 1/08  L 1/8
        db      068h            ; Mi   (2) 
        db      098h            ; 1/08  L 1/8
        db      066h            ; Re   (2) 
        db      098h            ; 1/08  L 1/8
        db      068h            ; Mi   (2) 
        db      095h            ; 1/04  L 1/4
        db      068h            ; Mi   (2) 
        db      09Fh            ; Tempou= 150
        db      068h            ; Melody END
;
;---------------------------------------------------------------------
; *** В. А. Моцарт. Рондо (Турецкий марш) ****
        db      09Bh            ; 1/16 Nd 1/18
        db      0A3h            ; Si   (1) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0A1h            ; La   (1) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0A0h            ; Sol# (1) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0A1h            ; La   (1) 
        db      095h            ; 1/04 Nd 1/5
        db      0A4h            ; Do   (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0A6h            ; Re   (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0A4h            ; Do   (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0A3h            ; Si   (1) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0A4h            ; Do   (2) 
        db      095h            ; 1/04 Nd 1/5
        db      0A8h            ; Mi   (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0A9h            ; Fa   (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0A8h            ; Mi   (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0A7h            ; Re#  (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0A8h            ; Mi   (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0AFh            ; Si   (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0ADh            ; La   (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0ACh            ; Sol# (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0ADh            ; La   (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0AFh            ; Si   (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0ADh            ; La   (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0ACh            ; Sol# (2) 
        db      09Bh            ; 1/16 Nd 1/18
        db      0ADh            ; La   (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0B0h            ; Do   (3) 
        db      098h            ; 1/08 Nd 1/9
        db      0B0h            ; Do   (3) 
        db      098h            ; 1/08 Sd 1/11
        db      0EDh            ; La   (2) 
        db      098h            ; 1/08 Sd 1/11
        db      0F0h            ; Do   (3) 
        db      09Eh            ; 1/32  L 1/32
        db      06Bh            ; Sol  (2) 
        db      09Eh            ; 1/32  L 1/32
        db      06Dh            ; La   (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0AFh            ; Si   (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0ADh            ; La   (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0ABh            ; Sol  (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0ADh            ; La   (2) 
        db      09Eh            ; 1/32  L 1/32
        db      06Bh            ; Sol  (2) 
        db      09Eh            ; 1/32  L 1/32
        db      06Dh            ; La   (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0AFh            ; Si   (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0ADh            ; La   (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0ABh            ; Sol  (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0ADh            ; La   (2) 
        db      09Eh            ; 1/32  L 1/32
        db      06Bh            ; Sol  (2) 
        db      09Eh            ; 1/32  L 1/32
        db      06Dh            ; La   (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0AFh            ; Si   (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0ADh            ; La   (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0ABh            ; Sol  (2) 
        db      098h            ; 1/08 Nd 1/9
        db      0AAh            ; Fa#  (2) 
        db      095h            ; 1/04 Nd 1/5
        db      0A8h            ; Mi   (2) 
        db      09Fh            ; Tempou= 150
        db      0A8h            ; Melody END
;---------------------------------------------------------------------
; *** М. Легран. Шербургские зонтики ***
        db      048h            ; 1/08  L 1/8
        db      064h            ; Do   (2) 
        db      048h            ; 1/08  L 1/8
        db      064h            ; Do   (2) 
        db      045h            ; 1/04  L 1/4
        db      063h            ; Si   (1) 
        db      045h            ; 1/04  L 1/4
        db      061h            ; La   (1) 
        db      048h            ; 1/08  L 1/8
        db      060h            ; Sol# (1) 
        db      048h            ; 1/08  L 1/8
        db      05Eh            ; Fa#  (1) 
        db      048h            ; 1/08  L 1/8
        db      069h            ; Fa   (2) 
        db      048h            ; 1/08  L 1/8
        db      06Ah            ; Fa#  (2) 
        db      045h            ; 1/04  L 1/4
        db      068h            ; Mi   (2) 
        db      045h            ; 1/04 Nd 1/5
        db      0A6h            ; Re   (2) 
        db      045h            ; 1/04 Nd 1/5
        db      0A6h            ; Re   (2) 
        db      048h            ; 1/08 Nd 1/9
        db      0A2h            ; La#  (1) 
        db      048h            ; 1/08 Nd 1/9
        db      0A3h            ; Si   (1) 
        db      045h            ; 1/04 Nd 1/5
        db      0A1h            ; La   (1) 
        db      045h            ; 1/04 Nd 1/5
        db      0A0h            ; Sol# (1) 
        db      048h            ; 1/08 Nd 1/9
        db      09Eh            ; Fa#  (1) 
        db      048h            ; 1/08 Nd 1/9
        db      09Ch            ; Mi   (1) 
        db      048h            ; 1/08 Nd 1/9
        db      0A7h            ; Re#  (2) 
        db      048h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      045h            ; 1/04 Nd 1/5
        db      0A6h            ; Re   (2) 
        db      045h            ; 1/04 Nd 1/5
        db      0A5h            ; Do#  (2) 
        db      045h            ; 1/04 Nd 1/5
        db      0A5h            ; Do#  (2) 
        db      04Fh            ; Tempou= 90
        db      0A5h            ; Melody END
;
;---------------------------------------------------------------------
; *** Вальс. На сопках Маньчжурии ***
        db      0D1h            ; 1/02* L 1/1
        db      061h            ; La   (1) 
        db      0D5h            ; 1/04  L 1/4
        db      061h            ; La   (1) 
        db      0D5h            ; 1/04  L 1/4
        db      05Dh            ; Fa   (1) 
        db      0D5h            ; 1/04  L 1/4
        db      05Fh            ; Sol  (1) 
        db      0D1h            ; 1/02* L 1/1
        db      061h            ; La   (1) 
        db      0D2h            ; 1/02  P 1/2
        db      000h            ; Pauza    
        db      0D5h            ; 1/04  P 1/4
        db      000h            ; Pauza    
        db      0D5h            ; 1/04  L 1/4
        db      05Fh            ; Sol  (1) 
        db      0D5h            ; 1/04  L 1/4
        db      061h            ; La   (1) 
        db      0D5h            ; 1/04  L 1/4
        db      065h            ; Do#  (2) 
        db      0D2h            ; 1/02  L 1/2
        db      069h            ; Fa   (2) 
        db      0D5h            ; 1/04  L 1/4
        db      068h            ; Mi   (2) 
        db      0D1h            ; 1/02* L 1/1
        db      066h            ; Re   (2) 
        db      0D2h            ; 1/02  P 1/2
        db      000h            ; Pauza    
        db      0D5h            ; 1/04  P 1/4
        db      000h            ; Pauza    
        db      0D5h            ; 1/04  L 1/4
        db      061h            ; La   (1) 
        db      0D5h            ; 1/04  L 1/4
        db      066h            ; Re   (2) 
        db      0D5h            ; 1/04  L 1/4
        db      069h            ; Fa   (2) 
        db      0D2h            ; 1/02  L 1/2
        db      065h            ; Do#  (2) 
        db      0D5h            ; 1/04  L 1/4
        db      066h            ; Re   (2) 
        db      0D5h            ; 1/04  L 1/4
        db      068h            ; Mi   (2) 
        db      0D5h            ; 1/04  L 1/4
        db      066h            ; Re   (2) 
        db      0D5h            ; 1/04  L 1/4
        db      062h            ; La#  (1) 
        db      0D2h            ; 1/02  L 1/2
        db      068h            ; Mi   (2) 
        db      0D5h            ; 1/04  L 1/4
        db      066h            ; Re   (2) 
        db      0D5h            ; 1/04  L 1/4
        db      061h            ; La   (1) 
        db      0D5h            ; 1/04  L 1/4
        db      066h            ; Re   (2) 
        db      0D5h            ; 1/04  L 1/4
        db      068h            ; Mi   (2) 
        db      0D2h            ; 1/02  L 1/2
        db      069h            ; Fa   (2) 
        db      0D5h            ; 1/04  L 1/4
        db      068h            ; Mi   (2) 
        db      0D5h            ; 1/04 Nd 1/5
        db      0A6h            ; Re   (2) 
        db      0D5h            ; 1/04 Nd 1/4
        db      0A1h            ; La   (1) 
        db      0D5h            ; 1/04 Nd 1/5
        db      09Dh            ; Fa   (1) 
        db      0D8h            ; 1/08 Nd 1/11
        db      09Ah            ; Re   (1) 
        db      0DFh            ; Tempou= 210
        db      09Ah            ; Melody END
;
;---------------------------------------------------------------------
; *** Н. Рота. Говори тише, любовь ***
        db      068h            ; 1/08 Nd 1/9
        db      0A1h            ; La   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A9h            ; Fa   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A9h            ; Fa   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A2h            ; La#  (1) 
        db      068h            ; 1/08 Nd 1/9
        db      0A4h            ; Do   (2) 
        db      062h            ; 1/02  L 1/2
        db      061h            ; La   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      0A1h            ; La   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      0A1h            ; La   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A9h            ; Fa   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A9h            ; Fa   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A8h            ; Mi   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A6h            ; Re   (2) 
        db      068h            ; 1/08 Nd 1/9
        db      0A1h            ; La   (1) 
        db      068h            ; 1/08 Nd 1/9
        db      0A0h            ; Sol# (1) 
        db      062h            ; 1/02  L 1/2
        db      05Fh            ; Sol  (1) 
        db      068h            ; 1/08 Nd 1/9
        db      09Fh            ; Sol  (1) 
        db      06Fh            ; Tempou= 120
        db      09Fh            ; Melody END
;---------------------------------------------------------------------
; *** Ф. Папетти. Как ты думаешь? ****
        db      0A8h            ; 1/08  L 1/8
        db      066h            ; Re   (2) L
        db      0A8h            ; 1/08  L 1/8
        db      066h            ; Re   (2) L
        db      0A8h            ; 1/08  L 1/8
        db      063h            ; Si   (1) L
        db      0A6h            ; 1/08* L 1/5
        db      05Fh            ; Sol  (1) L
        db      0ABh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      0A6h            ; 1/08* L 1/5
        db      05Fh            ; Sol  (1) L
        db      0A6h            ; 1/08*Sd 1/8
        db      0DCh            ; Mi   (1) S
        db      0A8h            ; 1/08  L 1/8
        db      066h            ; Re   (2) L
        db      0A8h            ; 1/08  L 1/8
        db      066h            ; Re   (2) L
        db      0A8h            ; 1/08  L 1/8
        db      063h            ; Si   (1) L
        db      0A6h            ; 1/08* L 1/5
        db      05Fh            ; Sol  (1) L
        db      0ABh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      0A6h            ; 1/08* L 1/5
        db      05Fh            ; Sol  (1) L
        db      0A6h            ; 1/08*Sd 1/8
        db      0DCh            ; Mi   (1) S
        db      0A8h            ; 1/08  L 1/8
        db      066h            ; Re   (2) L
        db      0A8h            ; 1/08  L 1/8
        db      066h            ; Re   (2) L
        db      0A8h            ; 1/08  L 1/8
        db      063h            ; Si   (1) L
        db      0A6h            ; 1/08* L 1/5
        db      05Fh            ; Sol  (1) L
        db      0ABh            ; 1/16  L 1/16
        db      05Ch            ; Mi   (1) L
        db      0A6h            ; 1/08* L 1/5
        db      05Fh            ; Sol  (1) L
        db      0A6h            ; 1/08*Sd 1/8
        db      0DCh            ; Mi   (1) S
        db      0A3h            ; 1/04* L 1/3
        db      063h            ; Si   (1) L
        db      0AFh            ; Tempou= 165
        db      063h            ; Melody END
;
;--------------------------------------------------------------------
; *** Аль Бано и Ромина Пауэр. Felicita ****
        db      06Ah            ; 1/12 Nd 1/14
        db      0A1h            ; La   (1) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A3h            ; Si   (1) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A5h            ; Do#  (2) N
        db      067h            ; 1/06 Nd 1/7
        db      0A5h            ; Do#  (2) N
        db      065h            ; 1/04  P 1/4
        db      000h            ; Pauza    P
        db      06Ah            ; 1/12  P 1/12
        db      000h            ; Pauza    P
        db      06Ah            ; 1/12 Nd 1/14
        db      0A1h            ; La   (1) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A3h            ; Si   (1) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A5h            ; Do#  (2) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A5h            ; Do#  (2) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A5h            ; Do#  (2) N
        db      06Ah            ; 1/12  L 1/12
        db      066h            ; Re   (2) L
        db      06Ah            ; 1/12 Nd 1/14
        db      0A6h            ; Re   (2) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A5h            ; Do#  (2) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A5h            ; Do#  (2) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A5h            ; Do#  (2) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A5h            ; Do#  (2) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A6h            ; Re   (2) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A5h            ; Do#  (2) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A3h            ; Si   (1) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A1h            ; La   (1) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A3h            ; Si   (1) N
        db      06Ah            ; 1/12 Nd 1/14
        db      0A5h            ; Do#  (2) N
        db      067h            ; 1/06 Nd 1/7
        db      0A5h            ; Do#  (2) N
        db      06Fh            ; Tempou= 120
        db      0A5h            ; Melody END
;
;=====================================================================
        db      0FFh            ; Конец массива мелодий
        db      0FFh            ;
;=====================================================================
        END
