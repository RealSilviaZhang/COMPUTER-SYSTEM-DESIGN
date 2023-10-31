// ------------------------------------------
//  Author: Aoxuan Zhang
//          Computer Science & Engineering
//          College of Informatics, Korea Univ.
//  Date:   March 27, 2023
// ------------------------------------------

.global main

main:
 	ldr r0, =src
 	ldr r1, =dst
 	mov r2, #31 //iterator in loop1 (inner)
 	mov r3, #0	//initial r3 and use it as an temporary value
 	mov r6, #31 //iterator in loop2 (outer)
 	mov r7, #0 //initial a reg to save the location we're going to stroe in the memory

loop2:
	mov r2, r6 //make sure the iterator same as the outer loop
	ldr r0, =src //reinitialization

loop1:
	ldr r4, [r0]	//load one word into r4 and update r0 (= r0 + 4)
	ldr r5, [r0, #4]	//load two words into r4 and r5 respectively and keep the same r0 as r0 (= r0 + 4)


	cmp r4, r5 //compare r4 and r5, if r4 > r5, swap
	addgt r3, r4, #0 //r3 = r4
	addgt r4, r5, #0 //r4 = r5
	addgt r5, r3, #0 //r5 = r3, finished swap, now r4 <= r5

	str r4, [r0] //update the order in src(memory), r4 (smaller of two)
	str r5, [r0, #4] //r5 (larger of two)
	add r0, r0, #4 //get ready to sort next two data in src

 	subs r2, r2, #1 //inner loop finished once
 	bne loop1

 	add r7, r1, r6,lsl #2 //find the location of the one we just sorted in dst (memory)
 	str r5, [r7] //store the word in r5 to memory, settled the order (largest)

 	subs r6, r6, #1 //outer loop finished once
 	bne loop2

	sub r7, r7, #4 //find the smallest one location in src(memory)
	str r4, [r7] //store back to dst


.data
.align 4

src:
    .word 2, 0, -7, -1, 3, 8, -4, 10
    .word -9, -16, 15, 13, 1, 4, -3, 14
    .word -8, -10, -15, 6, -13, -5, 9, 12
    .word -11, -14, -6, 11, 5, 7, -2, -12

dst:
 	.space 32	//allocate memory for 32 words

