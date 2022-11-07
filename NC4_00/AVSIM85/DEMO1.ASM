$ALLPUBLIC
;	Demo Program for 8085
;	Written by Ken Anderson
;	Sept 1985
;
;	This program is intended to demonstrate features of
;	the 8085 CPU that are easily visualized on Avocet's
;	AVSIM 8085 Simulator.
;
;	The functions of this program include:
;
;	1. MAIN routine reads the bit pattern from Port B of 8355
;	   and cycles it on the LEDs attached to Port A of 8355
;	   (like a light chaser) where HI bits represent
;	   LIGHT ON (or vice-versa, of course).
;	   The light chaser rotates alternately to the right,
;	   then to the left at a rate corresponding to
;	   the binary value of the bit pattern.
;
;	2. R7.5 interrupt routine changes the rotation direction
;	   on each timeout of 8155 Timer.
;
;	3. Port A of 8155 is supporting a second task:
;	   On R6.5 interrupt - caused by strobed  input of A-Intr,
;	   read ASCII character from port, and buffer it.
;	   Special character <CR> clears the buffer contents - for
;	   visual effect in the simulator!
;

;	Variable Map

BFSIZE	EQU	31		; Maximum Buffer size 
RETURN	EQU	0DH		; Carriage Return
;	Register Usage:

;	D	; store switch settings
;	E	; bit 0 is direction flag
;	C	; input temporary - R6.5 routine
;	HL	; R6.5 Int routine Buffer pointer - next free position
;	B	; R6.5 Int routine Buffer counter

;	I/O Map

	SEG	IOSPACE,START=0

CS8155:	DS	1	; Command/Status Reg of 8155 in I/O Space
PA8155:	DS	1 	; Port A of 8155 in I/O Space
PB8155:	DS	1
PC8155:	DS	1	; Port C of 8155 in I/O Space
TL8155:	DS	1	; Timer Low part of 8155 in I/O Space
TH8155:	DS	1	; Timer High part of 8155 in I/O Space

	DEFSEG	PA8355SEG,START=8,CLASS=IOSPACE
	SEG	PA8355SEG
PA8355:	DS	1 ; Port A of 8355 in I/O Space
PB8355:	DS	1 ; Port B of 8355 in I/O Space
DA8355:	DS	1 ; DDR of Port A of 8355 in I/O Space
DB8355:	DS	1 ; DDR of Port B of 8355 in I/O Space

	DEFSEG	ZEROSEG,START=0
	SEG	ZEROSEG

ZERO:	JMP	MAIN		; Restart

	DEFSEG	PAINTRSEG,START=34H
	SEG	PAINTRSEG

PAINTR:	JMP	R65		; Port A INTR routine

	DEFSEG	TMRINTRSEG,START=3CH
	SEG	TMRINTRSEG
	
TMRINTR:JMP	R75		; 8155 Timer routine - uses edge triggered input
	

	DEFSEG	BFSEG,START=40H
	SEG	BFSEG
	
BFBASE:	DS	BFSIZE		; R65 Int routine Buffer space

	DEFSEG	STSEG,START=0E0H
	SEG	STSEG
	DS	20H
STACK:				; Stack at top

	DEFSEG	MAINSEG,CLASS=CODE,START=100H
	SEG	MAINSEG

MAIN:	LXI	SP,STACK
	; Init LEDS - 8355
	XRA	A
	OUT	DB8355	; Port B DDR Inputs
	DCR	A
	OUT	DA8355	; Port A DDR Outputs
	; Init 8155
	XRA	A
	CALL	SETIMER		; Preset timer H/L
	MVI	A,01010110B	; 8155: IEA, Port A strobed Input
	OUT	CS8155
	; Init Int task pointer
	LXI	H,BFBASE
	MVI	B,0
	MVI	A,00001001B	; Set R6.5 Int Enable
	SIM
	EI			; Int service ON
	IN	PB8355	; get switch settings
NEWPTRN:MOV	D,A		; save switches
        OUT	PA8355	; Update LEDS
	CALL	SETIMER		; Time constant for direction change
ROTATE:	MVI	A,1		; make mask for direction bit
	ANA	E		; set flags
	IN	PA8355	; get current value -> read output port
	JNZ	ROTLEFT		; HI -> to left
	RRC			; rotate right
	RRC			; one to nullify rotleft
ROTLEFT:RLC			; rotate left
        OUT	PA8355	; Update LEDS
        IN	PB8355	; Test switches
	CMP	D		; change?
	JZ	ROTATE		; No, keep cycling
	JMP	NEWPTRN		; Yes, reload

; Subroutine to show stack working
SETIMER:OUT	TL8155	; Time constant in Acc
	ORI	11000001B	; Continuous pulses mode +  offset
	OUT	TH8155
	MVI	A,11010110B	; Start timer
	OUT	CS8155
	RET

; R7.5 is connected to TimerOut pulse by 'Set' 'opTions' command
R75:	INR	E		; Toggle BIT 0: Direction
	EI
	RET

; R6.5 is connected to Intr-A pin of 8155 by 'Set' 'opTions' command
R65:	PUSH	PSW		; Save ACC & flags
	IN	PA8155	; Get data & clear int request
	MOV	C,A		; Save data
	CPI	RETURN		; <CR>?
	JNZ	BUFCHAR		; No, buffer character
CLEAR:	DCX	H		; Yes, clear buffer to zeroes
	MVI	M,0		; from back to front
	DCR	B		
	JNZ	CLEAR		; until at front
	JMP	EXIT

BUFCHAR:MOV	A,B		; get char count in buffer
	CPI	BFSIZE		; Check if space left in buffer
	JNC	EXIT		; No room left
	MOV	M,C		; Yes, save char
	INX	H
	INR	B
EXIT:	POP	PSW
	EI
	RET 

	END

