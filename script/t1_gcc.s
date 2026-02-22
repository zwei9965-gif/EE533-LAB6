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
	.file	"t1_array_sum.c"
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
	.word	10
	.word	20
	.word	30
	.word	40
	.word	50
	.word	60
	.word	70
	.word	80
	.word	90
	.word	100
	.global	result
	.bss
	.align	2
	.type	result, %object
	.size	result, 4
result:
	.space	4
	.text
	.align	2
	.global	array_sum
	.syntax unified
	.arm
	.type	array_sum, %function
array_sum:
	@ Function supports interworking.
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	mov	r3, #0
	str	r3, [fp, #-12]
	mov	r3, #0
	str	r3, [fp, #-8]
	b	.L2
.L3:
	ldr	r2, .L4
	ldr	r3, [fp, #-8]
	ldr	r3, [r2, r3, lsl #2]
	ldr	r2, [fp, #-12]
	add	r3, r2, r3
	str	r3, [fp, #-12]
	ldr	r3, [fp, #-8]
	add	r3, r3, #1
	str	r3, [fp, #-8]
.L2:
	ldr	r3, .L4+4
	ldr	r3, [r3]
	ldr	r2, [fp, #-8]
	cmp	r2, r3
	blt	.L3
	ldr	r2, .L4+8
	ldr	r3, [fp, #-12]
	str	r3, [r2]
	nop
	add	sp, fp, #0
	@ sp needed
	ldr	fp, [sp], #4
	bx	lr
.L5:
	.align	2
.L4:
	.word	array
	.word	N
	.word	result
	.size	array_sum, .-array_sum
	.ident	"GCC: (Arm GNU Toolchain 15.2.Rel1 (Build arm-15.86)) 15.2.1 20251203"
