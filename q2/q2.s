# q2.s — Next Greater Element (monotonic stack, O(n) time/space)
# RV64, LP64 ABI, linked with glibc
#
# For each element in the array, find the 0-indexed position of the
# next greater element to its right.  Print -1 if none exists.
#
# Input:  command-line arguments (space-separated integers)
# Output: space-separated positions (or -1), one line
#
# Algorithm (from pseudocode):
#   stack = empty ;  result = [-1, -1, ..., -1]
#   for i = n-1 downto 0:
#       while !stack.empty() && arr[stack.top()] <= arr[i]:  stack.pop()
#       if !stack.empty():  result[i] = stack.top()
#       stack.push(i)

.section .rodata
fmt_int:
    .string "%d"

.text
.globl main

main:
    # ---- Prologue ----
    addi sp, sp, -80
    sd   ra, 72(sp)
    sd   s0, 64(sp)          # s0 = arr  (int*)
    sd   s1, 56(sp)          # s1 = result (int*)
    sd   s2, 48(sp)          # s2 = stk  (int*)  — stack array
    sd   s3, 40(sp)          # s3 = n
    sd   s4, 32(sp)          # s4 = stk_top
    sd   s5, 24(sp)          # s5 = loop counter i
    sd   s6, 16(sp)          # s6 = argv+8  (pointer to argv[1])
    sd   s7, 8(sp)           # s7 = scratch

    # a0 = argc,  a1 = argv
    addi s3, a0, -1          # s3 = n = argc - 1
    addi s6, a1, 8           # s6 = &argv[1]

    blez s3, .done           # if n <= 0, nothing to do

    # ---- Allocate arr[n] + result[n] + stk[n] = 12·n bytes ----
    slli a0, s3, 2           # n * 4
    mv   s7, a0             # save n*4
    slli a0, a0, 1           # n * 8
    add  a0, a0, s7          # n * 12
    call malloc
    beqz a0, .done           # Exit safely if malloc fails

    mv   s0, a0              # s0 = arr
    add  s1, s0, s7          # s1 = result = arr + n*4
    add  s2, s1, s7          # s2 = stk    = result + n*4

    # ---- Parse argv[1..n] into arr[] ----
    li   s5, 0               # i = 0
.parse_loop:
    bge  s5, s3, .parse_done
    slli t0, s5, 3           # i * 8  (pointer size)
    add  t0, s6, t0          # &argv[i+1]
    ld   a0, 0(t0)           # argv[i+1]
    call atoi                # a0 = integer value
    slli t0, s5, 2           # i * 4
    add  t0, s0, t0          # &arr[i]
    sw   a0, 0(t0)           # arr[i] = value
    addi s5, s5, 1
    j    .parse_loop
.parse_done:

    # ---- Initialise result[] to -1 ----
    li   s5, 0
    li   t1, -1
.init_loop:
    bge  s5, s3, .init_done
    slli t0, s5, 2
    add  t0, s1, t0
    sw   t1, 0(t0)           # result[i] = -1
    addi s5, s5, 1
    j    .init_loop
.init_done:

    # ---- Monotonic-stack algorithm ----
    li   s4, 0               # stk_top = 0 (stack is empty)
    addi s5, s3, -1          # i = n - 1

.algo_loop:
    bltz s5, .algo_done      # if i < 0, finished

    # t1 = arr[i]
    slli t0, s5, 2
    add  t0, s0, t0
    lw   t1, 0(t0)

.pop_loop:
    beqz s4, .pop_done       # stack empty → stop popping
    # t3 = stk[stk_top - 1]  (top index)
    addi t2, s4, -1
    slli t2, t2, 2
    add  t2, s2, t2
    lw   t3, 0(t2)           # t3 = top-of-stack index
    # t4 = arr[t3]
    slli t4, t3, 2
    add  t4, s0, t4
    lw   t4, 0(t4)           # t4 = arr[stack.top()]
    bgt  t4, t1, .pop_done   # arr[stack.top()] > arr[i] → stop
    addi s4, s4, -1          # pop
    j    .pop_loop
.pop_done:

    # if stack not empty, result[i] = stack.top()
    beqz s4, .skip_result
    addi t2, s4, -1
    slli t2, t2, 2
    add  t2, s2, t2
    lw   t3, 0(t2)           # t3 = stack.top()
    slli t0, s5, 2
    add  t0, s1, t0
    sw   t3, 0(t0)           # result[i] = stack.top()
.skip_result:

    # stack.push(i)
    slli t0, s4, 2
    add  t0, s2, t0
    sw   s5, 0(t0)           # stk[stk_top] = i
    addi s4, s4, 1           # stk_top++

    addi s5, s5, -1          # i--
    j    .algo_loop
.algo_done:

    # ---- Print results ----
    li   s5, 0               # i = 0
.print_loop:
    bge  s5, s3, .print_done

    # print space before every element except the first
    beqz s5, .no_space
    li   a0, 32              # ' '
    call putchar
.no_space:
    # printf("%d", result[i])
    la   a0, fmt_int
    slli t0, s5, 2
    add  t0, s1, t0
    lw   a1, 0(t0)           # result[i]
    call printf

    addi s5, s5, 1
    j    .print_loop
.print_done:

    # trailing newline
    li   a0, 10              # '\n'
    call putchar

.done:
    li   a0, 0               # return 0

    # ---- Epilogue ----
    ld   ra, 72(sp)
    ld   s0, 64(sp)
    ld   s1, 56(sp)
    ld   s2, 48(sp)
    ld   s3, 40(sp)
    ld   s4, 32(sp)
    ld   s5, 24(sp)
    ld   s6, 16(sp)
    ld   s7, 8(sp)
    addi sp, sp, 80
    ret
