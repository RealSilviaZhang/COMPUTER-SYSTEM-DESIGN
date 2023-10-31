// ------------------------------------------
// ------------------------------------------
//  Author: Aoxuan Zhang
//          Computer Science & Engineering
//          College of Informatics, Korea Univ.
//  Date:   May 24, 2023
// ------------------------------------------

#include "csd_zynq_peripherals.h"

.extern csd_main

#define csd_LED_ADDR 0x41200000
#define csd_SW_ADDR 0x41210000

.global main

main:

	ldr r7, =csd_SW_ADDR
	ldr r8, =csd_LED_ADDR

forever:

	ldr r9, [r7]
	and r9, r9, #0b1 // get the sw0 input

	cmp r9, #0b1
	beq Enable // r9==1, sw0 is on, caches are enabled
	bne Disable // r9==0, sw0 is off, caches are disabled

Disable:

	// Read Cache Type Register (CTR)
	mrc p15, 0, r1, c0, c0, 1

	// Read Cache Level ID Register (CLIDR)
	mrc p15, 1, r2, c0, c0, 1
	//------------------------
	// Disable Caches (L2)
	//------------------------
	ldr r0, =L2_reg1_ctrl
	mov r1, #0x0
	str r1, [r0]
	//------------------------
	// Disable Caches (IL1, DL1)
	//------------------------
	mrc		p15, 0, r0, c1, c0, 0	// read control register (CP15 register1)
	bic		r0, r0, #4096		    // disable I bit (Instruction Cache)
	bic		r0, r0, #4		        // disable C bit (Data and Unified Caches)
	mcr		p15, 0, r0, c1, c0, 0	// write control register (CP15 register2)

	// read SCTLR (System Control Register) to r0
	mrc	p15, 0, r0, c1, c0, 0

	bl csd_main

	b forever

Enable:

	// Read Cache Type Register (CTR)
	mrc p15, 0, r1, c0, c0, 1

	// Read Cache Level ID Register (CLIDR)
	mrc p15, 1, r2, c0, c0, 1

	//------------------------
	// Enable Caches (L2)
	//------------------------
	ldr r0, =L2_reg1_ctrl
    mov r1, #0x1
    str r1, [r0]

	//------------------------
	// Enable Caches (IL1, DL1)
	//------------------------
	mrc		p15, 0, r0, c1, c0, 0	// read control register (CP15 register1)
	orr		r0, r0, #(1<<12)	    // Enable I bit (Instruction Cache)
	orr		r0, r0, #(1<<2)         // Enable C bit (Data and Unified Caches)
	mcr		p15, 0, r0, c1, c0, 0	// write control register (CP15 register2)

	// read SCTLR (System Control Register) to r0
	mrc	p15, 0, r0, c1, c0, 0

	bl csd_main

	b forever


