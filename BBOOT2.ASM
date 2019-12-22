;	bboot.asm
;	boot sector for A: drive which allows boot from B: drive
;	(c) 1992,1993 Chris Green
;
OLDINTOFS	EQU	004CH
OLDINTSEG	EQU 	004EH
NEWINTOFS	EQU	OLDINTOFS
NEWINTSEG	EQU 	OLDINTSEG

CODE	SEGMENT 'CODE'
	ASSUME CS:CODE,DS:NOTHING,ES:NOTHING,SS:NOTHING
	ORG 0000H
START:
	JMP	PASTDATA
	DB	'IBM  5.0'
	DW	512	; bytes per sector
	DB	1	; sectors per cluster
	DW	1	; reserved sectors
	DB	2	; number of FATs
	DW	224	; root directory entries
	DW	2880	; number of sectors
	DB	0F0H	; media descriptor
	DW	9	; sectors per FAT
	DW	18	; sectors per track
	DW	2	; heads
	DD	0	;hidden sectors
	DD	0	;long sectors
	DB	0	; physical drive number
	DB	0	;reserved
	DB	029H	;signature byte for extended boot record
	DD	0	;serial number
	DB	'NO NAME    '	;volume label
	DB	'FAT12   '	;reserved
ProgMsg	DB	'B:Boot',0dh,0ah
	DB	'(c)1992,1993 Chris Green',0dh,0ah
	DB	0dh,0ah
	DB	'Translate A: drive to B: drive at BIOS level!',0dh,0ah
ErrMsg	DB	'Disk read error: either remove B:Boot disk from drive A:'
	DB	0dh,0ah,'and press Ctrl-Alt-Del',0dh,0ah
	DB	'or insert bootable disk in B: drive',0dh,0ah
	DB	'and press a key',0dh,0ah
ErrorC	DB	0
PASTDATA:
	XOR	AX,AX
	MOV	DS,AX
	MOV	SS,AX
	MOV	SP,7C00H
	MOV	AX,DS:[0413h] 		; reduce DOS memory by 1K
	DEC	AX
	MOV	DS:[0413h],AX
	MOV	CL,06
	SHL	AX,CL
	MOV	ES,AX
	MOV	CX,0200H	      	; relocate to top of memory
	MOV	SI,7C00H
	XOR	DI,DI
	CLD
	REPZ	MOVSB
	MOV	AX,ES
	PUSH	AX
	MOV	AX,OFFSET Continue
	PUSH	AX
	RETF				; jump to our relocated self
CONTINUE:
	XOR	AX,AX
	MOV	DS,AX
	MOV	AX,DS:[OldIntOfs]	; save original int 13 handler
	MOV	WORD PTR CS:ExitHandler+1,AX
	MOV	AX,DS:[OldIntSeg]
	MOV	WORD PTR CS:ExitHandler+3,AX
				;put ourselves in as new int 13 handler
	MOV	WORD PTR DS:[NewIntOfs],OFFSET StartHandler
	MOV	AX,CS
	MOV	DS:[NewIntSeg],AX

	MOV	AX,CS
	MOV	DS,AX
	MOV	ES,AX
	ASSUME	DS:CODE,ES:CODE
RetryDiskLoop:				; clears screen and (re)displays msg
	MOV	AH,0fh
	INT	10h			; get current display mode
	MOV	AH,0h
	INT	10h			; set video mode - ie CLS
	MOV	AH,13h			; display copyright notice
	MOV	AL,1
	MOV	BX,000eh
	MOV	CX,ErrMsg-ProgMsg
	MOV	DX,0000h
	MOV	BP,Offset ProgMsg
	INT	10h
DiskLoop:
	XOR	AH,AH	; reset disk system
	MOV	DL,0	; B: drive (now referred to as A:)
	INT	13H
	JC	DveError
	MOV	AX,0201H	;read one sector
	MOV	BX,07C0H
	MOV	ES,BX
	XOR	BX,BX		; read buffer is 07C0:0000
	MOV	CX,0001H	; track 0, sector 1
	MOV	DX,0000H	; head 0, A: drive (ie B: drive)
	INT	13H
	JE	NextRead		; read succeeded
DveError:
	INC	ErrorC
	CMP	ErrorC,5
	JB	DiskLoop		;loop around
	MOV	AX,CS			;write error message
	MOV	ES,AX
	MOV	AH,13h
	MOV	AL,1
	MOV	BX,000fh
	MOV	CX,ErrorC-ErrMsg
	MOV	DX,600h
	MOV	BP,Offset ErrMsg
	INT	10h
	MOV	AH,0
	INT	16h
	MOV	ErrorC,0		;reset error counter
	JMP	RetryDiskLoop		;loop around
NextRead:			;if we successfully read, this jumps
	XOR	AX,AX		;to the new boot sector. We musn't
	PUSH	AX		;do this unless we have read a new
	MOV	AX,7C00H	;boot sector though - we're not reentrant!
	PUSH	AX
	RETF			; "jump" to the boot sector we just read
;new interrupt 13h handler
StartHandler:
	CMP	AH,08h
	JLE	ChangeIt
	CMP	AH,15h
	JB	ExitHandler
ChangeIt:
	CMP	DL,00h	;reference to A: drive becomes B: drive
	JNE	ChkB
	MOV	DL,01h
	JMP	SHORT ExitHandler	;all the stuff to make B into
ChkB:					;A: seemed to cause loops so dropped.
	CMP	DL,01h	;reference to B: drive becomes A: drive
	JNE	ExitHandler
	MOV	DL,00h
ExitHandler:
	DB	11101010b,0,0,0,0	;this is a inter-segment direct
HandleEnd:				;jump which I couldn't convince
CODE	ENDS				;the assembler to let me code!

	END

