// ------------------------------------------
// ------------------------------------------
//  Author: Aoxuan Zhang
//          Computer Science & Engineering
//          College of Informatics, Korea Univ.
//  Date:   May 24, 2023
// ------------------------------------------

#include "csd_zynq_peripherals.h"
#include "uart_init.s"

.extern task1_c
.extern task2_c
.extern task3_c

#define USR_Mode 0x10            // User mode
#define FIQ_Mode 0x11            // Fast Interrupt Request mode
#define IRQ_Mode 0x12            // Interrupt Request mode
#define SVC_Mode 0x13            // Supervisor mode
#define ABT_Mode 0x17            // Abort mode
#define UND_Mode 0x1B            // Undefined Instruction mode
#define SYS_Mode 0x1F            // System mode

#define	TIMER_INITIAL	0x1000000

.align 8

// My Interrupt/Exception Vector Table
csd_vector_table:
	b csd_reset					// Supervisor Mode in Secure
	b csd_undefined				// Undefined Mode
	b csd_software_interrupt 	// Supervisor Mode
	b csd_prefetch				// Abort Mode
	b csd_data					// Abort Mode
	b csd_not_used				// Not used
	b csd_irq					// IRQ Mode
	b csd_fiq					// FIQ Mode

.global main

main:

// ---------------------------
// UART Initialization
// ---------------------------
	UART_init

// ---------------------------
// Stack setup for each mode
// ---------------------------

    // Disable interrupt: CPSR'I = 1
	cpsID i

	// -------------------------------------
	// Set VBAR (Vector Base Address Register) to
	// the base location of our interrupt vector table
	// -------------------------------------
	ldr	r0, =csd_vector_table
	mcr	p15, 0, r0, c12, c0, 0
	dsb
	isb

	cps  #0x11   // Change to Fast Interrupt Request Mode
	ldr	r13,=fiq_stack_top	/* FIQ mode stack pointer */

	cps  #0x12   // Change to Interrupt Request Mode
	ldr	r13,=irq_stack_top	/* IRQ mode stack pointer */

	cps  #0x13   // Change to Supervisor (SVC) Mode
	ldr	r13,=svc_stack_top	/* SVC mode stack pointer */

	cps  #0x17   // Change to Abort Mode
	ldr	r13,=abt_stack_top	/* ABT mode stack pointer */

	cps  #0x1B   // Change to Undefined Instruction Mode
	ldr	r13,=und_stack_top	/* UND mode stack pointer */

	cps #0x13

// ---------------------------
// Generic Interrupt Controller (GIC) setup - Begin
// ---------------------------

	// CPU Interface ID Register
	ldr r0, =GICC_IIDR
	ldr r3, [r0]

	// CPU Controller Type Register
	ldr r0, =GICD_TYPER
	ldr r3, [r0]

	// CPU Binary Pointer Register
	ldr r0, =GICC_BPR
	ldr r3, [r0]

	// Distributor Control Register
	ldr r0, =GICD_CTLR
	ldr r1, [r0]
	mov r2, #1       // Enable
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

	 // Interrupt Set-Enable Register 0
	ldr r0, =GICD_ISENABLER0
	ldr r1, [r0]
	mov r2, #1 << 29   // Enable #29 (Private Timer)
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

	// According to specifications,
	// Cortex-A9 supports 5-bit version of priority format [7:3] in secure world
	// ( 0 -> 8 -> 16 -> 24...)

	// Interrupt Priority Register #7
	ldr r0, =GICD_PRIOR7
	ldr r1, [r0]
	mov r2, #0x10 << 8    // Priority 16 for ID# 29 (Private Timer)
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

	// CPU Interface Control Register
	ldr r0, =GICC_CTLR
	ldr r1, [r0]
	mov r2, #1        // Enable
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

 	// CPU Interface Interrupt Priority Mask Register
	ldr r0, =GICC_PMR
	ldr r1, [r0]
	mov r2, #0xFF     // Lowest
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

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

// ----------------------------
//TCB (Task-Control Block) setup for each user program
// ----------------------------


/*
// Create TCB instance

    // Create TCB instance for Task 1 (Selection-sorting)
    ldr     r0, =os_tcb_task1        // Load the address of the TCB instance for Task 1
    ldr     r1, =task1_stack_top         // Load the address of the task's stack for Task 1
    str     r1, [r0, #OSTCBStkPtr]   // Set the task's stack pointer in the TCB
    ldr     r1, =tast2_stack_top
    str     r1, [r0, #OSTCBNext]     // Set next TCB pointer to test2
    ldr     r1, =tast3_stack_top
    str     r1, [r0, #OSTCBPrev]     // Set previous TCB pointer to test3
    mov     r1, #0                   // Assuming no initial delay
    strh    r1, [r0, #OSTCBDly]      // Set the delay value in the TCB
    mov     r1, #1                   // Assuming initial state as Ready
    strb    r1, [r0, #OSTCBStat]     // Set the task state in the TCB
    mov     r1, #0xFF                  // Assuming priority FF
    strb    r1, [r0, #OSTCBPrio]     // Set the task priority in the TCB

    // Create TCB instance for Task 2 (DhryStone Benchmark)
    ldr     r0, =os_tcb_task2        // Load the address of the TCB instance for Task 2
    ldr     r1, =task2_stack_top         // Load the address of the task's stack for Task 2
    str     r1, [r0, #OSTCBStkPtr]   // Set the task's stack pointer in the TCB
	ldr     r1, =tast3_stack_top
    str     r1, [r0, #OSTCBNext]     // Set next TCB pointer to test3
    ldr     r1, =tast1_stack_top
    str     r1, [r0, #OSTCBPrev]     // Set previous TCB pointer to test1
    mov     r1, #0                   // Assuming no initial delay
    strh    r1, [r0, #OSTCBDly]      // Set the delay value in the TCB
    mov     r1, #1                   // Assuming initial state as Ready
    strb    r1, [r0, #OSTCBStat]     // Set the task state in the TCB
    mov     r1, #0xFF                  // Assuming priority FF
    strb    r1, [r0, #OSTCBPrio]     // Set the task priority in the TCB

    // Create TCB instance for Task 3 (Hello World)
    ldr     r0, =os_tcb_task3        // Load the address of the TCB instance for Task 3
    ldr     r1, =task3_stack_top      // Load the address of the task's stack for Task 3
    str     r1, [r0, #OSTCBStkPtr]   // Set the task's stack pointer in the TCB
    ldr     r1, =tast1_stack_top
    str     r1, [r0, #OSTCBNext]     // Set next TCB pointer to test1
    ldr     r1, =tast2_stack_top
    str     r1, [r0, #OSTCBPrev]     // Set previous TCB pointer to NULL
    mov     r1, #0                   // Assuming no initial delay
    strh    r1, [r0, #OSTCBDly]      // Set the delay value in the TCB
    mov     r1, #1                   // Assuming initial state as Ready
    strb    r1, [r0, #OSTCBStat]     // Set the task state in the TCB
    mov     r1, #0xFF                  // Assuming priority FF
    strb    r1, [r0, #OSTCBPrio]     // Set the task priority in the TCB
*/
// ----------------------------
// Stack setup for each user program in supervisor mode
// ----------------------------

	ldr r0, =pc_stack_top

	ldr r1, =task1_c
	add r1, r1, #4
	ldr r2, =task2_c
	add r2, r2, #4
	ldr r3, =task3_c
	add r3, r3, #4

	stm r0, {r1-r3}



	// Enable interrupt: CPSR'I = 0
    cpsIE i


	cps  #0x10   // Change to User Mode, reverse as what we did from line37
	                		// Enable A, I, F
	ldr r13,=task1_stack_top
	ldr r12,=current_task_top
	ldr r11,=os_tcb_current
	ldr r10,=os_tcb_task1
	str r10,[r11]
	str r13, [r12]
	b task1_c // start running from task1

/*
forever:
	nop
	b forever*/

// ----------------------------
// Interrupt Service Routines (ISRs) - Begin
// ----------------------------

csd_reset:
csd_undefined:
csd_software_interrupt:
csd_prefetch:
csd_data:
csd_not_used:
csd_fiq:
csd_irq:

	//srsfd sp!, #IRQ_Mode  // SRS(Save Return State): save LR and SPSR to stack
	ldr sp, =irq_stack_top // change the stack pointer pointing towards the irq stack
	stmfd sp!, {r0-r12, lr}^
	mrs r0, spsr //copy spsr to r0
	stmfd sp,{r0,lr} //store spsr and lr in irq mode in irq stack

 	// Interrupt Ack
  	ldr r0, =GICC_IAR
	ldr r12, [r0]

    // Update the current task's state and other relevant information
    ldr r1, =os_tcb_current   // Load the address of the current task variable
    ldr r2, [r1]              // Load the value of the current task
    ldr r6, =current_task_top

	// Select the next task to run based on round-robin mechanism
    ldr r3, =os_tcb_task1   // Load the address of the TCB for Task 1
    ldr r4, =os_tcb_task2   // Load the address of the TCB for Task 2
    ldr r5, =os_tcb_task3   // Load the address of the TCB for Task 3
    cmp r2, r3              // Compare current task with Task 1 TCB
    beq switch_to_task2     // If current task is Task 1, switch to Task 2
    cmp r2, r4              // Compare current task with Task 2 TCB
    beq switch_to_task3     // If current task is Task 2, switch to Task 3
    cmp r2, r5              // Compare current task with Task 3 TCB
    beq switch_to_task1     // If current task is Task 3, switch to Task 1

switch_to_task2:
	ldr sp, [r6]
	stmfd sp!, {r0-lr}^ // store r0 ~ r14 User-mode registers to stack
    ldr r2, =os_tcb_task2      // Load the address of the TCB for Task 2
    str r2, [r1]            // Store the address of Task 2 TCB as the new current task
    ldr r7, =task2_stack_top
    ldr r8, [r7]
    str r8, [r6]
    // Clear Interrupt Status bit
  	ldr r0, =PRIVATE_STATUS
  	mov r1, #1
	str r1, [r0]
 	// End-of-Interrupt
  	ldr r0, =GICC_EOIR
	str r12, [r0]
    // Restore the context of Task 2
    ldr sp, [r7]  // Restore the stack pointer for Task 2
    ldmfd sp!, {r0-lr}^     // Restore the registers and other necessary context of Task 2
    // Update the task's state and other relevant information
    //strb #1, [r2, #OSTCBStat]   // Set the task state of Task 2 as Running or other appropriate state
    // Jump to the restored Task 2 context
    subs pc, lr, #4

switch_to_task3:
    ldr sp, [r6]
	stmfd sp!, {r0-lr}^ // store r0 ~ r14 User-mode registers to stack
    ldr r2, =os_tcb_task3      // Load the address of the TCB for Task 3
    str r2, [r1]            // Store the address of Task 3 TCB as the new current task
    ldr r7, =task3_stack_top
    ldr r8, [r7]
    str r8, [r6]
    // Clear Interrupt Status bit
  	ldr r0, =PRIVATE_STATUS
  	mov r1, #1
	str r1, [r0]
 	// End-of-Interrupt
  	ldr r0, =GICC_EOIR
	str r12, [r0]
    // Restore the context of Task 3
    ldr sp, [r7]  // Restore the stack pointer for Task 3
    ldmfd sp!, {r0-r12, lr}     // Restore the registers and other necessary context of Task 3
    // Update the task's state and other relevant information
    //strb #1, [r2, #OSTCBStat]   // Set the task state of Task 3 as Running or other appropriate state
    // Jump to the restored Task 3 context
    subs pc, lr, #4

switch_to_task1:
    ldr sp, [r6]
	stmfd sp!, {r0-lr}^ // store r0 ~ r14 User-mode registers to stack
    ldr r2, =os_tcb_task1     // Load the address of the TCB for Task 1
    str r2, [r1]            // Store the address of Task 1 TCB as the new current task
    ldr r7, =task1_stack_top
    ldr r8, [r7]
    str r8, [r6]
    // Clear Interrupt Status bit
  	ldr r0, =PRIVATE_STATUS
  	mov r1, #1
	str r1, [r0]
 	// End-of-Interrupt
  	ldr r0, =GICC_EOIR
	str r12, [r0]
    // Restore the context of Task 1
    ldr sp, [r7]  // Restore the stack pointer for Task 1
    ldmfd sp!, {r0-r12, lr}     // Restore the registers and other necessary context of Task 1
    // Update the task's state and other relevant information
    //strb #1, [r2, #OSTCBStat]   // Set the task state of Task 1 as Running or other appropriate state
    // Jump to the restored Task 1 context
    subs pc, lr, #4

/*
	ldr sp, =temp_stack_top
	stm sp, {r0-r12}^

	ldr r0, =current_task_top
	ldr r0, [r0]

	mov r1, r0, LSL #2
	sub r1, r1, #4
	add pc, pc, r1
	b switch_to_task2
	b switch_to_task3
	b switch_to_task1

switch_to_task2:
	ldm sp, {r0-r12}^
	ldr sp, =task1_stack_top
	stm	sp, {r0-r12}^

	ldr r0, =current_task_top
	mov r1, #1
	str r1, [r0]

	ldr r0, =pc_stack_top
	ldm r0, {r1-r3}
	mov	r1, lr
	mov lr, r2
	stm r0, {r1-r3}

	ldr sp, =task2_stack_top
	ldm sp, {r0-r12}^

	subs pc, lr, #4

switch_to_task3:
	ldm sp, {r0-r12}^
	ldr sp, =task2_stack_top
	stm	sp, {r0-r12}^

	ldr r0, =current_task_top
	mov r1, #2
	str r1, [r0]

	ldr r0, =pc_stack_top
	ldm r0, {r1-r3}
	mov	r2, lr
	mov lr, r3
	stm r0, {r1-r3}

	ldr sp, =task3_stack_top
	ldm sp, {r0-r12}^

	subs pc, lr, #4

switch_to_task1:
	ldm sp, {r0-r12}^
	ldr sp, =task3_stack_top
	stm	sp, {r0-r12}^

	ldr r0, =current_task_top
	mov r1, #0
	str r1, [r0]

	ldr r0, =pc_stack_top
	ldm r0, {r1-r3}
	mov	r3, lr
	mov lr, r1
	stm r0, {r1-r3}

	ldr sp, =task1_stack_top
	ldm sp, {r0-r12}^

	subs pc, lr, #4			*/

// ----------------------------
// Interrupt Service Routines (ISRs) - End
// ----------------------------


// -------------------------------
//Data section
// -------------------------------

.data
.align 4

user_stack:	   			.space 1024 // to store r0-r12
user_stack_top:
und_stack:	   			.space 1024 // to store r0-r12
und_stack_top:
svc_stack:     			.space 1024 // to store r0-r12
svc_stack_top:
abt_stack:	  			.space 1024 // to store r0-r12
abt_stack_top:
irq_stack:     			.space 1024 // to store r0-r12
irq_stack_top:
fiq_stack:     			.space 1024 // to store r0-r7
fiq_stack_top:
temp_stack:				.space 1024
temp_stack_top:
pc_stack:				.space 1024
pc_stack_top:
/*
// Data section
os_tcb_task1:           // Allocate memory for the TCB instance of Task 1
    .space   16          // Size of the TCB structure
os_tcb_task2:           // Allocate memory for the TCB instance of Task 2
    .space   16          // Size of the TCB structure
os_tcb_task3:           // Allocate memory for the TCB instance of Task 3
    .space   16          // Size of the TCB structure


// Define the os_tcb structure
os_tcb
    .field  OSTCBStkPtr, 4      // Pointer to the task's stack
    .field  OSTCBNext, 4        // Pointer to the next TCB in the list
    .field  OSTCBPrev, 4        // Pointer to the previous TCB in the list
    .field  OSTCBDly, 2         // Task delay in clock ticks
    .field  OSTCBStat, 1        // Task state (Dormant, Ready, Running, Waiting)
    .field  OSTCBPrio, 1        // Task priority
    .size   os_tcb, 16          // Size of the TCB structure
*/

// TCB for Task 1: Selection-sorting
os_tcb_task1:/*
    .field  OSTCBStkPtr, 4      // Pointer to the task's stack
    .field  OSTCBNext, 4        // Pointer to the next TCB in the list
    .field  OSTCBPrev, 4        // Pointer to the previous TCB in the list
    .field  OSTCBDly, 2         // Task delay in clock ticks
    .field  OSTCBStat, 1        // Task state (Dormant, Ready, Running, Waiting)
    .field  OSTCBPrio, 1        // Task priority*/
    .size   os_tcb_task1, 16    // Size of the TCB structure

// TCB for Task 2: DhryStone Benchmark
os_tcb_task2:/*
    .field  OSTCBStkPtr, 4      // Pointer to the task's stack
    .field  OSTCBNext, 4        // Pointer to the next TCB in the list
    .field  OSTCBPrev, 4        // Pointer to the previous TCB in the list
    .field  OSTCBDly, 2         // Task delay in clock ticks
    .field  OSTCBStat, 1        // Task state (Dormant, Ready, Running, Waiting)
    .field  OSTCBPrio, 1        // Task priority*/
    .size   os_tcb_task2, 16    // Size of the TCB structure

// TCB for Task 3: Hello World
os_tcb_task3:/*
    .field  OSTCBStkPtr, 4      // Pointer to the task's stack
    .field  OSTCBNext, 4        // Pointer to the next TCB in the list
    .field  OSTCBPrev, 4        // Pointer to the previous TCB in the list
    .field  OSTCBDly, 2         // Task delay in clock ticks
    .field  OSTCBStat, 1        // Task state (Dormant, Ready, Running, Waiting)
    .field  OSTCBPrio, 1        // Task priority*/
    .size   os_tcb_task3, 16    // Size of the TCB structure

task1_stack:     .space 1024
task1_stack_top:
task2_stack:     .space 1024
task2_stack_top:
task3_stack:     .space 1024
task3_stack_top:

current_task_top:	 .space 1024
os_tcb_current:	 	 .space 1024
