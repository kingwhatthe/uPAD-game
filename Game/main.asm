;******************************************************************************
;main.asm
;Name: Sabal Schuster
;Hardware: ATxmega128A1U
;Description: This is a game program. See README.md for full game description
;*******INCLUDES*************************************

.include "ATxmega128a1udef.inc"
;*******END OF INCLUDES******************************

;*******DEFINED SYMBOLS******************************
.equ ANIMATION_START_ADDR	=	0x2000 ;useful, but not required
.equ stack_init				=   0x3FFF
.equ LEVEL_START_ADDR		=   0x3000	; 
.equ HIGHSCORE_ADDR			=	0x2000 ;
.def COUNTER = r20 ; used to keep score
.def STAGE_COMING = r21 ; used to define the calling stage for interrupts
.def STAGE_GOING = r22 ; used to figure out which stage to go to next after an interrupt
.def CURSOR = r18 ; Used for cursor
.def TARGET = r23 ; Target bit for the cursor to land on
;*******END OF DEFINED SYMBOLS***********************

;*******MEMORY CONSTANTS*****************************
; data memory allocation
.dseg
.org HIGHSCORE_ADDR
; Allocated high score memory
.byte 1
.cseg
; Animation initialization
.org ANIMATION_START_ADDR
.db 0x7e, 0x7e, 0xbd, 0xbd, 0xff, 0xff, 0xdb, 0xdb, 0xff, 0xff, 0xe7, 0xe7, 0xff, 0xff, 0xe7, 0xc7, 0xc3, 0x83, 0x81, 0x01, 0x00, 0x00, 0x00, 0x81, 0xc3, 0xe7, 0xff, 0xfb, 0xfb, 0xfb, 0x7b, 0x7b, 0x3b, 0x3b, 0x9b, 0x9b, 0xcb, 0xcb, 0xe3, 0xe3, 0xf3, 0xf3, 0xf9, 0xf9, 0xf8, 0xf8, 0xf9, 0xf9, 0xf3, 0xf3, 0xe3, 0xe3, 0xcb, 0xcb, 0x9b, 0x9b, 0x3b, 0x3b, 0x9b, 0x9b, 0xcb, 0xcb, 0xe3, 0xe3, 0xf3, 0xf3, 0xf9, 0xf9, 0xf8, 0xf8, 0xf9, 0xf9, 0xf3, 0xf3, 0xe3, 0xe3, 0xcb, 0xcb, 0x9b, 0x9b, 0x3b, 0x3b, 0x7b, 0x7b, 0xfb, 0xfb, 0xfb, 0xfb, 0xef, 0xef, 0xee, 0xee, 0xed, 0xed, 0xeb, 0xeb, 0xe7, 0xe7, 0xef, 0xef, 0xcf, 0xcf, 0xaf, 0xaf, 0x6f, 0x6f, 0x6f, 0x6f, 0xaf, 0xaf, 0xcf, 0xcf, 0xe7, 0xe7, 0xeb, 0xeb, 0xed, 0xed, 0xee, 0xee, 0xef, 0xef, 0xef, 0xef, 0xff, 0xff
ANIMATION_END_ADDR:
.equ ANIMATION_SIZE = ANIMATION_START_ADDR - ANIMATION_END_ADDR

.org LEVEL_START_ADDR
;First (left) 2 bits: Cursor Width
;Middle 3 bits: Speed of Cursor (by a large factor)
;Last 3 bits: position of Target
.db 0b11000010, 0b11000011, 0b11000110, 0b11000100, 0b11001010, 0b11001011, 0b10010111,  0b10010101, 0b10010100, 0b10010101, 0b10001111, 0b10001101, 0b10010101, 0b10010100, 0b10010101, 0b10010100, 0b10010011,  0b10010001, 0b10010111, 0b10010001, 0b10100010, 0b10100011, 0b10100110, 0b10100100, 0b10100101, 0b01100100, 0b01100001, 0b01100100, 0b01100001,0b01100100, 0b01100101, 0b01100111, 0b01101011, 0b01101001, 0b01101010, 0b01101111, 0b01111010, 0b01111101, 0b01111001, 0b01111111
LEVEL_END_ADDR:
.equ NUMBER_OF_LEVELS = LEVEL_END_ADDR - LEVEL_START_ADDR
;*******END OF MEMORY CONSTANTS**********************





.cseg

;*******INTERRUPT VECTORS****************************
.org PORTF_INT0_vect ; Port F interrupt (S1)
	rjmp S1_PRESSED_ISR
.org PORTE_INT0_vect ; Port F interrupt (S1)
	rjmp S2_MB_PRESSED_ISR				
; .org TCC0_OVF_vect ; Timer overflow interrupt
;	rjmp DEBOUNCE_OVER_ISR	
;.org TCD0_OVF_vect ; Timer overflow interrupt
;	rjmp RESET_ANIMATION	
 ;*******END OF INTERRUPT VECTORS*********************

 ;*******MAIN PROGRAM*********************************

.org 0x00
	rjmp MAIN

.org 0x100
MAIN:
; initialize the stack pointer
;Below taken copied over from Stack example
	ldi r16, low(stack_init)
	out CPU_SPL, r16		;initialize low byte of stack pointer 
; sts or out will work above, but out will ONLY work for addresses 
;   less than 63 = 0x3F; CPU_SPL = 61, see ATxmega128A1Udef.inc
	ldi r16, high(stack_init)
	out CPU_SPH, r16		;initialize high byte of stack pointer 
; sts or out will work above, but out will ONLY work for addresses 
;END OF COPY

; Sets the timer interrupt to medium priority
	;ldi r16, TC_OVFINTLVL_MED_gc 
	;sts TCC0_INTCTRLA, r16
	
	; Set bit 3 of PORTF to trigger the interrupt
	ldi r16, 0b00000100		
	sts PORTF_INT0MASK, r16

	; Set bit 0 of PORTE to trigger the interrupt
	ldi r16, 0b00000001		
	sts PORTE_INT0MASK, r16

	; Set the PORTF interrupt to medium priority
	ldi r16, PMIC_MEDLVLEN_bm
	sts PORTF_INTCTRL, r16

	; Set the PORTE interrupt to low priority
	ldi r16, PMIC_LOLVLEN_bm
	sts PORTE_INTCTRL, r16

	; Set PMIC to low and medium priority (PMIC_LOLVLEN_bm and PMIC_MEDLVLEN_bm)
	ldi r16, 0x03	
	sts PMIC_CTRL, r16


	; Clear the PORTF_INTFLAGS (bit 0)
	ldi	 r16, 0b00000001			; PORT_INT0IF_bm
	sts  PORTF_INTFLAGS, r16

	; Clear the PORTE_INTFLAGS (bit 0)
	ldi	 r16, 0b00000001			; PORT_INT0IF_bm
	sts  PORTE_INTFLAGS, r16

	; set counter to zero
	ldi COUNTER, 0

	ldi XL, low(HIGHSCORE_ADDR)
	ldi XH, high(HIGHSCORE_ADDR)
	st X, r0 ; initialize high score to be zero

; initialize relevant I/O modules (switches and LEDs)
	rcall IO_INIT

; initialize (but do not start) the relevant timer/counter module(s)
	rcall TC_INIT

	sei
	

; "PLAY" mode
PLAY:

; Reload the relevant index to the first memory location
; within the animation table to play animation from first frame.
	ldi ZL, 0x00
	ldi ZH, 0x40 ; had to double the actual address because program memory stores words not bytes
	ldi r19, 0 ; set frame counter to 0 (used to check if end of animation is reached
	ldi STAGE_COMING, 1

PLAY_LOOP:

	cpi r19, ANIMATION_SIZE

; If r19 reaches the end of the animation, then branch back and reset Z pointer

	breq PLAY

	lpm r16, Z ; Load animation frame
	lpm r17, Z+
	sts PORTC_OUT, r16 ; Display frame

	; Turn on clock
	ldi r16, TC_CLKSEL_DIV1024_gc
	sts TCC0_CTRLA, r16

	; Set the frame rate to run at 200ms (40ms * 5 = 200ms = 5Hz)
	ldi r17, 5

TIMER_LOOP3:
	lds r16, TCC0_INTFLAGS
	sbrs r16, 0
	rjmp TIMER_LOOP3
	andi r16, 0b00001111
	sts TCC0_INTFLAGS, r16
	dec r17 ; decrement r17 to wait another TC clock cycle
	brne TIMER_LOOP3
	
	; Turn off timer
	ldi r16, TC_CLKSEL_OFF_gc
	sts TCC0_CTRLA, r16

	inc r19 ; increment animation counter

	cpi STAGE_GOING, 2
	breq GAMEPLAY

	rjmp PLAY_LOOP


GAMEPLAY:

	ldi STAGE_COMING, 2
	; Load level
	lpm r15, Z+

	;Set up target
	ldi r16, 0b00000111
	and r16, r15
	ldi TARGET, 1
	SHIFT_TARGET:
		lsl TARGET
		dec r16
		brne SHIFT_TARGET

	;Set up CURSOR
	ldi r16, 0b11000000
	and r16, r15
		;SHIFT_LOGIC:
		;lsr r16
		;cpi r16, 4
		;brpl SHIFT_LOGIC
	lsr r16
	lsr r16
	lsr r16
	lsr r16
	lsr r16
	lsr r16
	
	ldi CURSOR, 0
	ldi r17, 1
	SHIFT_CURSOR:
		lsl CURSOR
		or CURSOR, r17
		dec r16
		brne SHIFT_CURSOR

	; default set up cursor to size 2
	;ldi CURSOR, 0b00000011

	;Set up Speed
	ldi r16, 0b00111000
	and r15, r16
	lsr r15
	lsr r15
	lsr r15




	ldi r24, 0 ; If set its moving right
	rjmp GAME_LOOP
PLAY2:
	rjmp PLAY
GAMEPLAY2:
	rjmp GAMEPLAY

GAME_LOOP:

	sbrc CURSOR, 0
	rjmp START_LEFT

	sbrc CURSOR, 7
	rjmp START_RIGHT
	rjmp MOVE

	START_LEFT:
		ldi r24, 0
	rjmp MOVE

	START_RIGHT:
		ldi r24, 1
	
	MOVE:
		sbrs r24, 0
		lsl CURSOR

		sbrc r24, 0
		lsr CURSOR

	ldi r25, 0xff
	sts PORTC_OUTSET, r25
	sts PORTC_OUTCLR, CURSOR
	sts PORTC_OUTCLR, TARGET

	; Turn on clock
	ldi r16, TC_CLKSEL_DIV64_gc
	sts TCC0_CTRLA, r16

	; Set the frame rate to run at 200ms (40ms * 5 = 200ms = 5Hz)
	ldi r17, 75
	mov r16, r15 ; double the subtraction (make it go faster)
	lsl r16
	lsl r16
	lsl r16
	sub r17, r16 ; Speed up frame rate based on definition in level

TIMER_LOOP4:
	lds r16, TCC0_INTFLAGS
	sbrs r16, 0
	rjmp TIMER_LOOP4
	andi r16, 0b00001111
	sts TCC0_INTFLAGS, r16
	dec r17 ; decrement r17 to wait another TC clock cycle
	brne TIMER_LOOP4
	
	; Turn off timer
	ldi r16, TC_CLKSEL_OFF_gc
	sts TCC0_CTRLA, r16

	cpi STAGE_COMING, 5
	breq GAMEPLAY2

	cpi STAGE_GOING, 1
	breq PLAY2

	rjmp GAME_LOOP
; end of program (never reached)
DONE: 
	rjmp DONE
;*******END OF MAIN PROGRAM *************************

;*******SUBROUTINES**********************************

;****************************************************
; Name: IO_INIT 
; Purpose: To initialize the relevant input/output modules, as pertains to the
;		   application.
; Input(s): N/A
; Output: N/A
;****************************************************
IO_INIT:
; protect relevant registers
	push r16
; initialize the relevant I/O
	
	; Set S1 and S2 on SLB to input ports
	ldi r16, 0b00110000
	sts PORTF_DIRCLR, r16

	; Set LEDs to output ports
	ldi r16, 0b11111111
	sts PORTC_DIRSET, r16
	sts PORTC_OUTSET, r16 ; Turn off LEDs initially 

	; Set DIP switches to input ports
	sts PORTA_DIRCLR, r16

	; Set S1 and S2 of OOTB MB to input port
	ldi r16, 0b11000000
	sts PORTE_DIRCLR, r16

; recover relevant registers
	pop r16
; return from subroutine
	ret
;****************************************************
; Name: TC_INIT 
; Purpose: To initialize the relevant timer/counter modules, as pertains to
;		   application.
; Input(s): N/A
; Output: N/A
;****************************************************

TC_INIT:
; protect relevant registers
	push r16
	push r17
; initialize the relevant TC modules
	ldi r16, 0
	ldi r17, 39 ; Set the period to run at 40ms
	sts TCC0_PER, r17 ; Load low period register
	sts TCC0_PER+1, r16 ; Load high period register
	
; recover relevant registers
	pop r17
	pop r16
; return from subroutine
	ret


;****************************************************
; Name: S1_PRESSED_ISR 
; Purpose: (Insert purpose here)
; Input(s): STAGE_COMING, COUNTER, Memory at X
; Output: STAGE_GOING, COUNTER, Memory at X
;****************************************************

S1_PRESSED_ISR:

	push r24
	push r16
	push r17
	lds r17, CPU_SREG ; Save status register on stack
	push r17

	cpi STAGE_COMING, 1
	breq GO_STAGE2
	rjmp CHECK2

	GO_STAGE2:
		ldi STAGE_GOING, 2
		ldi ZL, 0x00
		ldi ZH, 0x60

	CHECK2:
		cpi STAGE_COMING, 2
		breq MANAGE_ATTEMPT
		rjmp CONTINUE
	MANAGE_ATTEMPT:
		mov r17, CURSOR
		and CURSOR, TARGET
		cpi CURSOR, 0
		brne HIT
		; Otherwise assume not hit
		;Reset COUNTER
		ldi COUNTER, 0
		; Set Z to starting address
		; Branch back to STAGE_1
		mov CURSOR, r17
		ldi STAGE_GOING, 1
		rjmp TIMER_LOOP5

	HIT:
		mov CURSOR, r17
		ldi STAGE_COMING, 5
		inc COUNTER
		ld r0, Z+
		ld r17, X
		cp r17, COUNTER
		brlo UPDATE_HS
		rjmp DONT_UPDATE

	UPDATE_HS:
		st X, COUNTER
	
	DONT_UPDATE:

	; Turn on clock
	ldi r16, TC_CLKSEL_DIV256_gc
	sts TCC0_CTRLA, r16
	ldi r24, 0
TIMER_LOOP5:
; Load OVFIF flag
	lds r16, TCC0_INTFLAGS

	;Check SL1
	lds r17, PORTF_IN
	sbrs r16, 0
	rjmp TIMER_LOOP5

	; If pressed and value in r24 is true
	sbrc r17, 2
	cpi r24, 1 
	breq FINISH_DEBOUNCING ; 

CONTINUE2:
	
	; if value is pressed, set r24 to true
	sbrs r17, 2 
	ldi r24, 1




	; reset flag
	ldi r16, 0b00000001
	sts TCC0_INTFLAGS, r16
	rjmp TIMER_LOOP5

FINISH_DEBOUNCING:
	
	;loop until done being pressed
	SMOL_LOOP:
		lds r16, TCC0_INTFLAGS
		sbrs r16, 0
		rjmp SMOL_LOOP
		; reset flag
		ldi r16, 0b00000001
		sts TCC0_INTFLAGS, r16
		;Check SL2
		lds r17, PORTF_IN
		sbrs r17, 2
		rjmp SMOL_LOOP


	
	ldi r24, 0 ; reset pressed flag (false)
	; Turn on clock
	ldi r16, TC_CLKSEL_DIV256_gc
	sts TCC0_CTRLA, r16


	CONTINUE:
	; Clear the PORTF_INTFLAGS (bit 0)
	ldi	 r16, 0b00000001			; PORT_INT0IF_bm
	sts  PORTF_INTFLAGS, r16


	pop r17
	sts CPU_SREG, r17 ; restore status register from stack
	pop r17
	pop r16
	pop r24
	reti

;****************************************************
; Name: S2_MB_PRESSED_ISR 
; Purpose: (Insert purpose here)
; Input(s): STAGE_COMING, COUNTER, Memory at X
; Output: N/A
;****************************************************
S2_MB_PRESSED_ISR:
	cli
	push r16
	push r17
	lds r17, CPU_SREG ; Save status register on stack
	push r17

	; Turn LEDs off
	ldi r16, 0xff
	sts PORTC_OUTSET, r16

	cpi STAGE_COMING, 2
	breq SET_CURRENT_SCORE

	cpi STAGE_COMING, 1
	breq SET_HIGH_SCORE

	SET_CURRENT_SCORE:
		mov r17, COUNTER
		rjmp START

	SET_HIGH_SCORE:
		ld r17, X
		rjmp START
	START: 
		; turn r17 into properly displayable stuff
		neg r17 
		dec r17
	; Continuously display score and poll for SLB2
	DISPLAY:
		lds r16, PORTF_IN
		sbrs r16, 3
		rjmp END_S2
		sts PORTC_OUT, r17
		rjmp DISPLAY

	END_S2:
	; Clear the PORTF_INTFLAGS (bit 0)
	ldi	 r16, 0b00000001			; PORT_INT0IF_bm
	sts  PORTF_INTFLAGS, r16

	pop r17
	sts CPU_SREG, r17 ; restore status register from stack
	pop r17
	pop r16
	sei
	reti
;*******END OF SUBROUTINES***************************