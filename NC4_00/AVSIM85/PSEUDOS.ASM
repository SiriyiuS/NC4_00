$SHOWMACS

;     This file is intended to demonstrate 
; the uses and capablities of the Avocet 
; macro facilities, as well as to illustrate
; the proper use of Avocet pseudo-operations
; and preprocessor directives.

; *****************************************
; *****************************************
; *****        PSEUDO - OPS           *****
; *****************************************
; *****************************************


; *****************************************
;    Using the DEFSEG and SEG pseudo-ops...
; *****************************************

; Note that DEFSEG defines a name for a 
; segment (called a 'user-defined' segment),
; while SEG actually places you into a 
; segment.  You remain in that segment until
; you specify (using another SEG pseudo-op) 
; that you wish to be in a different segment.

	DEFSEG  segname
	SEG	segname
	db	1

	DEFSEG  seg2name
	SEG	seg2name
	db	2

;   You may assign attributes to a segment...
; Specifying the ABSOLUTE attribute allows 
; use of ORG statements within the segment

	DEFSEG  segabs, ABSOLUTE
	SEG	segabs
	ORG	100H
	db	3

	ORG	200H
	db	4

;   The ORG pseudo-op may also be used in a
; relocatable segment which has the
; START= attribute, but only if that segment
; resides entirely in one module.  If the
; ORG is used in a relocatable, START= type
; segment in more than one module, that
; segment must be OVERLAID.
;
; Note that you may use AVLINK options on
; relocatable segments, but not on ABSOLUTE
; segments, and that the linker will warn
; you if relocatable segments overwrite, but
; not if an ABSOLUTE segment overwrites any
; other segment. (See the chapter on Segments
; and Relocation.)

	DEFSEG segreloc, START=250H
	SEG    segreloc
	db     5
	ORG	300H
	db	6

;  Since segreloc is relocatable, the
; following segment causes an 'overwrite'
; warning at AVLINK time...

	DEFSEG  segover, start=2F0h
	seg segover
	db 7

;   The OVERLAID attribute may only be
; used for the same segment name in more
; than one module...

	DEFSEG segol, OVERLAID
	seg segol
	db 55H

;   Use of the CLASS= attribute...
; You may assign any applicable class
; attribute with the CLASS= statement

	DEFSEG  seg1code, CLASS=CODE
	SEG	seg1code
	db	8

; You may also assign a segment to the
; DATA class...

	DEFSEG	seg1data, CLASS=DATA
	SEG	seg1data
	db	9

;   Some chips use other classes,
; for instance the PAGE0 class, which
; places data on page0...
;
;	DEFSEG	segzero, CLASS=PAGE0
;	SEG	segzero
;	db	1

;   Note that any CLASS applicable to
; a chip has a predefined segment name
; known to the assembler, for example,

	SEG	CODE
	db	0AH

	SEG	DATA
	db	0BH

;   Note that the address field of the
; '.prn' file will show, after the addr,
;   & for a user-defined segment, 
;   ' for the pre-defined CODE segment, 
;   '' for the pre-defined DATA segment,
;   @ (if applicable) for the 
;            pre-defined PAGE0 seg,
;   * for an extern label

;   You may specify the alignment of a
; segment, using the ALIGN= attribute,
; where the value must be a power of 2 --

	DEFSEG	segalign, ALIGN=100H
	SEG	segalign
	db	0DH

;   You may also specify the block size
; of a segment, using BLOCK= where the
; value must also be a power of 2

	DEFSEG	segblock, BLOCK=200H
	SEG	segblock
	db	0EH


; (For compatibility purposes, certain
; synonyms have been added as valid AVMAC 
; pseudo-ops. These will be noted in the 
; next three sections.)

; *****************************************
;     USAGE OF DB, DW, DS pseudo-ops...
; *****************************************

;   DS is used to reserve a certain
; number of uninitialized BYTES of space...

	DS	8

;   RMB and DEFS are synonyms for DS..

	RMB	6
	DEFS    4

;   DW defines a 16-bit quantity,

	DW	123H

;   DW can define more than one word..

	DW	123H, 456H, 789H

;   DEFW is a synonym for DW..

	DEFW	5
	DEFW	100H, 256

;   FDB is like DW, except that it also
; allows two or more consecutive commas, 
; providing a zero value between each 2 
; commas..

	FDB	1,2,,3,,,4

;   DB defines one byte at a time

	DB	4
	DB	1,2,3

;   DB is also used for strings..

	DB	"hello, world"

;   DEFB and DEFM are synonyms for DB..

	DEFB	1, 2, "hello"
	DEFM	'world', 3

;   FCB is like DB, except (as in FDB) that
; it also allows two or more consecutive 
; commas, providing a zero value between
; each 2 commas..

	FCB	5,,6,7

;   FCC is a string-defining pseudo, with
; two valid syntaxes.  In the first, a
; decimal number followed immediately by a
; comma indicates that beginning with the
; next non-space or non-tab character, a
; string of length number is to be taken..

	FCC	4,string
	FCC	10,string

;   Note that a string which is not as long
; as the number count will be space-padded;
; the largest count allowed is 132.

;   In the second allowed syntax the first
; non-space or non-tab character after  the
; FCC pseudo-op is considered the string
; delimiter; until that character is seen,
; the string will continue to be processed.

	FCC	/monday/
	FCC	zmondayz
	FCC	7monday7
	FCC	&monday&

; *****************************************
;   Use of EQU and TEQ...
; *****************************************

; You may equate a symbol with a numeric
; value by means of the EQU and TEQ 
; directives.  The EQU pseudo-op simply
; assigns a value to a label, while the
; TEQ also allows the same label to be
; re-defined at a later time --

labelname   EQU    2
labeltwo    TEQ    3
labeltwo    TEQ    4

; ASET and DEFL are synonyms for TEQ..

labeltwo    ASET   5
labeltwo    DEFL   6

;   SET is also a synonym for TEQ except
; in the Z80, 8085, and 64180, where SET
; is already an instruction.

; Note that any label name MUST begin in
; column 1.


; *****************************************
;   Use of PUBLIC and EXTERN...
; *****************************************

; You can use symbols across modules
; (i.e., separate source files) by means
; of the PUBLIC and EXTERN pseudo-ops.

;   The PUBLIC pseudo-op is used to
; indicate that a symbol which is defined
; in the current module is to be referenced
; from a different module.

	      PUBLIC   otherlabel
otherlabel    DB    5

; Note that using the ALLPUBLIC option
; will render every label in the current
; module as PUBLIC 

;   XDEF and GLOBAL are synonyms for PUBLIC.

;   To reference a symbol which is defined
; in another module, use the EXTERN 
; pseudo-op...

	EXTERN   outlabel

; Using the EXTERN directive enables that
; label to be used in the current module, 
; even though it is not defined there.

;   Synonyms for EXTERN include EXT, EXTRN,
; EXTERNAL, and XREF.

; *****************************************
;   Use of PROCedures...
; *****************************************

; Using PROCedures enables you to use local
; symbols, that is, symbols whose identity
; is known only between the preceding PROC
; and succeeding ENDPROC directives.

proclab   PROC
..local   db   5
          ENDPROC

proc2lab  PROC
..local   db   6
          ENDPROC

; Note that the symbol '..local' will not
; cause a 'multiply-defined symbol' error.
; Note also, that local symbols must begin
; with TWO dots (..)



; *****************************************
; *****************************************
; *  MACROS and PREPROCESSOR DIRECTIVES   *
; *****************************************
; *****************************************

; *****************************************
;         Macros...
; *****************************************
;   MACROs allow you to create sequences
; of instructions that you can call up
; with a single line.  First, define your 
; macro, then you may call it...
;     definition of macro --

macname   %MACRO
          db     22H
          dw     3456H
          %ENDM

;     call of macro --

	macname

;	call it a second time --

	macname

;   MACROs may be passed 'parameters'...

mac2	%MACRO  param1, param2, param3
	db	param1
	db	param2
	db	param3
	%ENDM

	mac2  7H, 8H, 9H

;   A MACRO's parameters may be compared...

mac3	%MACRO  param1, param2
	%IFEQ  <param1>, <param2>
	db	1
	%ELSE
	db	2
	%ENDIF
	%ENDM

; and then called --

	mac3  A, A

	mac3  A, B

;   The parameter fields of a MACRO may be
; tested as to whether an actual parameter
; was utilized on this invocation of the
; MACRO --

mac4	%MACRO  param1, param2, param3
	%IFB	<param2>
	db	5
	%ELSE
	db	6
	%ENDIF
	%ENDM

	mac4  1, 2, 3

	mac4  4, ,5


; *****************************************
;         More on macro parameters...
; *****************************************

;
;  A Percent (%) sign before a 
; macro parameter causes it to 
; be  evaluated as a numerical 
; expression.
;
five	equ  5

mac5	%macro arg1
	dw arg1
	%endm

	mac5 % five+4
	mac5 % five*five

;
;  Angle brackets allow commas and 
; other things to be passed
;
mac6	%macro  arg1
	dw arg1
	%endm

	mac6 <1,2,3,4>

;
;  Carets (^) cause angle brackets 
; and control characters to be
; interpreted literally.
;
mac7	%macro arg1
	mac6 arg1 ;use previous macro.
	%endm

      ; in this example the brackets 
      ; must be passed down to
      ; MAC6 intact - thus the carets.
      
	mac7  <^<1,2,3,4^>>


;
;  Arguments may be inserted within strings 
; by capitalizing their letters and putting
; an ampersand next to them
;
mac8	%macro arg1
	db "ARG1 and &arg1 and &ARG1 and ARG1&ARG1"
	%endm

	mac8 ARF

;
;  Argument names within macros 
; may be used literally if they
; are preceded by a caret (^).
;
arg1	equ  10
mac9	%macro arg1
	dw arg1, ^arg1, arg1, ^arg1
	%endm

	mac9 5
      

; *****************************************
;         More on macros
; *****************************************

;   You may generate unique labels in a 
; MACRO with the GENSYM directive...

next	%MACRO
	%GENSYM  newname
newname db    4
	%ENDM

	next
	next

;   You may cause an immediate exit from
; a MACRO using the EXITM pseudo-op...

next2	%MACRO  arg1
	%IFB  <arg1>
	%EXITM
	%ENDIF
	db	7
	%ENDM

	next2
	next2  anyarg

;   You may concatenate text within the MACRO
; by the use of the ampersand (&) charac-
; ter...

next3	%MACRO  string
lab&string  db	string
	%ENDM

	next3  1
	next3  2

; *****************************************
; *****************************************
; *****    PREPROCESSOR DIRECTIVES    *****
; *****************************************
; *****************************************


; *****************************************
;    The REPT directive...
; *****************************************

;   Using preprocessor directives, you
; can perform the REPT (or, 'repeat')
; function...

	%REPT  5
	ds	2
	%ENDREPT

;   Nesting of REPT loops...

	%REPT  2
	db	2
	%REPT  3
	db	3
	%ENDREPT
	%ENDREPT

; *****************************************
;   The FOR directive is more powerful.
; *****************************************

; You can step through a FOR loop...

	%FOR  I = 1 to 3
	db	I
	%ENDFOR

;   You can non-contiguously step through-

	%FOR  J = 1 to 7 by 2
	db	J
	%ENDFOR

;   You can step backwards...

	%FOR  K = 10 to 2 by -2
	db	K
	%ENDFOR

;   You may use characters...

	%FOR  NUM  chars  abc
NAME	TEQ	0&NUM&H
	%ENDFOR

;   Or you may use strings...

	%FOR  M  in  "ONE", "TWO"
	db	M
	%ENDFOR

;   The FOR loop may be nested...

	%FOR  P = 1 to 3
	%FOR  Q = 4 to 8 by 2
	db	P
	db	Q
	%ENDFOR
	%ENDFOR


; *****************************************
;     The SWITCH directive...
; *****************************************

;   The SWITCH pseudo-op allows assembly
; of a particular piece of code, to the
; exclusion of other code...

swmac	%MACRO   ups
	%SWITCH  ups
	%CASE  1
	db	1
	%CASE  2
	db	2
	%DEFAULT
	db	7
	%ENDSW
	%ENDM

	swmac  1
	swmac  2
	swmac  3



; *****************************************
;     The END...
; *****************************************

;   The END pseudo-op must appear once in the
; file, at the very end (since assembly will
; cease as soon as END is recognized).
	END

