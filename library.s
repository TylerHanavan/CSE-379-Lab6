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
	STMFD SP!, {lr}				;returns output as boolean in (r4)

	CMP r0, #0x71				;'q'
	BEQ quit

	;CMP r9, #1 
	;BNE vi_exit_false			;Not accepting input at this time	

	CMP r0, #0x30				;Less than 0x30, invalid input
	BLT vi_exit_false

	CMP r0, #0x46				;Greater than 0x46, invalid input
	BGT vi_exit_false

	CMP r0, #0x39				;Less than equal 0x39, valid input
	BLE vi_exit_true_num	
	
	CMP r0, #0x41				;Greater than equal 0x41, valid input
	BGE vi_exit_true_let

	B vi_exit_false

vi_exit_true_let					;change display and return 0x1 in r4

	MOV r4, #0x1
	
	SUB r0, r0, #0x41
	ADD r0, r0, #10
	
	BL clear_display

	BL change_display
	;LDR r4, =test
	;BL output_string

	B vi_exit
	
vi_exit_true_num					;change display and return 0x1 in r4

	MOV r4, #0x1
	
	SUB r0, r0, #0x30
	
	BL clear_display

	BL change_display
	;LDR r4, =test
	;BL output_string

	B vi_exit

vi_exit_false					;don't change display. return 0x0 in r4
	
	MOV r4, #0x0				

vi_exit

	LDMFD SP!, {lr}
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
	MOV r7, #1
	END
