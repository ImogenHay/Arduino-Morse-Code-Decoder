;;;Main file for getting button presses and constructing the morse code byte
;;;This button detection system is mainly from the lab8 example as rewriting it is pointless

	CPU_FREQ = 16000000
	TICKS_PER_SEC = CPU_FREQ / (256 * 1024)

	DECISION_LIMIT = TICKS_PER_SEC / 5 ;
	TIMEOUT = 7 * (DECISION_LIMIT / 3)

	BUTTON = 0

#define __SFR_OFFSET 0
#include <avr/io.h>

;;; this is the entry point to the user code, called from init.S. We
;;; do the setup of ports, timer and interrupts, then we go to an
;;; eternal loop because all the work is done in the interrupt service
;;; routines. 

	.section .text
	.global main
main:	
	;; make these pins output:
	ldi r24, 0xff
	out DDRD, r24

	;;Clear the registers used for storing morse code input
	clr r20 ; This register is used to count how many dots/dashes have been input
	clr r21 ; This register stores the dots
	clr r22 ; This register stores dashes
	
	;; setup for the button, DDRB0 is automatically an input.
	sbi PORTB, _BV(BUTTON) 	; switch on the pull-up. Released
				; button is 1, depressed button read as 0.

	;; set up the timer ([ATmega328p], Section 15.11.1 (p126))

	clr r16
	sts TCCR1A, r16 	; setting timer output mode: no output
				; pin used, normal counting up. 

	ldi r16, TIMEOUT	; time in 16ms ticks to detect a TIMEOUT,
				; about 400ms.
				; long and short button presses. 
	sts OCR1AH, r16		; move into high byte of compare match
				; register A
	
	clr r16			; low byte of compare match is just 0.
	sts OCR1AL, r16		; note 16bit registers always have to
				; be written high byte first, see
				; [ATmega328p], Chapter 15.3, p 106

	;; enable input capture interrupt (to time button presses) and
	;; timer overflow interrupt:
	ldi r16, _BV(ICIE1) | _BV(OCIE1A)
	sts TIMSK1, r16

	;; enable noise canceller, set prescaler to 1024, and start
	;; timer in normal mode, [ATmega328p] section 12.11.2 (p128).
	ldi r16,  _BV(ICNC1) | _BV(CS12) | _BV(CS10) | _BV(WGM12)
	sts TCCR1B, r16

	clr r19			; reset overflow flag to defined state

	sei			; enable interrupts globally.

fourE4:	rjmp fourE4 		; do nothing :-) just wait for the
				; interrupts to occur -- forever.
	;; end of setup

;;; This interrupt service routine is currently called whenever timer1 has
;;; an overflow, ie when more than 4s have elapses since the last button release. 
	
	.global timer1_compa_isr  ; export symbol to overwrite weak
				; definition in init.S

;;; This is the start of the interrupt service routine:
timer1_compa_isr:			

	push r16	
	in r16, SREG		; save the status register.
	push r16

	;; check whether we are waiting for a button press or release:
	lds r16, TCCR1B
	sbrs r16, ICES1 	; skip if waiting for positive edge (ie for button release)
	rjmp awaiting_press

awaiting_release:
	;;  make sure also an overly long press is always recognised
	;;  as a long press, irrespective of a timer overrun:

	ser r19 		; using r19 as a flag to indicate a
				; timer overflow has occured.
	rjmp 1f

awaiting_press:	
	;; if we are waiting for a button press, then more time than
	;; 700ms has elasped since the last release.
		
	ldi r16, _BV(BUTTON)

	out PORTB, r16		
	
1:	pop r16
	out SREG, r16 		; restore status register
	pop r16

	;; Check if the button counter is greater than 1 after waiting 700ms
	;; If it is that means that morse code has been input and the character is ready to be displayed
	cpi r20, 0x1
	brlo 2f  	; Skip the morse code display if r20 is 0

	rcall morse_code_done	; Call the subroutine for when morse code is ready to be displayed
2:	

	reti

;;; This interrupt service routine times the duration of button
;;; presses. It is also involved in timing button releases as it
;;; always resets timer1 when called.
;;; It is called whenever the signal at ICP1 (PORTB0) changes in a
;;; certain direction. If we are called for a negative edge (button
;;; has just been depressed), we go on waiting for a positive edge
;;; (button will be released) and vice-versa.
	
	.global timer1_cpt_isr

timer1_cpt_isr:

	push r8

	in r8, SREG 		; save the status register.
	push r8

	lds r8, ICR1L		; get the timer count when the capture event happened.
	lds r8, ICR1H           ; we discard the low part, only
				; interested in the high part, but
				; reading low byte is necessary to get
				; a correct high byte in ICR1H, see
				; documentation [ATmega328p] Section 15.11.7 p131 
	push r17				

	;; debounce button:

	mov r17,r19		;  If there is no timer-overflow (ie a
				;  very long button press and
	or r17,r8		;  ICR1H is still zero, then 
				;  less than 16ms have elapsed since
				;  last release or press
	breq debounce		;  and we do nothing

	clr r17
	sts TCNT1H, r17 	; reset timer, first writing the high byte to the latch
	sts TCNT1L, r17		; then the low byte -- Section 16.3 of [328] again.

	;; check whether we were looking for a positive or a negative edge:
	lds r17, TCCR1B
	sbrs  r17, ICES1	; skip next instruction if positive edge dedection.
	
	rjmp pressed		; we have a negative edge ie button
				; has been pressed

	;; positive edge, button has been released
	rcall released

	andi r17, ~(_BV(ICES1)) ; we have had positive edge, so next
				; time looking for negative edge
	rjmp end_isr

	
pressed:
	ori r17, _BV(ICES1)	; next time detect positive edge, ie a
				; button release.

end_isr:
	sts TCCR1B, r17 	; write r17 to TCCR1B to activate the
				; change in edge detection.
	
debounce:
	pop r17
	pop r8
	out SREG, r8		; restore status register
	pop r8

	reti

;;; This subroutine handles the detection of a button release (ie the
;;; end of a button press)
;;; It expects the durations of button presses in 16ms ticks in r8

released:
	
	;; When the button is released shift the two registers to the left
	;; This is so that adding 1 will then change the next bit
	;; This is done before adding to them so that they are not shifted 1 too many
	lsl r21 
	lsl r22

	inc r20 ; Increase the button press counter by 1

	ldi r24, 0xff  ; Clear the display when a new letter is being input
	out PORTD, r24

	push r16

	tst r19 		; Did we have a timer overflow
				; (ie more than TIMEOUT time since the
				; last released of the button?
	brne long_press		; if yes, then signal is a long
				; press in any case

	;; is the signal longer than DECISION_LIMIT?
	ldi r16, DECISION_LIMIT
	cp r8,r16
	brcs short_press		; if it is shorter jump to label short
	
	
long_press:
	ldi r16, _BV(BUTTON) ; pull-up for button on.
	out PORTB, r16

	inc r22 ; Set the right most bit of the dash register to 1

	rjmp 1f

short_press:

	ldi r16, _BV(BUTTON) ; pull-up on.
	out PORTB, r16	

	inc r21 ; Set the right most bit of the dash register to 1

1:
	pop r16
	clr r19			; clear overflow flag in case it was set
	ret

;;; This subroutine handles converting the dots and dashes stored in r21 and r22
;;; into a morse code byte and calling the character conversion subroutine

;;; This will correct the bit positions and then set r21 to the left nibble and r22
;;; to the right nibble of r24 to then be converted to a character

loop:
	;; This loop is to shift the bits if the length of the morse code is less than 4
	lsl r21
	lsl r22

	inc r20 ; r20 is used here so that when it reaches 4 the loop ends

morse_code_done:

	;; Jump to the loop if the button counter is less than 4 and loop until the counter
	;; is equal to 4 so that the bit for the first dot/dash is far left
	;; This will loop (4 - button presses)
	cpi r20, 0x4
	brne loop

	;; shift r21 to the left 4 times so it is in the left nibble
	lsl r21 
	lsl r21
	lsl r21
	lsl r21
	
	;; r24 is the parameter for the get_morse subroutine so we set r21 to the left nibble
	;; and r22 to the right nibble
	clr r24
	add r24, r21
	add r24, r22

	rcall get_morse ; Set r24 to the bit pattern of the letter that the morse code points to

	out PORTD, r24 ; Turn on the bits of port D to display the letter stored in r24

	;; Clear the morse code registers for a new letter to be input
	clr r20
	clr r21
	clr r22

	ret
