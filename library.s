	AREA library, CODE, READWRITE
	EXPORT uart_init
	EXPORT pin_connect_block_setup_for_uart0
	EXPORT setup_pins
	EXPORT validate_input
	EXPORT toggle_seven_seg
	EXPORT read_character
	EXPORT output_character
	EXPORT output_string
	EXPORT clear_display
	EXPORT change_display

	EXPORT change_display_digit
	EXPORT get_digit

	EXPORT from_ascii

test = "test1",0
	ALIGN
		
digits_SET   
    DCD 0x00003780  ; 0 
    DCD 0x00003000  ; 1  
	DCD 0x00009580	; 2
	DCD 0x00008780	; 3
	DCD 0x0000A300	; 4
	DCD 0x0000A680 	; 5
	DCD 0x0000B680	; 6
	DCD 0x00000380	; 7
	DCD 0x0000B780	; 8
	DCD 0x0000A380 	; 9
	DCD 0x0000B380	; A
	DCD 0x0000B600	; B
	DCD 0x00003480	; C
	DCD 0x00009700	; D
	DCD 0x0000B480	; E
	DCD 0x0000B080  ; F 
      ALIGN 

uart_init
	STMFD SP!,{lr}			;push link register to stack
	LDR r0, =0xE000C00C		;loads the memory address 0xE000C00C into r0
	MOV r1, #131			;copies decimal 131 into r1
	STR r1, [r0]			;stores r1 into the memory address at r0
	LDR r0, =0xE000C000		;loads the memory address 0xE000C000 into r0
	MOV r1, #120			;copies decimal 120 into r1
	STR r1, [r0]			;stores r1 into the memory address at r0
	LDR r0, =0xE000C004		;loads the memory address 0xE000C004 into r0
	MOV r1, #0			;copies decimal 0 into r1
	STR r1, [r0]			;stores r1 into the memory address at r0
	LDR r0, =0xE000C00C		;loads the memory address 0xE000C00C into r0
	MOV r1, #3			;copies decimal 3 into r1
	STR r1, [r0]			;stores r1 into the memory address at r0
	LDMFD sp!, {lr}			;pop link register from stack
	BX lr				;move pc,lr


pin_connect_block_setup_for_uart0
	STMFD sp!, {r0, r1, lr}		;Push stack
	LDR r0, =0xE002C000  		; PINSEL0 load pinsel0 r0
	LDR r1, [r0]			;Load pinsel0 contents to r1
	ORR r1, r1, #5			; Or with 5 dec.
	BIC r1, r1, #0xA		; Clear against 0xA
	STR r1, [r0]			; Store results to r0 in memory
	LDMFD sp!, {r0, r1, lr}		;Pop stack
	BX lr				;Branch back

setup_pins
	STMFD SP!,{lr, r1, r2, r3}

	LDR r1, =0xE0028008			;IODIR for Seven-Seg
	LDR r3, =0xB784				;Load 0xB784 (for bit manipulation) to r3
	STR r3, [r1]				;store results to r1

	LDMFD sp!, {lr, r1, r2, r3}
	BX lr 

validate_input					;checks that the inputted value (r0) is either hexadecimal or 'q'
	STMFD SP!, {lr, r1, r2, r3}		;returns output as boolean in (r4)

	CMP r0, #0x71				;'q'
	BEQ quit

	CMP r9, #0				;not accepting input (bar 'q') when display is off
	BEQ vi_invalid		

	CMP r0, #0x30				;<0x30 invalid
	BLT vi_invalid

	CMP r0, #0x66				;>0x66 invalid
	BGT vi_invalid

	CMP r0, #0x39				;<=0x39 valid number
	BLE vi_valid_number
	
	CMP r0, #0x61				;>=0x61 valid uppercase letter
	BGE vi_valid_letter_upper

	CMP r0, #0x46				;>0x46 invalid
	BGT vi_invalid
	
	CMP r0, #0x41				;>=0x41 valid uppercase letter
	BGE vi_valid_letter_upper
	
vi_valid_number

	MOV r4, #1				;return 1 for r4

	B vi_exit

vi_valid_letter_lower

	MOV r4, #1				;return 1 for r4

	B vi_exit

vi_valid_letter_upper

	MOV r4, #1				;return 1 for r4
	
	B vi_exit

vi_invalid

	MOV r4, #0				;return 0 for r4

vi_exit

	LDMFD SP!, {lr, r1, r2, r3}
	BX lr

get_digit					; returns (in r4) the hexadecimal number's (globally at r8) digit r0
						; last-most digit is 0, first-most digit is n where n is number of steps needed to get to said digit
						
	STMFD SP!, {lr, r1, r2, r3}

	MOV r1, #0xF
	MOV r2, r8
	MOV r3, #0

	CMP r0, #0
	BEQ get_digit_0

	CMP r0, #1
	BEQ get_digit_1

	CMP r0, #2
	BEQ get_digit_2

	CMP r0, #3
	BEQ get_digit_3

get_digit_0
	
	AND r2, r2, r1	

get_digit_0_loop
	
	CMP r2, #0
	BEQ get_digit_end

	ADD r3, r3, #1
	SUB r2, r2, #1
	
	B get_digit_0_loop


get_digit_1

	MOV r1, r1, #4

	AND r2, r2, r1

get_digit_1_loop

	CMP r2, #0xF
	BLE get_digit_end

	ADD r3, r3, #1
	SUB r2, r2, #0x10
	
	B get_digit_0_loop

get_digit_2

	MOV r1, r1, #8

	AND r2, r2, r1

get_digit_2_loop

	CMP r2, #0xFF
	BLE get_digit_end

	ADD r3, r3, #1
	SUB r2, r2, #0x100

	B get_digit_2_loop

get_digit_3

	MOV r1, r1, #12
	
	AND r2, r2, r1

get_digit_3_loop

	CMP r2, #0xFFF
	BLE get_digit_end

	ADD r3, r3, #1
	SUB r2, r2, #0x1000

	B get_digit_3_loop

get_digit_end

	MOV r4, r3

	LDMFD SP!, {lr, r1, r2, r3}
	BX lr

from_ascii					; converts (singe-digit) number at r0 from ascii number to normal number, returning at r4
	STMFD SP!, {lr, r1, r2, r3}

	CMP r0, #0x39
	BLE fa_number

	CMP r0, #0x61
	BGE fa_lower

	CMP r0, #0x41
	BGE fa_upper

fa_number

	SUB r4, r0, #0x30

fa_upper
	
	SUB r4, r0, #54

fa_lower

	SUB r4, r0, #86

fa_exit

	LDMFD SP!, {lr, r1, r2, r3}
	BX lr

toggle_seven_seg
	STMFD SP!, {lr, r0}

	CMP r9, #0				;check if seven seg is off
	BNE tss_off

tss_on

	MOV r9, #1				;set the flag to #1 (r9) to say seven seg is on

	MOV r0, r6

	BL change_display			;change display

	B tss_exit 

tss_off
	
	MOV r9, #0				;set the flag to #0 (r9) to say seven seg is off
	BL clear_display			;clear (turn off) display

tss_exit

	LDMFD SP!, {lr, r0}
	BX lr

change_display				;Displays hex value passed in r0
	STMFD SP!,{lr, r1, r2, r3}
	
	MOV r9, #1
	MOV r6, r0

	LDR r1, =0xE0028000 		; Base address 
	LDR r3, =digits_SET 
	MOV r0, r0, LSL #2 		; Each stored value is 32 bits 
	LDR r2, [r3, r0]   		; Load IOSET pattern for digit in r0 
	STR r2, [r1, #4]   		; Display (0x4 = offset to IOSET) 

	LDMFD sp!, {lr, r1, r2, r3}
	BX lr

change_display_digit			;Displays hex value passed in r0 at digit r4
	STMFD SP!,{lr, r1, r2, r3, r5}
	
	MOV r9, #1
	MOV r6, r0			; Save our r0 at r6
	
	MOV r5, #1			; Initial 1 for selecting which pin to HIGH

	ADD r4, #0x2			; DIGIT SEL IS OFFSET BY 2. BEGINS AT PIN 2. r4 + 2 is pin that gets HIGH'd
	
	MOV r5, r5, LSL r4		; Shift initial 1 bit by r4

	MVN r5, r5			; High all bits besides r4 (DIGIT SEL IS OFFSET BY 2. BEGINS AT PIN 2. 0 & 1 RESERVED)
	;ADD r5, r5, #1

	AND r5, r5, #0x3C		; Clear all bits (AND) besides 6 bits in 0x3C. Will be used in later OR

	LDR r1, =0xE0028000 		; Base address for 7seg
	LDR r3, =digits_SET 
	MOV r0, r0, LSL #2 		; Each stored value is 32 bits 
	ADD r3, r0
	LDR r2, [r3] 	  		; Load IOSET pattern for digit in r0 
	ORR r2, r2, r5			; HIGH bits not being used (HIGH-OFF TO CHOOSE DIGIT)
	STR r2, [r1, #4]   		; Display (0x4 = offset to IOSET) 

	LDMFD sp!, {lr, r1, r2, r3, r5}
	BX lr
	
clear_display
	STMFD SP!,{lr, r1, r2}
	
	MOV r9, #0
	
	LDR r1, =0xE002800C							;Load P0xCLR to r1
	LDR r2, =0xB784								;Load number (to r2) for bits of seven-segment display
	STR r2, [r1]								;Store number in P0xClr at r1
	
	LDMFD sp!, {lr, r1, r2}
	BX lr
	
read_character 				;Begin Receive Character block
	STMFD SP!,{lr, r3, r4, r5}
read_character_2
	LDR r3, =0xE000C014		;loads the address of uart0 into register r3 
	
	LDRB r4, [r3]			;loads the bytes at address r3 into r4 (RXFE - RDR)
	
	MOV r5, #1			;immediate value 1 is copied into r5
	AND r5, r4, r5			;logically AND r4 and r5 to compare the LSB(RDR) of r4
	
	CMP r5, #1			;if the value of r5 is one, we are ready to receive data
	BNE read_character_2		;else redo the process
	
	; Receiving
	
	LDR r3, =0xE000C000		;loads the address of the receive buffer register into r5
	LDR r0, [r3]			;hex value at r3 is loaded into r8
read_character_break
	LDMFD sp!, {lr, r3, r4, r5}
	BX lr

output_character 				;Begin Transmit Character block
	STMFD SP!,{lr, r3, r6, r5}
output_character_2
	LDR r3, =0xE000C014			;loads address of uart0 into register r3
	
	LDRB r6, [r3]				;loads bytes at address r3 into r6 (RXFE - RDR)
	
	MOV r5, #32					;immediate value 32 (00010000) copied into r5		
	AND r5, r6, r5				;logically AND r6 and r5 to compare the 5th bit(THRE) of r6
	
	CMP r5, #32					;if the fifth bit is 1, then we are ready to transmit
	BNE output_character_2		;else we redo the process
	
	; Transmitting
	
	LDR r5, =0xE000C000			;loads the address of the transmit holding register (same as receive buffer)
	
	STR r0, [r5]				;stores the value of r0 into the address at r5
	LDMFD sp!, {lr, r3, r6, r5}
	BX lr
		
output_string
	STMFD SP!,{lr, r0, r1}
	
output_string_2
	LDRB r0, [r4], #1      		;Load =prompt contents from memory (r4) to r0, one byte at a time. Then increments memory address, r4, by 1.
	BL output_character			;Branch and link to output_character
	
	CMP r0,#0					;compares r0 to null terminator
	BNE output_string_2			;if equal we continue on with program
	
	BL new_line
	
	LDMFD sp!, {lr, r0, r1}
	BX lr
	
new_line
	STMFD SP!,{lr, r10}
	MOV r10, r0					;saves contents of r0 into r10 before using it
	MOV r0, #0xA				;new line character copied into r0
	BL output_character			;branch and link to output character
	MOV r0, #0xD				;carriage return copied into r0
	BL output_character			;branch and link to output character
	MOV r0, r10					;takes saved content from r10 and copies into r0
	;CMP r8, #0xD				;checks if r8 has  carriage return and jumps to clear it
	;BEQ clear_read_character
	LDMFD sp!, {lr, r10}
	BX lr	 

quit
	MOV r7, #5
	END
