// ------------------------------------------
//  Author: Aoxuan Zhang
//          Computer Science & Engineering
//          College of Informatics, Korea Univ.
//  Date:   April 7, 2023
// ------------------------------------------

#define csd_LED_ADDR 0x41200000
#define csd_SW_ADDR 0x41210000

.global main
main:

 	ldr r0, =csd_LED_ADDR
 	ldr r2, =csd_SW_ADDR
 	mov r1, #1 // signal of lights will be stored in r1,
 			   // Turn on LD0 at the start of our loop
 	mov r3, #0 // initial r3 to use as an iterator

getloop:
	stmfd sp!, {r0,r2} // push stack before we call a function
	bl sw_btn_dur // call the function in c to get the duration(loops)
	mov r3, r0 // return value will be stored in r3
	ldmfd sp!, {r0,r2} // pop stack after we call a function

	str r1, [r0] // light the LED

loop: // time consumer in one duration
 	subs r3, r3, #1
 	bne loop
 	cmp r1, #0x100 // 1 0000 0000 means that there will be a new round
 	moveq r1, #0b00000001 // reinitiate the LED status
	movne r1, r1, lsl #1 // mov to light next position LED

	bal getloop
