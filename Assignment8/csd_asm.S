// ------------------------------------------
//  Author: Aoxuan Zhang
//          Computer Science & Engineering
//          College of Informatics, Korea Univ.
//  Date:   Jun 10, 2023
// ------------------------------------------

// Vector table base location should be aligned at 2^8
.align 8
csd_entry:
	b csd_reset
	b .
	b .
	b csd_prefetch_abort
	b csd_data_abort
	b .
	b csd_irq
	b .
.global main
csd_reset:
main:

	// Set VBAR (Vector Base Address Register) to my own interrupt vectors
    ldr     r0, =csd_entry
    mcr     p15, 0, r0, c12, c0, 0

	// read SCTLR (System Control Register) to r0
	mrc	p15, 0, r0, c1, c0, 0

	// read SCR (Secure Configuration Register) to r1
	mrc p15, 0, r1, c1, c1, 0

	// read TTBCR (Translation Table Base Control Register) to r2
	mrc p15, 0, r2, c2, c0, 2

	// read TTBR0 to r3
	mrc p15, 0, r3, c2, c0, 0

	// read DACR (Domain Access Control Register) to r4
	mrc p15, 0, r4, c3, c0, 0

	/* Disable MMU, if enabled */
	mrc	p15, 0, r0, c1, c0, 0		/* read CP15 register 1 */
	bic	r0, r0, #0x1			/* clear bit 0 */
	mcr	p15, 0, r0, c1, c0, 0		/* write value back */


    /* Begin: store some words to the start of each 1MB section */
	mov r0, #0x400000
	ldr r1, =#-1024
	mov r2, #2048

Initial_DDR:
	str r1, [r0], #4
	add r1, r1, #1
	cmp r1, #0
	addeq r1, r1, #1
	cmp r1, r2
	bne Initial_DDR
	/* End */

	ldr	r0,=csd_MMUTable	   /* Load MMU translation table base */
	orr	r0, r0, #0x5B			/* Outer-cacheable, WB */
	mcr	15, 0, r0, c2, c0, 0		/* TTBR0 */

	/* Enable MMU */
	// Set M-bit in SCTLR (System Control Register)
	mrc	p15, 0, r0, c1, c0, 0
	bic r0, r0, #(1<<12)  // I-bit = I$ disable
	bic r0, r0, #(1<<2)   // C-bit = $ disable
	orr r0, r0, #(1<<0)   // M-bit = MMU enable
	mcr	p15, 0, r0, c1, c0, 0	/* Enable MMU */
	dsb					        /* dsb	allow the MMU to start up */
	isb					        /* isb	flush prefetch buffer */

	// read SCTLR (System Control Register) to r0
	mrc	p15, 0, r0, c1, c0, 0


// Run the program, and check out the addition outcome
/*
	mov r0, #0x200000
	mov r1, #0x202fff
	mov r3, #0
Addition:
	ldr r4, [r0], #4
	add r3, r3, r4
	cmp r0, r1
	bne Addition
*/
	mov r0, #0x200000
	mov r1, #3071
	mov r3, #0
Addition:
	ldr r4, [r0], #4
	add r3, r3, r4
	subs r1, r1, #1
	bne Addition

forever:
	nop
	b forever

// Normal Interrupt Service Routine
csd_irq:
	b .

csd_prefetch_abort:
	mrc p15, 0, r10, c6, c0, 2  // read IFAR to r10
	mrc p15, 0, r11, c5, c0, 1  // read IFSR to r11
	b .

csd_data_abort:
	mrc p15, 0, r10, c6, c0, 0  // read DFAR to r10
	mrc p15, 0, r11, c5, c0, 0  // read DFSR to r11
	b .
