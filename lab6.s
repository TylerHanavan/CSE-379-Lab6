	AREA interrupts, CODE, READWRITE

	EXPORT lab6

	EXPORT FIQ_Handler

	EXTERN uart_init
	EXTERN pin_connect_block_setup_for_uart0
	EXTERN setup_pins
	EXTERN validate_input
	EXTERN change_display
	EXTERN clear_display
	EXTERN toggle_seven_seg
	EXTERN read_character
	EXTERN output_character
	EXTERN output_string

prompt = "Press momentary push button to toggle seven segment display on or off. Press a hexadecimal character (hold shift for A-F) to change the display (if it is on). Press 'q' to exit program.",0
test = "test1",0
    ALIGN

lab6	 	

	STMFD sp!, {lr}

	BL uart_init					;setup the uart with its init subroutine
	BL pin_connect_block_setup_for_uart0		;setup the pin connect block
	BL setup_pins					;setup pins required for momentary push button and seven segment display	
	BL interrupt_init
	BL clear_display
	
	MOV r0, #1
	
	BL change_display
	
	MOV r9, #1

	LDR r4, =prompt

	BL output_string	

lab5_loop
	
	;BL read_character
	;BL validate_input

	;CMP r4, #0
	;BEQ skip_output
	
	;BL output_character 

;skip_output

	;MOV r6, r0

	CMP r7, #1
	BEQ lab5_end

	B lab5_loop

lab5_end

	LDMFD sp!,{lr}

	BX lr



interrupt_init       

		STMFD SP!, {r0-r2, lr}   ; Save registers 

		

		; Push button setup		 

		LDR r0, =0xE002C000

		LDR r1, [r0]

		ORR r1, r1, #0x20000000

		BIC r1, r1, #0x10000000

		STR r1, [r0]  ; PINSEL0 bits 29:28 = 10


		;key board setup
		LDR r0, =0xE000C004
		
		LDR r1, [r0]
		
		ORR r1, r1, #0x1
		
		STR r1, [r0]
		

		; Classify sources as IRQ or FIQ

		LDR r0, =0xFFFFF000

		LDR r1, [r0, #0xC]
		
		LDR r2, =0x8050

		ORR r1, r1, r2 ; External Interrupt 1

		STR r1, [r0, #0xC]



		; Enable Interrupts

		LDR r0, =0xFFFFF000

		LDR r1, [r0, #0x10]

		LDR r2, =0x8050

		ORR r1, r1, r2 ; External Interrupt 1

		STR r1, [r0, #0x10]



		; External Interrupt 1 setup for edge sensitive

		LDR r0, =0xE01FC148

		LDR r1, [r0]

		ORR r1, r1, #2  ; EINT1 = Edge Sensitive

		STR r1, [r0]
		
		

		; External Timer 0 interrupt select register

		;LDR r0, =0xFFFFF010

		;LDR r1, [r0]

		;ORR r1, r1, #0x10

		;STR r1, [r0]
		
		

		
		
		

		; External Timer 0 modify MR0

		LDR r0, =0xE0004018

		LDR r1, =250000

		STR r1, [r0]

		
		; External Timer 0 MCR

		LDR r0, =0xE0004014

		LDR r1, [r0]
		
		;ORR r1, r1, #3
		;ORR r1, r1, #8
		ORR r1, r1, #0x3
		BIC r1, r1, #0x20

		STR r1, [r0]
		
		; External Timer 0 timer control register

		LDR r0, =0xE0004004

		LDR r1, [r0]

		ORR r1, r1, #1  

		STR r1, [r0]

		; Enable FIQ's, Disable IRQ's

		MRS r0, CPSR

		BIC r0, r0, #0x40

		ORR r0, r0, #0x80

		MSR CPSR_c, r0



		LDMFD SP!, {r0-r2, lr} ; Restore registers

		BX lr             	   ; Return

FIQ_Handler

		STMFD SP!, {r0, r1, r2, r3, r4, r5, lr}   ; Save registers 
		
		LDR r0, =0xE0004000
		LDR r1, [r0]
		CMP r1, #0
		BGT TIMER0
		B EINT1
		
TIMER0

	B FIQ_Exit

EINT1			; Check for EINT1 interrupt
	
	LDR r4, =test
	BL output_string
	
		LDR r0, =0xE01FC140

		LDR r1, [r0]

		TST r1, #2

		BEQ FIQ_Keys

		BL toggle_seven_seg

		ORR r1, r1, #2		; Clear Interrupt

		STR r1, [r0]
		
		B FIQ_Exit

FIQ_Keys
		LDR r0, =0xE000C008

		LDR r1, [r0]
		
		AND r2, r1, #1

		CMP r2, #0

		BNE FIQ_Exit

		BL read_character
		BL output_character
		BL validate_input

FIQ_Exit

		LDMFD SP!, {r0, r1, r2, r3, r4, r5, lr}

		SUBS pc, lr, #4



	END
