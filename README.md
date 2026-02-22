# EE533-LAB6
Quad HW-Threaded ARM Processor
# EE533 Lab 6 — Quad HW-Threaded ARM Processor

## Files
- arm_pipeline.v   : 4-thread zero-overhead pipeline
- arm_regfile.v    : 64x32 register file (4 threads x 16)
- arm_alu.v        : 32-bit ALU
- imem.v / dmem_32.v : Memory modules
- tb_mt_sort.v     : Testbench (4-thread software verification)
- asm2bin_v3.py    : ARM assembler (GCC -O0 compatible)
- t0~t3 *.c/*.s    : Four independent C programs

## How to Run
1. Compile C programs:
   arm-none-eabi-gcc -S -O0 -march=armv4t -marm t1_array_sum.c -o t1.s

2. Assemble:
   python asm2bin_v3.py t1.s --dump

3. Simulate: Open ISE project, run tb_mt_sort in ISim

## Expected Results
T0 bubble_sort : PASS
T1 array_sum   : PASS (result=550)
T2 find_max    : PASS (result=0)
T3 count_neg   : PASS (result=5)


