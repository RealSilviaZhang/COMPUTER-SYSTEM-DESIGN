// ------------------------------------------
// ------------------------------------------
//  Author: Aoxuan Zhang
//          Computer Science & Engineering
//          College of Informatics, Korea Univ.
//  Date:   May 01, 2023
// ------------------------------------------

#define csd_LED_ADDR 0x41200000

.extern thumb_C_test
.extern arm_C_test

.global main

main:
forever:
 	bl arm_C_test
 	bl thumb_C_test

 	b forever
