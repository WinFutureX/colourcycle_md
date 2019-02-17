; colour cycle (cycles through colours as a series of lines)

; necessary equates for system

; reset system stack pointer
initialssp:	equ	$8FFFFF00

; z80 bus request, reset and ram addrs
z80req:		equ	$A11100
z80reset:	equ	$A11200
z80ram:		equ	$A00000

; vdp control and data ports
vdpctrl:	equ	$C00004
vdpdata:	equ	$C00000

; sn76489 psg (byte-addressing only)
psg:		equ	$C00011

; cart header and 68k vectors
vectors:
		dc.l	initialssp					;  0: reset sp
		dc.l	startup						;  1: reset pc
		dc.l	cpufault					;  2: bus error
		dc.l	cpufault					;  3: address error
		dc.l	cpufault					;  4: illegal instruction
		dc.l	cpufault					;  5: zero divide
		dc.l	cpufault					;  6: chk instruction
		dc.l	cpufault					;  7: trapv instruction
		dc.l	cpufault					;  8: privilege violation
		dc.l	cpufault					;  9: trace
		dc.l	cpufault					; 10: line A trap
		dc.l	cpufault					; 11: line F trap
		dc.l	cpufault					; 12: unassigned, reserved
		dc.l	cpufault					; 13: unassigned, reserved
		dc.l	cpufault					; 14: format error (68010 and up)
		dc.l	cpufault					; 15: uninitialized interrupt vector
		dc.l	cpufault					; 16: unassigned, reserved
		dc.l	cpufault					; 17: unassigned, reserved
		dc.l	cpufault					; 18: unassigned, reserved
		dc.l	cpufault					; 19: unassigned, reserved
		dc.l	cpufault					; 20: unassigned, reserved
		dc.l	cpufault					; 21: unassigned, reserved
		dc.l	cpufault					; 22: unassigned, reserved
		dc.l	cpufault					; 23: unassigned, reserved
		dc.l	cpufault					; 24: spurious interrupt
		dc.l	cpufault					; 25: l1 irq
		dc.l	useless						; 26: l2 irq (ext int)
		dc.l	cpufault					; 27: l3 irq
		dc.l	useless						; 28: l4 irq (hblank)
		dc.l	cpufault					; 29: l5 irq
		dc.l	useless						; 30: l6 irq (vblank)
		dc.l	cpufault					; 31: l7 irq
		dc.l	cpufault					; 32: trap #0
		dc.l	cpufault					; 33: trap #1
		dc.l	cpufault					; 34: trap #2
		dc.l	cpufault					; 35: trap #3
		dc.l	cpufault					; 36: trap #4
		dc.l	cpufault					; 37: trap #5
		dc.l	cpufault					; 38: trap #6
		dc.l	cpufault					; 39: trap #7
		dc.l	cpufault					; 40: trap #8
		dc.l	cpufault					; 41: trap #9
		dc.l	cpufault					; 42: trap #10
		dc.l	cpufault					; 43: trap #11
		dc.l	cpufault					; 44: trap #12
		dc.l	cpufault					; 45: trap #13
		dc.l	cpufault					; 46: trap #14
		dc.l	cpufault					; 47: trap #15
		dc.l	cpufault					; 48: unassigned, reserved
		dc.l	cpufault					; 49: unassigned, reserved
		dc.l	cpufault					; 50: unassigned, reserved
		dc.l	cpufault					; 51: unassigned, reserved
		dc.l	cpufault					; 52: unassigned, reserved
		dc.l	cpufault					; 53: unassigned, reserved
		dc.l	cpufault					; 54: unassigned, reserved
		dc.l	cpufault					; 55: unassigned, reserved
		dc.l	cpufault					; 56: unassigned, reserved
		dc.l	cpufault					; 57: unassigned, reserved
		dc.l	cpufault					; 58: unassigned, reserved
		dc.l	cpufault					; 59: unassigned, reserved
		dc.l	cpufault					; 60: unassigned, reserved
		dc.l	cpufault					; 61: unassigned, reserved
		dc.l	cpufault					; 62: unassigned, reserved
		dc.l	cpufault					; 63: unassigned, reserved

; game header info
header:
		dc.b	"SEGA MEGA DRIVE "				; console name
		dc.b	"                "				; copyright name/date
		dc.b	"                                                "
		dc.b	"COLOUR CYCLE: THE DEFINITIVE GAME               "
		dc.b	"GM 00000000-00"				; product no.
		dc.w	$0						; checksum
		dc.b	"J               "				; supported devices
		dc.l	vectors						; rom start
		dc.l	romend-1					; rom end
		dc.l	$FF0000						; ram start
		dc.l	$FFFFFF						; ram end
		dc.l	$20202020					; sram support (disabled)
		dc.l	$20202020					; sram end
		dc.l	$20202020					; modem
		dc.b	"                                                    "
		dc.b	"JUE             "				; region

; 68k exception handler (freezes the cpu)
cpufault:
		nop
		nop
		bra.s	cpufault

; this is where the fun begins
startup:
		tst.l	$A10008						; test port A & B control registers
		bne.s	initz80
		tst.l	$A1000C						; test port C control register
		bne.s	initz80						; was it a soft reset?
		move.b	$A10001, d0					; get HW ver
		andi.b	#$0F, d0					; compare to rev 0
		beq.s	initz80						; non-TMSS systems only, otherwise...
		move.l	#"SEGA", $A14000				; make the TMSS happy

; z80 initialization area
initz80:
		move.w	#$100, z80req					; request z80 bus
		move.w	#$100, z80reset					; reset z80

z80wait:
		btst	#$0, z80req					; is bus access granted?
		bne.s	z80wait						; if not, branch
		lea	z80code, a1
		lea	z80ram, a2					; target z80 ram space ($A00000-$A0FFFF)
		move.w	#z80end-z80code-1,d1				; how many times to copy?

z80loop:
		move.b	(a1)+, (a2)+					; copy code to z80 ram
		dbf	d1, z80loop					; copy until finished
		bra.w	z80end						; finish up

; z80 startup instructions		
z80code:
		dc.b	$AF						; xor	a
		dc.b	$01, $D9, $1F					; ld	bc,1fd9h
		dc.b	$11, $27, $00					; ld	de,0027h
		dc.b	$21, $26, $00					; ld	hl,0026h
		dc.b	$F9						; ld	sp,hl
		dc.b	$77						; ld	(hl),a
		dc.b	$ED, $B0					; ldir
		dc.b	$DD, $E1					; pop	ix
		dc.b	$FD, $E1					; pop	iy
		dc.b	$ED, $47					; ld	i,a
		dc.b	$ED, $4F					; ld	r,a
		dc.b	$D1						; pop	de
		dc.b	$E1						; pop	hl
		dc.b	$F1						; pop	af
		dc.b	$08						; ex	af,af'
		dc.b	$D9						; exx
		dc.b	$C1						; pop	bc
		dc.b	$D1						; pop	de
		dc.b	$E1						; pop	hl
		dc.b	$F1						; pop	af
		dc.b	$F9						; ld	sp,hl
		dc.b	$F3						; di
		dc.b	$ED, $56					; im1
		dc.b	$36, $E9					; ld	(hl),e9h
		dc.b	$E9						; jp	(hl)
		
z80end:
		move.w	#$0, z80req					; release z80 bus
		move.w	#$0, z80reset					; reset z80

silencepsg:
		lea	psg, a3						; target psg at $C00011
		move.b	#$9F, (a3)					; set 1st PSG channel to silence
		move.b	#$BF, (a3)					; set 2nd PSG channel to silence
		move.b	#$DF, (a3)					; set 3rd PSG channel to silence
		move.b	#$FF, (a3)					; set 4th PSG channel to silence

; setup vdp (320x224 resolution, 40 col x 28 lines)
initvdp:
		lea	vdpctrl, a0					; target vdp control register at $C00004
		move.l	#$80048114, (a0)				; reg $80/81: 8 colour mode + md mode, dma enabled
		move.l	#$82308340, (a0)				; reg $82/83: foreground + window nametable addr
		move.l	#$8407856A, (a0)				; reg $84/85: background + sprite nametable addr
		move.l	#$86008700, (a0)				; reg $86/87: unused + background colour
		move.l	#$8A008B08, (a0)				; reg $8A/8B: hblank reg + fullscreen scroll
		move.l	#$8C818D34, (a0)				; reg $8C/8D: 40 cell display + hscroll table addr
		move.l	#$8E008F00, (a0)				; reg $8E/8F: unused + vdp increment
		move.l	#$90019200, (a0)				; reg $90/92: 64 cell hscroll size + window v pos
		move.l	#$93009400, (a0)				; reg $93/94: dma length
		move.l	#$95009700, (a0)				; reg $95/97: dma source + dma fill vram

laststeps:
		moveq	#0, usp						; zero out usp (will this work?)

main:
		moveq	#0, d0						; clear d0
		move.w	#$8F00, vdpctrl					; always assume word increment
		move.l	#$C0000003, vdpctrl				; cram write mode
		
main_loop:
		move.w	d0, vdpdata					; write prev value (if loop >=1)
		add.w	#1, d0						; add one to change colour
		move.w	#100, d1					; how long to delay?

main_wait:
		dbf	d1, main_wait					; coded like this for extra delay
		jmp	main_loop					; should give us a mostly straight line

; dma or midframe cram swaps not used here
useless:
		rte							; may be replaced as development progresses

; end of rom
romend:
		end
