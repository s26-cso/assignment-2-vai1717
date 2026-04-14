# q2.s — Next Greater Element (NGE) using a monotonic stack
# RV64, LP64 ABI, statically linked with glibc.
#
# For each element arr[i], output the 0-indexed position of the
# first element to its right that is strictly greater.
# Output -1 if no such element exists.
#
# Input:  command-line args  argv[1..argc-1]  (space-separated ints)
# Output: space-separated integers on one line, followed by newline.
#
# Complexity: O(n) time, O(n) space.
#
# Algorithm (right-to-left monotonic stack):
#   result = [-1, -1, ..., -1]
#   stack  = empty                     // stores indices
#   for i = n-1 downto 0:
#       while stack not empty AND arr[stack.top()] <= arr[i]:
#           stack.pop()
#       if stack not empty:
#           result[i] = stack.top()
#       stack.push(i)
#   print result

.section .rodata
fmt_d:   .string "%d"   # printf format for a single int

.text
.globl main

# Register allocation:
#   s0 = arr    (int*)            — input values, 4 bytes each
#   s1 = result (int*)            — output answers, 4 bytes each
#   s2 = stk    (int*)            — monotonic stack of indices
#   s3 = n                        — number of elements
#   s4 = stk_top                  — current stack depth (0 = empty)
#   s5 = i                        — loop counter
#   s6 = base of argv[1]          — &argv[1], pointer arithmetic in 8-byte steps
#   s7 = n*4 (byte stride for int arrays)
main:
    # ── prologue ──────────────────────────────────────────────────
    addi sp, sp, -64
    sd   ra, 56(sp)
    sd   s0, 48(sp)
    sd   s1, 40(sp)
    sd   s2, 32(sp)
    sd   s3, 24(sp)
    sd   s4, 16(sp)
    sd   s5,  8(sp)
    sd   s6,  0(sp)
    # s7 stored in the slot we reuse after saving — add more space or use stack slot
    addi sp, sp, -8
    sd   s7, 0(sp)

    # a0=argc, a1=argv
    addi s3, a0, -1            # n = argc - 1  (number of elements)
    addi s6, a1, 8             # s6 = &argv[1]

    blez s3, .exit_ok          # n <= 0: nothing to print

    # ── allocate three int arrays: arr, result, stk ───────────────
    # Total: n * 4 * 3 = n * 12 bytes
    slli s7, s3, 2             # s7 = n * 4
    slli t0, s3, 2
    slli t1, t0, 1
    add  a0, t0, t1            # a0 = n*4 + n*8 = n*12
    call malloc
    beqz a0, .exit_ok          # malloc failed → exit gracefully

    mv   s0, a0                # arr    starts at a0
    add  s1, s0, s7            # result starts at arr + n*4
    add  s2, s1, s7            # stk    starts at result + n*4

    # ── parse argv[1..n] → arr[] ──────────────────────────────────
    li   s5, 0
.parse:
    bge  s5, s3, .parse_end
    slli t0, s5, 3             # i * 8 (pointer width)
    add  t0, s6, t0            # &argv[i+1]
    ld   a0, 0(t0)             # argv[i+1] (char*)
    call atoi                  # a0 = integer
    slli t0, s5, 2             # i * 4 (int width)
    add  t0, s0, t0
    sw   a0, 0(t0)             # arr[i] = value
    addi s5, s5, 1
    j    .parse
.parse_end:

    # ── initialise result[] to -1 ─────────────────────────────────
    li   s5, 0
    li   t2, -1
.init:
    bge  s5, s3, .init_end
    slli t0, s5, 2
    add  t0, s1, t0
    sw   t2, 0(t0)             # result[i] = -1
    addi s5, s5, 1
    j    .init
.init_end:

    # ── monotonic stack: right-to-left ────────────────────────────
    li   s4, 0                 # stk_top = 0 (stack empty)
    addi s5, s3, -1            # i = n - 1

.nge_loop:
    bltz s5, .nge_done

    # t1 = arr[i]
    slli t0, s5, 2
    add  t0, s0, t0
    lw   t1, 0(t0)             # t1 = arr[i]  (sign-extended)

    # pop indices whose values are <= arr[i]
.pop:
    beqz s4, .pop_done         # stack empty
    addi t2, s4, -1
    slli t2, t2, 2
    add  t2, s2, t2
    lw   t3, 0(t2)             # t3 = stk[top-1]  (an index)
    slli t4, t3, 2
    add  t4, s0, t4
    lw   t4, 0(t4)             # t4 = arr[t3]     (a value)
    bgt  t4, t1, .pop_done     # arr[stk.top] > arr[i] → stop popping
    addi s4, s4, -1
    j    .pop
.pop_done:

    # if stack not empty, result[i] = stk.top()
    beqz s4, .no_result
    addi t2, s4, -1
    slli t2, t2, 2
    add  t2, s2, t2
    lw   t3, 0(t2)             # t3 = stk.top() index
    slli t0, s5, 2
    add  t0, s1, t0
    sw   t3, 0(t0)             # result[i] = t3
.no_result:

    # stk.push(i)
    slli t0, s4, 2
    add  t0, s2, t0
    sw   s5, 0(t0)             # stk[stk_top] = i
    addi s4, s4, 1

    addi s5, s5, -1
    j    .nge_loop
.nge_done:

    # ── print result[] space-separated, then newline ──────────────
    li   s5, 0
.print:
    bge  s5, s3, .print_done

    bgtz s5, .print_space      # print space before elements 1..n-1
    j    .print_val
.print_space:
    li   a0, ' '
    call putchar
.print_val:
    la   a0, fmt_d
    slli t0, s5, 2
    add  t0, s1, t0
    lw   a1, 0(t0)             # result[i]  (sign-extended for printf %d)
    call printf

    addi s5, s5, 1
    j    .print
.print_done:

    li   a0, '\n'
    call putchar

.exit_ok:
    li   a0, 0                 # return 0

    # ── epilogue ─────────────────────────────────────────────────
    ld   s7, 0(sp)
    addi sp, sp, 8
    ld   ra, 56(sp)
    ld   s0, 48(sp)
    ld   s1, 40(sp)
    ld   s2, 32(sp)
    ld   s3, 24(sp)
    ld   s4, 16(sp)
    ld   s5,  8(sp)
    ld   s6,  0(sp)
    addi sp, sp, 64
    ret
