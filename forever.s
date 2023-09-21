* forever - respawn command forever
*
* Itagaki Fumihiko 07-Apr-92  Create.
*
* Usage: forever command [ args ... ]

.include doscall.h
.include chrcode.h

.xref DecodeHUPAIR
.xref EncodeHUPAIR
.xref SetHUPAIR
.xref strlen
.xref memmovi
.xref strazbot
.xref fgetc
.xref drvchkp

STACKSIZE	equ	512

.text
start:
		bra.s	start1
		dc.b	'#HUPAIR',0			*  HUPAIR�K���錾
start1:
		lea	stack_bottom,a7			*  A7 := �X�^�b�N�̒�
		move.l	a3,forever_envp			*  ���̃A�h���X���L������
	*
	*  ��L��������؂�l�߂�
	*
		DOS	_GETPDB
		movea.l	d0,a0				*  A0 : PDB�A�h���X
		lea	stack_bottom,a1
		suba.l	a0,a1
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
	*
	*  �������f�R�[�h����
	*
		lea	1(a2),a0
		bsr	strlen
		addq.l	#1,d0
		move.l	d0,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bmi	insufficient_memory

		move.l	d0,args
		movea.l	d0,a1
		bsr	DecodeHUPAIR			*  �������f�R�[�h����
		subq.l	#1,d0
		bcs	usage

		move.l	d0,argc
	*
	*  �V�O�i���������[�`����ݒ肷��
	*
		clr.l	command_envp
		st	in_me
		pea	manage_interrupt_signal(pc)
		move.w	#_CTRLVC,-(a7)
		DOS	_INTVCS
		addq.l	#6,a7
		pea	manage_abort_signal(pc)
		move.w	#_ERRJVC,-(a7)
		DOS	_INTVCS
		addq.l	#6,a7
forever_spawn:
	*
	*  �������G���R�[�h����
	*
		move.l	argc,d1
		movea.l	args,a0
		bsr	strlen
		addq.l	#1,d0
		lea	(a0,d0.l),a1			*  A1 : �������т̐擪
		move.l	#$00ffffff,-(a7)
		DOS	_MALLOC
		addq.l	#4,d7
		sub.l	#$81000000,d0
		cmp.l	#10,d0
		blo	insufficient_memory

		move.l	d0,d2
		subq.l	#8,d2				*  D2.L : �R�}���h���C���̗e��
		move.l	d0,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bmi	insufficient_memory

		addq.l	#8,d0
		move.l	d0,command_line
		movea.l	d0,a0
		move.l	d2,d0
		bsr	EncodeHUPAIR
		bmi	insufficient_memory

		movea.l	command_line,a1
		move.l	d2,d1
		movea.l	args,a2
		bsr	SetHUPAIR
		bmi	insufficient_memory

		subq.l	#8,a1
		suba.l	a1,a0
		move.l	a0,-(a7)
		move.l	a1,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
	*
	*  ���𕡐�����
	*
		movea.l	forever_envp,a1
		addq.l	#4,a1
		movea.l	a1,a0
		bsr	strazbot
		move.l	a0,d2
		addq.l	#1,d2
		sub.l	a1,d2				*  D2.L : ���{�̂̃o�C�g��
		move.l	d2,d1
		addq.l	#5,d1
		bclr	#0,d1				*  D1.L : ���G���A�̃T�C�Y
		move.l	d1,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bmi	insufficient_memory

		move.l	d0,command_envp
		movea.l	d0,a0
		move.l	d1,(a0)+
		move.l	d2,d0
		bsr	memmovi
	*
	*  �R�}���h��spawn����
	*
		movea.l	args,a0
		bsr	drvchkp
		bmi	unable_exec

		move.l	command_envp,-(a7)		*  ���[�U�̊��̃A�h���X
		move.l	command_line,-(a7)		*  �N������v���O�����ւ̈����̃A�h���X
		move.l	a0,-(a7)			*  �N������v���O�����̃p�X���̃A�h���X
		clr.w	-(a7)				*  �t�@���N�V�����FLOAD&EXEC
		sf	in_me
		DOS	_EXEC
		st	in_me
		lea	14(a7),a7
		tst.l	d0
		bmi	unable_exec
respawn:
		lea	stack_bottom,a7
		DOS	_ALLCLOSE			*  Human68k 2.02 BUG�΍�i_EXEC �� ^C �Œ��f�����Ƃ��C�t�@�C���E�n���h�����N���[�Y����Ȃ��j
		move.l	command_envp,-(a7)
		DOS	_MFREE
		move.l	command_line,d0
		subq.l	#8,d0
		move.l	d0,(a7)
		DOS	_MFREE
		addq.l	#4,a7
		bra	forever_spawn
*****************************************************************
manage_abort_signal:
		move.l	#$3fc,d0
		cmp.w	#$100,d1
		bcs	manage_signals

		addq.l	#1,d0
		cmp.w	#$200,d1
		bcs	manage_signals

		addq.l	#2,d0
		cmp.w	#$ff00,d1
		bcc	manage_signals

		cmp.w	#$f000,d1
		bcc	manage_signals

		move.b	d1,d0
		bra	manage_signals

manage_interrupt_signal:
		move.l	#$200,d0
manage_signals:
		tst.b	in_me
		bne	respawn
leave:
		move.w	d0,-(a7)
		DOS	_EXIT2
*****************************************************************
unable_exec:
		lea	msg_unable_to_execute(pc),a0
		bsr	werror
		movea.l	args,a0
		bsr	werror
		lea	msg_quote_crlf(pc),a0
error_leave:
		bsr	werror
		moveq	#1,d0
		bra	leave
*****************************************************************
insufficient_memory:
		lea	msg_insufficient_memory(pc),a0
		bra	error_leave
*****************************************************************
usage:
		lea	msg_usage(pc),a0
		bra	error_leave
*****************************************************************
werror:
		move.l	a1,-(a7)
		movea.l	a0,a1
werror_count:
		tst.b	(a1)+
		bne	werror_count

		subq.l	#1,a1
		suba.l	a0,a1
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		movea.l	(a7)+,a1
		rts
*****************************************************************
.data

	dc.b	0
	dc.b	'## forever 0.0 ##  Copyright(C)1992 by Itagaki Fumihiko',0

msg_usage:			dc.b	'Usage: forever command args ...',CR,LF,0
msg_insufficient_memory:	dc.b	'forever: Insufficient memory.',CR,LF,0
msg_unable_to_execute:		dc.b	'forever: Unable to execute "',0
msg_quote_crlf:			dc.b	'"',CR,LF,0
*****************************************************************
.bss

.even
args:		ds.l	1
argc:		ds.l	1
forever_envp:	ds.l	1
command_line:	ds.l	1
command_envp:	ds.l	1
in_me:		ds.b	1
.even
		ds.b	STACKSIZE
.even
stack_bottom:
*****************************************************************
.end start
