	.global get_morse

#include <avr/io.h>

	;;; Each led on the 7 segment display
	
	A = _BV(7)	; top
	B = _BV(1) 	; upper right
	C = _BV(2)	; lower right
	D = _BV(3)	; bottom
	E = _BV(4)	; lower left
	F = _BV(5)	; upper left
	G = _BV(6)	; middle

	;;; The pins to output to for each letter
	;;; Giving a 0 will turn the pin to an output so the not operator (~) is used to reverse it

	CHAR_A = ~(A | B | C | E | F | G)
	CHAR_B = ~(C | D | E | F | G)
	CHAR_C = ~(A | D | E | F)
	CHAR_D = ~(B | C | D | E | G)
	CHAR_E = ~(A | D | E | F | G)
	CHAR_F = ~(A | E | F | G)
	CHAR_G = ~(A | C | D | E | F)
	CHAR_H = ~(C | E | F | G)
	CHAR_I = ~(B | C)
	CHAR_J = ~(B | C | D | E)
	CHAR_K = ~(A | C | E | F | G)
	CHAR_L = ~(D | E | F)
	CHAR_M = ~(A | C | E)
	CHAR_N = ~(A | B | C | E | F)
	CHAR_O = ~(A | B | C | D | E | F)
	CHAR_P = ~(A | B | E | F | G)
	CHAR_Q = ~(A | B | C | F | G)
	CHAR_R = ~(A | E | F)
	CHAR_S = ~(A | C | D | F | G)
	CHAR_T = ~(D | E | F | G)
	CHAR_U = ~(B | C | D | E | F)
	CHAR_V = ~(B | C | D | F)
	CHAR_W = ~(B | D | F)
	CHAR_X = ~(B | C | E | F | G)
	CHAR_Y = ~(B | C | D | F | G)
	CHAR_Z = ~(A | B | D | E | G)

	ALL_SEGS = A | B | C | D | E | F | G 	; Used to make all pins outputs
	_ = 0b00110110	; Used as an error character which displays 3 horizontal lines

;;; This subroutines purpose is to convert morse code into a character

;;; r24: Input as morse code that is in byte form
;;; r24: Output as a character defined as a set of bits for the 7 segment display
    
get_morse:

	push r30 	; Push r30 and r31 onto the stack so that their previous values can be saved
	push r31

	ldi r30, lo8(morse_to_char) 	; Set r30 to the lower byte of Z
	ldi r31, hi8(morse_to_char) 	; Set r31 to the upper byte of Z
				    	; Z points to the table of bytes morse_to_char

	add r30, r24	; Add r24 to the pointer index
	brcc 1f     	; Skip incrementing upper byte if no overflow occurs
	inc r31    	; If an overflow occurs add 1 to the upper byte of Z
1:		
	lpm r24, Z  	; Load the value at the index Z of morse_to_char into r24
	
	pop r31     	; Pop r30 and r31 from the stack so the previous values are restored for future usage
	pop r30

	ret         	; Return from subroutine


;;; This table is structured so that if you view the morse code byte as an index
;;; it points to the position of that letter in the table. For instance the morse code of
;;; B is ...- which in byte from is 01111000. As an integer this is equal to 120 in decimal
;;; The index 120 in the table is CHAR_B

;;; The _ label is the error character

morse_to_char:		
	.byte _, _, _, _, _, _, _, _, CHAR_T, _, _, _, CHAR_M, _, CHAR_O, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_G, CHAR_Q, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_Z, _, _, _, _, _, _, _, _, _, _, _, CHAR_N, _, CHAR_K, CHAR_Y, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_C, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_D, CHAR_X, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_B, _, _, _, _, _, _, _, CHAR_E, _, _, _, CHAR_A, _, CHAR_W, CHAR_J, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_P, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_R, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_L, _, _, _, _, _, _, _, _, _, _, _, CHAR_I, _, CHAR_U, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_F, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_S, CHAR_V, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_H
