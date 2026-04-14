# q5.s — Palindrome checker  (O(n) time, O(1) space)
# RV64, LP64 ABI, linked with glibc.
#
# Reads "input.txt" from the current directory.
# The file contains only lowercase alphabets (and possibly a trailing
# newline).  Prints "Yes" if the string is a palindrome, "No" otherwise.
#
# Strategy (two-pointer, O(1) space):
#   Open the file twice to get two independent file-position cursors.
#   fd_left  reads sequentially from position 0 forward.
#   fd_right seeks backwards from the last content byte.
#   Compare fd_left[i] with fd_right[n-1-i] for i = 0,1,...
#   Stop when the two pointers meet or cross.
#
# System calls used (via glibc wrappers):
#   open, lseek, read, close, puts
#
# Stack frame layout (sp after prologue):
#   sp+ 0 : 1-byte buffer for left  char
#   sp+ 1 : 1-byte buffer for right char
#   sp+ 2 : (6 bytes padding for alignment)
#   sp+ 8 : saved s3
#   sp+16 : saved s2
#   sp+24 : saved s1
#   sp+32 : saved s0
#   sp+40 : saved ra
#   (frame size = 48, 16-byte aligned)

.section .rodata
path_str:   .string "input.txt"
yes_str:    .string "Yes"
no_str:     .string "No"

.text
.globl main

main:
    # ── prologue ─────────────────────────────────────────────────
    addi sp, sp, -48
    sd   ra, 40(sp)          # saved ra
    sd   s0, 32(sp)          # s0 = fd_left
    sd   s1, 24(sp)          # s1 = fd_right
    sd   s2, 16(sp)          # s2 = left  index (advances 0 → …)
    sd   s3,  8(sp)          # s3 = right index (retreats … → 0)
    # sp+0, sp+1 : one-byte read buffers for left and right char

    # ── open file twice ──────────────────────────────────────────
    la   a0, path_str
    li   a1, 0               # O_RDONLY
    li   a2, 0               # mode (ignored for O_RDONLY)
    call open
    mv   s0, a0              # s0 = fd_left

    la   a0, path_str
    li   a1, 0
    li   a2, 0
    call open
    mv   s1, a0              # s1 = fd_right

    # ── get file length: lseek(fd_right, 0, SEEK_END) ───────────
    mv   a0, s1
    li   a1, 0
    li   a2, 2               # SEEK_END
    call lseek
    # a0 = file size ( >= 0 )

    # ── handle empty file → palindrome ──────────────────────────
    beqz a0, .yes

    # ── check and strip trailing newline ─────────────────────────
    # Read the last byte; if it's '\n', exclude it from the check.
    mv   s3, a0              # s3 = file_size (will become right boundary)
    addi s3, s3, -1          # s3 = index of last byte

    # seek fd_right to the last byte and peek at it
    mv   a0, s1
    mv   a1, s3
    li   a2, 0               # SEEK_SET
    call lseek

    mv   a0, s1
    addi a1, sp, 1           # buffer at sp+1
    li   a2, 1
    call read

    lb   t0, 1(sp)
    li   t1, '\n'
    bne  t0, t1, .check_init
    addi s3, s3, -1          # exclude the newline: right boundary = s3-1
    # If file was only "\n", s3 is now -1; handled below.

.check_init:
    li   s2, 0               # left  index = 0

    # ── rewind fd_left to position 0 ─────────────────────────────
    # (fd_left was opened fresh so position is 0 – no seek needed)

    # ── two-pointer loop ─────────────────────────────────────────
.loop:
    # if left >= right, all compared chars matched → palindrome
    bge  s2, s3, .yes

    # read one byte from fd_left (advances automatically)
    mv   a0, s0
    mv   a1, sp              # buffer at sp+0
    li   a2, 1
    call read

    # seek fd_right to current right index and read one byte
    mv   a0, s1
    mv   a1, s3
    li   a2, 0               # SEEK_SET
    call lseek

    mv   a0, s1
    addi a1, sp, 1           # buffer at sp+1
    li   a2, 1
    call read

    # compare the two bytes
    lb   t0,  0(sp)          # left  char
    lb   t1,  1(sp)          # right char
    bne  t0, t1, .no         # mismatch → not a palindrome

    addi s2, s2, 1           # left++
    addi s3, s3, -1          # right--
    j    .loop

.yes:
    la   a0, yes_str
    call puts
    j    .done

.no:
    la   a0, no_str
    call puts

.done:
    mv   a0, s0
    call close
    mv   a0, s1
    call close

    li   a0, 0               # exit status 0

    # ── epilogue ─────────────────────────────────────────────────
    ld   ra, 40(sp)
    ld   s0, 32(sp)
    ld   s1, 24(sp)
    ld   s2, 16(sp)
    ld   s3,  8(sp)
    addi sp, sp, 48
    ret
