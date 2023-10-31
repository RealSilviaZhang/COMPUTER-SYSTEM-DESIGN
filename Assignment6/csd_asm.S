// ------------------------------------------
// ------------------------------------------
//  Author: Aoxuan Zhang
//          Computer Science & Engineering
//          College of Informatics, Korea Univ.
//  Date:   May 16, 2023
// ------------------------------------------

#include "csd_zynq_peripherals.h"
#include "uart_regs.h"
#include "uart_init.s"

#define	TIMER_INITIAL 32000000

.extern csd_main

.align 5

csd_vector_table:
	b csd_IRQ_ISR
	b csd_IRQ_ISR
	b csd_IRQ_ISR
	b csd_IRQ_ISR
	b csd_IRQ_ISR
	b csd_IRQ_ISR
	b csd_IRQ_ISR
	b csd_IRQ_ISR

.global main
main:

	// Disable interrupt: CPSR'I = 1
	cpsID i

	cps #0x12	   	       // IRQ mode
	ldr	r13,=irq_stack_top // Stack pointer setup for IRQ mode

	// Set VBAR (Vector Base Address Register) to my vector table
	ldr     r0, =csd_vector_table
	mcr     p15, 0, r0, c12, c0, 0
	dsb
	isb

	// Enable interrupt: CPSR'I = 0
	cpsIE i

// ---------------------------
// Generic Interrupt Controller (GIC) setup - Begin
// ---------------------------

	// Distributor Control Register
	ldr r0, =GICD_CTLR
	ldr r1, [r0]
	mov r2, #1       // Enable
	orr r1, r1, r2
	str r1, [r0]

	 // Interrupt Set-Enable Register 0
	ldr r0, =GICD_ISENABLER0
	ldr r1, [r0]
	mov r2, #1 << 29   // Enable #29 (Private Timer)
	orr r1, r1, r2
	str r1, [r0]

	// According to specifications,
	// Cortex-A9 supports 5-bit version of priority format [7:3] in secure world
	// ( 0 -> 8 -> 16 -> 24...)

	// Interrupt Priority Register #7
	ldr r0, =GICD_PRIOR7
	ldr r1, [r0]
	mov r2, #0x10 << 8    // Priority 16 for ID# 29 (Private Timer)
	orr r1, r1, r2
	str r1, [r0]

	// CPU Interface Control Register
	ldr r0, =GICC_CTLR
	ldr r1, [r0]
	mov r2, #1        // Enable
	orr r1, r1, r2
	str r1, [r0]

 	// CPU Interface Interrupt Priority Mask Register
	ldr r0, =GICC_PMR
	ldr r1, [r0]
	mov r2, #0xFF     // Lowest
	orr r1, r1, r2
	str r1, [r0]

// ---------------------------
// Generic Interrupt Controller (GIC) setup - End
// ---------------------------


// ---------------------------
// Private Timer setup - Begin
// ---------------------------

 	// Private Timer Load Register
	ldr r0, =PRIVATE_LOAD
 	ldr r1, =TIMER_INITIAL
 	str r1, [r0]

 	// Private Timer Control Register
  	ldr r0, =PRIVATE_CONTROL
 	mov r1, #10 << 8   // Prescalar
 	orr r1, r1, #7     // IRQ Enable, Auto-Reload, Timer Enable
 	str r1, [r0]

// ----------------------------
// Private Timer setup - End
// ----------------------------

forever:
	nop
	b forever

// ----------------------------
// Interrupt Service Routines (ISRs) - Begin
// ----------------------------

csd_IRQ_ISR:

	stmfd sp!, {r0-r12, lr}

 	// Interrupt Ack
  	ldr r0, =GICC_IAR
	ldr r12, [r0]

 	// Digital Watch

	ldr r1, =hour // get address of hour
	ldr r2, =min  // get address of min
	ldr r3, =sec  // get address of sec

	ldrb r4, [r1] //load hour
	ldrb r5, [r2] //load min
	ldrb r6, [r3] //load sec

	add r6, r6, #1 //interrupt occured, add one sec

	cmp r6, #60 // if sec is 60, reset sec increase one min
	moveq r6, #0
	addeq r5, r5, #1

	cmp r5, #60 // if min is 60, reset min increase one hour
	moveq r5, #0
	addeq r4, r4, #1

	cmp r4, #99// if the time is 99: 59: 59, reset the watch
	cmpeq r5, #59
	cmpeq r6, #59
	moveq r4, #0
	moveq r5, #0
	moveq r6, #0

	strb r4, [r1] //store hour
	strb r5, [r2] //store min
	strb r6, [r3] //store sec

	mov r0, r4
	mov r1, r5
	mov r2, r6

	bl csd_main //get string "hour: min: sec"

 print: // print string part

	ldr	r7, =uart_Channel_sts_reg0
	ldr r9, =uart_TX_RX_FIFO0

TX_loop:
	// ---------  Check to see if the Tx FIFO is empty ------------------------------
	ldr r8, [r7]	//get channel status register
	and	r8, r8, #0x8	//transmitter FIFO status 0: not empty 1: empty
	cmp	r8, #0x8		// check if TxFIFO is empty and ready to receive new data
	bne	TX_loop			// if TxFIFO is NOT empty, keep checking until it is empty
	//------------------------------------------------------------------------------

	ldrb r7, =#0x0d // carriage return
	strb r7, [r9]//store that byte to TxRx FIFO

transfer_str:
	ldrb r7, [r0], #1 //print r0, r0 is time string in c code
	strb r7, [r9]
	cmp r7, #0x00 // if next char is not null
	bne	transfer_str // keep printing

 	// Clear Interrupt Status bit
  	ldr r0, =PRIVATE_STATUS
  	mov r1, #1
	str r1, [r0]

 	// End-of-Interrupt
  	ldr r0, =GICC_EOIR
	str r12, [r0]

	ldmfd sp!, {r0-r12, lr}
	subs pc, lr, #4

// ----------------------------
// Interrupt Service Routines (ISRs) - End
// ----------------------------

.data
.align 4

irq_stack:     .space 1024
irq_stack_top:

sec:	.word 0
min:	.word 0
hour:	.word 0
