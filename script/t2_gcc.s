	.arch armv4t
	.fpu softvfp
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"t2_find_max.c"
	.text
	.global	N
	.data
	.align	2
	.type	N, %object
	.size	N, 4
N:
	.word	10
	.global	array
	.align	2
	.type	array, %object
	.size	array, 40
array:
	.word	-9
	.word	-3
	.word	-7
	.word	-1
	.word	-5
	.word	-8
	.word	-2
	.word	-4
	.word	-6
	.word	0
	.global	result
	.bss
	.align	2
	.type	result, %object
	.size	result, 4
result:
	.space	4
	.text
	.align	2
	.global	find_max
	.syntax unified
	.arm
	.type	find_max, %function
find_max:
	@ Function supports interworking.
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	ldr	r3, .L5
	ldr	r3, [r3]
	str	r3, [fp, #-12]
	mov	r3, #1
	str	r3, [fp, #-8]
	b	.L2
.L4:
	ldr	r2, .L5
	ldr	r3, [fp, #-8]
	ldr	r3, [r2, r3, lsl #2]
	ldr	r2, [fp, #-12]
	cmp	r2, r3
	bge	.L3
	ldr	r2, .L5
	ldr	r3, [fp, #-8]
	ldr	r3, [r2, r3, lsl #2]
	str	r3, [fp, #-12]
.L3:
	ldr	r3, [fp, #-8]
	add	r3, r3, #1
	str	r3, [fp, #-8]
.L2:
	ldr	r3, .L5+4
	ldr	r3, [r3]
	ldr	r2, [fp, #-8]
	cmp	r2, r3
	blt	.L4
	ldr	r2, .L5+8
	ldr	r3, [fp, #-12]
	str	r3, [r2]
	nop
	add	sp, fp, #0
	@ sp needed
	ldr	fp, [sp], #4
	bx	lr
.L6:
	.align	2
.L5:
	.word	array
	.word	N
	.word	result
	.size	find_max, .-find_max
	.ident	"GCC: (Arm GNU Toolchain 15.2.Rel1 (Build arm-15.86)) 15.2.1 20251203"
