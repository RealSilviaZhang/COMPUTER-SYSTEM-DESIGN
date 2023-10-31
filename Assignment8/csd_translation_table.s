// ------------------------------------------
//  Author: Aoxuan Zhang
//          Computer Science & Engineering
//          College of Informatics, Korea Univ.
//  Date:   June 10, 2023
//
//  It is based on Boot code in Xilinx SDK
// ------------------------------------------
/*
.globl  csd_MMUTable_lv2
.section .csd_mmu_tbl_lv2,"a"
// Figure 2
//
//	 *     1st 4KB: 0x0020_0000 (VA) -> 0x0040_0000 (PA)
//	 *     2nd 4KB: 0x0020_1000 (VA) -> 0x0040_1000 (PA)
//	 *     3rd 4KB: 0x0020_2000 (VA) -> 0x0040_2000 (PA)
//	 *
csd_MMUTable_lv2:
.set	PAGE, 0x400000
.word	PAGE + 0x2
.set	PAGE, 0x401000
.word	PAGE + 0x2
.set	PAGE, 0x402000
.word	PAGE + 0x2

.globl  csd_MMUTable
.section .csd_mmu_tbl,"a"

csd_MMUTable:
//	 		1st 1MB (0x0 ~ 0xF_FFFF) in VA → 0x0 ~ 0xFFFFF in PA
//	   		2rd 1MB (0x10_0000 ~ 0x1F_FFFF) in VA → 0x10_0000 ~ 0x1F_FFFF in PA
//	  	First three 4KB pages in 3rd 1MB (0x20_0000 ~ 0x2F_FFFF) of VA
//	  		1st 4KB (0x20_0000 ~ 0x20_0FFF) in VA → 0x40_0000 ~ 0x40_0FFF in PA
//	 		2nd 4KB (0x20_1000 ~ 0x20_1FFF) in VA → 0x41_0000 ~ 0x41_0FFF in PA
//	 		3rd 4KB (0x20_2000 ~ 0x20_2FFF) in VA → 0x42_0000 ~ 0x42_0FFF in PA
//

.set	SECT, 0
.word	SECT + 0x15de6		// S=b1 TEX=b101 AP=b11, Domain=b1111, C=b0, B=b1
.set	SECT, 0x100000
.word	SECT + 0x15de6		// S=b1 TEX=b101 AP=b11, Domain=b1111, C=b0, B=b1
.set	SECT, 0x400000
.word	csd_MMUTable_lv2 + 0x1e1
*/

// Figure 3.
.globl  csd_MMUTable_lv2
.section .csd_mmu_tb_lv2,"a"
//
//	      1st 4KB: 0x0020_0000 (VA) -> 0x0040_0000 (PA)
//	      2nd 4KB: 0x0020_1000 (VA) -> 0x0040_2000 (PA)
//	      3rd 4KB: 0x0020_2000 (VA) -> 0x0040_0000 (PA)

csd_MMUTable_lv2:
.set	PAGE, 0x400000
.word	PAGE + 0x2
.set	PAGE, 0x402000
.word	PAGE + 0x2
.set	PAGE, 0x400000
.word	PAGE + 0x2

.globl  csd_MMUTable
.section .csd_mmu_tbl,"a"

csd_MMUTable:
	//		1st 1MB (0x0 ~ 0xF_FFFF) in VA → 0x0 ~ 0xFFFFF in PA
	// 		2rd 1MB (0x10_0000 ~ 0x1F_FFFF) in VA → 0x10_0000 ~ 0x1F_FFFF in PA
	//	First three 4KB pages in 3rd 1MB (0x20_0000 ~ 0x2F_FFFF) of VA
	//		1st 4KB (0x20_0000 ~ 0x20_0FFF) in VA → 0x40_0000 ~ 0x40_0FFF in PA
	//		2nd 4KB (0x20_1000 ~ 0x20_1FFF) in VA → 0x42_0000 ~ 0x40_2FFF in PA
	//		3rd 4KB (0x20_2000 ~ 0x20_2FFF) in VA → 0x40_0000 ~ 0x40_0FFF in PA

.set	SECT, 0
.word	SECT + 0x15de6		// S=b1 TEX=b101 AP=b11, Domain=b1111, C=b0, B=b1
.set	SECT, 0x100000
.word	SECT + 0x15de6		// S=b1 TEX=b101 AP=b11, Domain=b1111, C=b0, B=b1
.set	SECT, 0x400000
.word	csd_MMUTable_lv2 + 0x1e1
*/
