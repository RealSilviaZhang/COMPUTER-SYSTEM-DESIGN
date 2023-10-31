#include "uart_regs.h"
#include "uart_init.s"

.global main


main:
	ldr r0, =uart_TX_RX_FIFO0 // Load the address of the UART FIFO register into r0
	ldr r1, =uart_Channel_sts_reg0 // Load the address of the UART status register into r1

	ldr r10, =line // Load the address of a function that prints a line of '-' characters into r10
	bl str // Call the function to print the line of '-' characters

	// Define a macro for debugging purposes
.macro DEBUG
	str lr, [sp, #60] // Save the return address of the caller in the stack
	bl print_regs // Call the function to print the values of all registers
.endm

// Start of the sorting algorithm
Sorting:
 	ldr r0, =src // Load the address of the source array into r0
 	ldr r1, =dst // Load the address of the destination array into r1
 	mov r2, #31 // Initialize r2 to 31, which will be used as an iterator in loop1 (inner)
 	mov r3, #0	// Initialize r3 to 0 and use it as a temporary value
 	mov r6, #31 // Initialize r6 to 31, which will be used as an iterator in loop2 (outer)
 	mov r7, #0 // Initialize r7 to 0, which will be used to save the location where we will store a word in memory
 	DEBUG // Call the debugging macro to print the values of registers

loop2:
	mov r2, r6 // Copy the value of r6 to r2 to ensure that the iterator in loop1 is the same as the current value of r6
	ldr r0, =src // Reinitialize r0 to the start of the source array
	DEBUG // Call the debugging macro to print the values of registers

loop1:
	ldr r4, [r0]	// Load a word from memory into r4 and update r0 to point to the next word in the array
	ldr r5, [r0, #4]	// Load the next word from memory into r5 and keep r0 the same as before
	DEBUG // Call the debugging macro to print the values of registers

	cmp r4, r5 // Compare r4 and r5. If r4 is greater than r5, swap their values
	DEBUG // Call the debugging macro to print the values of registers
	addgt r3, r4, #0 // If r4 is greater than r5, copy r4 to r3
	addgt r4, r5, #0 // If r4 is greater than r5, copy r5 to r4
	addgt r5, r3, #0 // If r4 is greater than r5, copy r3 to r5 (i.e., swap the values of r4 and r5)
	DEBUG // Call the debugging macro to print the values of registers

	str r4, [r0] // Store the value of r4 back into memory (i.e., the first word in the pair being compared)
	str r5, [r0, #4] // Store the value of r5 back into memory (i.e., the second word in the pair being compared)
	add r0, r0, #4 // Move r0 to point to the next pair of words in the array
	DEBUG // Call the debugging macro to print the values of registers

 	subs r2, r2, #1 // Decrement the inner loop iterator
	DEBUG // Call the debugging macro to print the values of registers
 	bne loop1 // Branch if not equal to loop1 label (continue if still elements to be sorted)

 	add r7, r1, r6,lsl #2 // Calculate the location in memory of the current element to be stored in dst
 	str r5, [r7] // Store the current element (largest one) in memory at the calculated location
 	DEBUG // Print debug info

 	subs r6, r6, #1 //decrement the number of remaining elements to be sorted
 	DEBUG
 	bne loop2 // branch to loop2 label if there are still elements to be sorted

	sub r7, r7, #4 // find the smallest element in src(memory)
	str r4, [r7] //store the smallest element in memory back to dst
	DEBUG

print_regs: // label for printing registers
	// Store registers into the stack
	stmfa sp!, {r0 - r12} // store registers r0-r12 into the stack
	sub r0, sp, #52 // calculate the address of the saved registers in the stack
	ldr r1, [sp, #8] // load the saved pc value from the stack into r1
	sub r2, lr, #4 // calculate the address of the CPSR in the stack
	mrs r3, cpsr // copy the CPSR register value into r3
	stmfa sp!, {r0 - r3} // store registers r0-r3 into the stack
	// END Store registers into the stack

	ldr r0, =uart_TX_RX_FIFO0 // load uart_TX_RX_FIFO0 address into r0
	ldr r1, =uart_Channel_sts_reg0 // load uart_Channel_sts_reg0 address into r1


	// Print all registers in hex
	mvn r3, #63				// r3 = -64, calculate -64 and store it in r3
	ldr r10, =regs // load regs address into r10

	// Print a single register in hex
get_reg: // label for sending a register value
	bl str // call the str function to send the string to the console
	ldr r4, [sp, r3] // load the register value of sp-64 which is r0 from the stack into r4
	mov r5, #28 // initialize r5 with the starting bit index
	mov r6, #0xF0000000 // initialize r6 with the bitmask to extract a nibble
	mov r7, #0x5F // r7 = '_', initialize r7 with the ASCII code for '_'

	// Get and print hex code of 4 bits
get_reg_hex:          // label for sending a nibble in hex
    and r8, r4, r6         // extract the nibble from the register value
    lsr r8, r8, r5         // shift the nibble to the lowest 4 bits
    cmp r8, #10            // compare with 10 to decide if to use letters or numbers in the ASCII code
    addlt r9, r8, #48      // if less than 10, use the corresponding number
    addge r9, r8, #55      // if greater than or equal to 10, use the corresponding letter

    bl if_empty          // call the if_empty function (not shown here)
    strb r9, [r0]          // store the ASCII code for the nibble in the output buffer

    // Print delimiter (_)
    bl if_empty          // call if_empty again
    cmp r5, #0x10            // compare r5 to 16
    streqb r7, [r0]        // store '_' in the output buffer if r5 is equal to 16
    // END Print delimter (_)

    // check next 4 bits
    lsr r6, r6, #4         // shift r6 right by 4 bits
    subs r5, r5, #4        // subtract 4 from r5
    bge get_reg_hex  // branch to get_reg_hex if r5 is greater than or equal to 0

    // check next register
    add r3, r3, #0x4         // add 4 to r3 (the current register)
    cmp r3, #0x4             // compare r3 to 4
    bne get_reg      // branch to get_reg if r3 is not equal to 4

CPSR:
    // Print CPSR details
    ldr r10, =delimiter    // load the address of the delimiter string into r10
    bl str            // call the str function to output the delimiter
	mrs r4, cpsr // copy the CPSR register value into r4
    // Print CPSR NZCV bits
    and r8, r4, #0x80000000 // extract the N flag from CPSR
    cmp r8, #0x80000000    // compare the N flag to 1
    moveq r9, #0x4e        // if N flag is 1, set r9 to 'N'
    movne r9, #0x6e        // if N flag is 0, set r9 to 'n'
    bl if_empty          // call if_empty
    strb r9, [r0]          // store the appropriate character in the output buffer

    and r8, r4, #0x40000000 // extract the Z flag from CPSR
    cmp r8, #0x40000000    // compare the Z flag to 1
    moveq r9, #0x5a        // if Z flag is 1, set r9 to 'Z'
    movne r9, #0x7a        // if Z flag is 0, set r9 to 'z'
    bl if_empty          // call if_empty
    strb r9, [r0]          // store the appropriate character in the output buffer

	and r8, r4, #0x20000000 // extracts the C flag from the CPSR register and stores it in register r8
	cmp r8, #0x20000000 // compares the C flag (which was stored in r8) to the value 1
	moveq r9, #0x43 // sets the value of register r9 to 'C' if the C flag (which was stored in r8) is equal to 1
	movne r9, #0x63 // If C flag is 0, set r9 to 'c'
	bl if_empty // Call if_empty
	strb r9, [r0] // Store the appropriate character in the output buffer

	and r8, r4, #0x10000000 // Extract the V flag from CPSR
	cmp r8, #0x10000000 // Compare the V flag to 1
	moveq r9, #0x56 // If V flag is 1, set r9 to 'V'
	movne r9, #0x76 // else set r9 to 'v'
	bl if_empty // Call if_empty
	strb r9, [r0] // Store the appropriate character in the output buffer
	// END Print CPSR NZCV bits

	ldr r10, =delimiter // Load the memory address of the delimiter string
	bl str // Send the delimiter string to UART

	// Print CPSR interrupt bits
	bl if_empty // Wait for UART buffer to be empty
	and r8, r4, #0x100 // Extract the I bit from CPSR
	cmp r8, #0x100 // Compare the extracted I bit with 1
	moveq r9, #0x41 // If the I bit is 1, set r9 to ASCII character 'A'
	streqb r9, [r0] // If the I bit is 1, send the 'A' character to UART

	bl if_empty // Wait for UART buffer to be empty
	and r8, r4, #0x80 // Extract the F bit from CPSR
	cmp r8, #0x80 // Compare the extracted F bit with 1
	moveq r9, #0x49 // If the F bit is 1, set r9 to ASCII character 'I'
	streqb r9, [r0] // If the F bit is 1, send the 'I' character to UART

	bl if_empty // Wait for UART buffer to be empty
	and r8, r4, #0x40 // Extract the T bit from CPSR
	cmp r8, #0x40 // Compare the extracted T bit with 1
	moveq r9, #0x46 // If the T bit is 1, set r9 to ASCII character 'F'
	streqb r9, [r0] // If the T bit is 1, send the 'F' character to UART
	// END Print CPSR interrupt bits

	// Print CPSR ISA
	ldr r10, =delimiter // Load the address of delimiter into register r10
	bl str // Call str subroutine to print the delimiter

	and r8, r4, #0b100000 // Mask the CPSR register with 0b100000 to get the ISA mode flag
	cmp r8, #0b100000 // Compare ISA mode flag with 0b100000
	moveq r5, #0b01 // If the ISA mode flag is equal to 0b100000, set r5 to 0b01
	movne r5, #0b00 // If the ISA mode flag is not equal to 0b100000, set r5 to 0b00
	lsr r6, r4, #24 // Shift the CPSR register right by 24 bits and store in r6
	and r8, r6, #0b1 // Mask r6 with 0b1 to get the Thumb flag
	cmp r8, #0b1 // Compare Thumb flag with 0b1
	addeq r5, #0b10 // If Thumb flag is equal to 0b1, add 0b10 to r5
	addne r5, #0b00 // If Thumb flag is not equal to 0b1, add 0b00 to r5

	cmp r5, #0b00 // Compare r5 with 0b00
	ldreq r10, =isa_arm // If r5 is equal to 0b00, load the address of isa_arm into r10
	cmp r5, #0b01 // Compare r5 with 0b01
	ldreq r10, =isa_thumb // If r5 is equal to 0b01, load the address of isa_thumb into r10
	cmp r5, #0b10 // Compare r5 with 0b10
	ldreq r10, =isa_jazelle // If r5 is equal to 0b10, load the address of isa_jazelle into r10
	cmp r5, #0b11 // Compare r5 with 0b11
	ldreq r10, =isa_thumbee // If r5 is equal to 0b11, load the address of isa_thumbee into r10
	bl str // Call str subroutine to print the ISA mode
	// END Print CPSR ISA

	// Print CPSR Mode
	ldr r10, =delimiter // Load the address of delimiter into register r10
	bl str // Call str subroutine to print the delimiter

	// Mask CPSR register to get the mode flag and compare it with each possible mode flag
	and r8, r4, #0b11111 // Mask the CPSR register with 0b11111 to get the mode flag
	cmp r8, #0b10000 // Compare the mode flag with 0b10000
	ldreq r10, =mode_usr // If the mode flag is equal to 0b10000, load the address of mode_usr into r10
	cmp r8, #0b10001 // Compare the mode flag with 0b10001
	ldreq r10, =mode_fiq // If the mode flag is equal to 0b10001, load the address of mode_fiq into r10
	cmp r8, #0b10010 // Compare the mode flag with 0b10010
	ldreq r10, =mode_irq // If the mode flag is equal to 0b10010, load the address of mode_irq into r10
	cmp r8, #0b10011 // Compare the mode flag with 0b10011
	ldreq r10, =mode_svc // If the mode flag is equal to 0b10011, load the address of mode_svc into r10
	cmp r8, #0b10110 // Compare the mode flag with 0b10110
	ldreq r10, =mode_mon // If the mode flag is equal to 0b10110, load the address of mode_mon into r10
	cmp r8, #0b10111 // Compare the mode flag with 0b10111
	ldreq r10, =mode_abt // If the mode flag is equal to 0b10111, load the address of mode_abt into r10
	cmp r8, #0b11010 // Compare the mode flag with 0b11010
	ldreq r10, =mode_hyp // If the mode flag is equal to 0b11010, load the address of mode_hyp into r10
	cmp r8, #0b11011 // Compare the mode flag with 0b11011
	ldreq r10, =mode_und // If the mode flag is equal to 0b11011, load the address of mode_und into r10
	cmp r8, #0b11111 // Compare the mode flag with 0b11111
	ldreq r10, =mode_sys // If the mode flag is equal to 0b11111, load the address of mode_sys into r10
	bl str // Call str subroutine to print the mode name
	// END Print CPSR Mode

	// Print separator line
	ldr r10, =line // Load the address of line into register r10
	bl str // Call str subroutine to print the separator line

Read_stack:
	// Load registers from the stack
	ldmfa sp!, {r0, r1, r2, r3}  // Load registers r0-r3 from the stack and increment the stack pointer by 4
	add r2, r2, #4 // Add 4 to the value of r2
	str r2, [sp, #12] // Store the value of r2 in the stack at the location of the old r2
	msr cpsr, r3 // Load the value of r3 into CPSR
	ldmfa sp!, {r0 - r12} // Load the remaining registers from the stack
	ldr lr, [sp, #60] // Load the value of lr from the stack
	ldr sp, [sp, #64] // Load the value of sp from the stack
	// END Load registers from the stack

if_empty: // Wait for UART buffer to be empty
    ldr r11, [r1] // Load the UART's control register
    and r11, r11, #0b10000 // Extract the Transmit Holding Register Empty bit
    cmp r11, #0b10000 // Compare the bit with Transmit Holding Register Empty
    beq if_empty // Loop back if the bit is not set
    mov pc, lr // Return to calling function

str: // Send string through UART
    ldr r11, [r1] // Load the UART's control register
    and r11, r11, #0b10000 // Extract the Transmit Holding Register Empty bit
    cmp r11, #0b10000 // Compare the bit with Transmit Holding Register Empty
    beq str // Loop back if the bit is not set
    ldrb r12, [r10], #1 // Load the next byte from the string to send
    strb r12, [r0] // Write the byte to the UART data register
    cmp r12, #0x00 // Compare the byte with null terminator
    bne str // Loop back if the byte is not null
    mov pc, lr // Return to calling function

line:
	.ascii "\r\n---------------------------------------------------------------------------"
	.byte 0x00   // horizontal line

regs:
	.ascii "\r\n  r0 = 0x"  // register r0 name
	.byte 0x00
	.ascii ",  r1 = 0x"      // register r1 name
	.byte 0x00
	.ascii ",  r2 = 0x"      // register r2 name
	.byte 0x00
	.ascii ",  r3 = 0x"      // register r3 name
	.byte 0x00
	.ascii "\r\n  r4 = 0x"  // register r4 name
	.byte 0x00
	.ascii ",  r5 = 0x"      // register r5 name
	.byte 0x00
	.ascii ",  r6 = 0x"      // register r6 name
	.byte 0x00
	.ascii ",  r7 = 0x"      // register r7 name
	.byte 0x00
	.ascii "\r\n  r8 = 0x"  // register r8 name
	.byte 0x00
	.ascii ",  r9 = 0x"      // register r9 name
	.byte 0x00
	.ascii ", r10 = 0x"      // register r10 name
	.byte 0x00
	.ascii ", r11 = 0x"      // register r11 name
	.byte 0x00
	.ascii "\r\n r12 = 0x"  // register r12 name
	.byte 0x00
	.ascii ", r13 = 0x"      // register r13 name
	.byte 0x00
	.ascii ", r14 = 0x"      // register r14 name
	.byte 0x00
	.ascii ", r15 = 0x"      // register r15 name
	.byte 0x00
	.ascii "\r\ncpsr = "  // cpsr name

isa_arm:
	.ascii "ARM mode"    // ARM ISA name
	.byte 0x00

isa_thumb:
	.ascii "Thumb mode"  // Thumb ISA name
	.byte 0x00

isa_jazelle:
	.ascii "Jazelle mode"  // Jazelle ISA name
	.byte 0x00

isa_thumbee:
	.ascii "ThumbEE mode"  // ThumbEE ISA name
	.byte 0x00

mode_usr:
	.ascii "current mode = USR"  // User mode name
	.byte 0x00

mode_fiq:
	.ascii "current mode = FIQ"  // FIQ mode name
	.byte 0x00

mode_irq:
	.ascii "current mode = IRQ"  // IRQ mode name
	.byte 0x00

mode_svc:
	.ascii "current mode = SVC"  // Supervisor mode name
	.byte 0x00

mode_mon:
	.ascii "current mode = MON"  // Monitor mode name
	.byte 0x00

mode_abt:
	.ascii "current mode = ABT"  // Abort mode name
	.byte 0x00

mode_hyp:
	.ascii "current mode = HYP"  // Hypervisor mode name
	.byte 0x00

mode_und:
	.ascii "current mode = UND"  // Undefined mode name
	.byte 0x00

mode_sys:
	.ascii "current mode = SYS"  // System mode name
	.byte

delimiter:
	.ascii ", " // Delimiter
	.byte 0x00

.data
.align 4

src:
    .word 2, 0, -7, -1, 3, 8, -4, 10
    .word -9, -16, 15, 13, 1, 4, -3, 14
    .word -8, -10, -15, 6, -13, -5, 9, 12
    .word -11, -14, -6, 11, 5, 7, -2, -12

dst:
 	.space 32	//allocate memory for 32 words
