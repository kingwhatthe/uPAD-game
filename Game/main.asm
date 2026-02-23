;******************************************************************************
;  File name: lab2_s26_4_skeleton.asm
;  Author: Christopher Crary
;  Last Modified By: Sabal Schuster
;  Last Modified On: 14 Feb 2026
;  Purpose: To allow LED animations to be created with the OOTB uPAD, 
;			OOTB SLB, and OOTB MB.
;
;  NOTE: The use of this file is NOT required! This file is just given
;        as an example for how to potentially write code more effectively.
;******************************************************************************
;Lab 1, Section 1
;Name: Sabal Schuster
;Class #: 11091
;PI Name: William Shaul
;Description: This program allows the user to create and playback LED animations on the OOTB uPAD and SLB
;*******INCLUDES*************************************

; The inclusion of the following file is REQUIRED for our course, since
; it is intended that you understand concepts regarding how to specify an 
; "include file" to an assembler. 
.include "ATxmega128a1udef.inc"
;*******END OF INCLUDES******************************

;*******DEFINED SYMBOLS******************************
.equ ANIMATION_START_ADDR	=	0x2000 ;useful, but not required
.equ stack_init				=   0x3FFF
.equ HIGHSCORE_ADDR			=	0x2000 ;
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
;*******END OF MEMORY CONSTANTS**********************

;*******INTERRUPT VECTORS****************************
.org PORTF_INT0_vect ; Port F interrupt (S1)
	rjmp S1_PRESSED_ISR		
; .org TCC0_OVF_vect ; Timer overflow interrupt
;	rjmp DEBOUNCE_OVER_ISR	
;.org TCD0_OVF_vect ; Timer overflow interrupt
;	rjmp RESET_ANIMATION	
 ;*******END OF INTERRUPT VECTORS*********************


;*******MAIN PROGRAM*********************************
.cseg
; upon system reset, jump to main program (instead of executing
; instructions meant for interrupt vectors)
.org 0x00
	rjmp MAIN

; place the main program somewhere after interrupt vectors (ignore for now)
.org 0x100		; >= 0xFD
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
	ldi r16, TC_OVFINTLVL_MED_gc 
	sts TCC0_INTCTRLA, r16
	
	; Set bit 3 of PORTF to trigger the interrupt
	ldi r16, 0b00000100		
	sts PORTF_INT0MASK, r16

	; Set the PORTF interrupt to low priority
	ldi r16, 0b00000001
	sts PORTF_INTCTRL, r16

	; Set PMIC to low and medium priority (PMIC_LOLVLEN_bm and PMIC_MEDLVLEN_bm)
	ldi r16, PMIC_LOLVLEN_bm		
	sts PMIC_CTRL, r16

	; Clear the PORTF_INTFLAGS (bit 0)
	ldi	 r18, 0b00000001			; PORT_INT0IF_bm
	sts  PORTF_INTFLAGS, r18

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
	ldi ZH, 0x40
	ldi r19, 0

PLAY_LOOP:

	cpi r19, ANIMATION_SIZE

; If index values are equal, branch back to "PLAY" to
; restart the animation.

	breq PLAY

; Otherwise, load animation frame from table, 
; display this "frame" on the relevant LEDs,
; start relevant timer/counter,
; wait until this timer/counter overflows (to more or less
; achieve the "frame rate"), and then after the overflow,
; stop the timer/counter,
; clear the relevant OVFIF flag,
; and then jump back to "PLAY_LOOP".

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

	inc r19

	rjmp PLAY_LOOP



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

	; Set S1 of OOTB MB to input port
	ldi r16, 0b10000000
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


S1_PRESSED_ISR:

	push r18
	push r17
	lds r17, CPU_SREG ; Save status register on stack
	push r17

	dec r16 ; count up

	; Start clock
	;ldi r17, TC_CLKSEL_DIV1024_gc
	;sts TCC0_CTRLA, r17

	; Clear the PORTF_INTFLAGS (bit 0)
	ldi	 r18, 0b00000001			; PORT_INT0IF_bm
	sts  PORTF_INTFLAGS, r18
	
	; Turn off checking for the button press (turn off low priority)
	;ldi r17, PMIC_MEDLVLEN_bm
	;sts PMIC_CTRL, r17	
	END:
		ldi r16, 0xff
		sts PORTC_OUTSET, r16
		ldi r16, 0b00010000
		sts PORTC_OUTTGL, r16
		rjmp END


	pop r17
	sts CPU_SREG, r17 ; restore status register from stack
	pop r17
	pop r18
	reti
;*******END OF SUBROUTINES***************************