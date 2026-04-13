# q5.s — Palindrome checker  (O(n) time, O(1) space)
# RV64, LP64 ABI, linked with glibc
#
# Reads "input.txt", checks whether its contents form a palindrome.
# Uses two file descriptors so only O(1) extra memory is needed:
#   fd1 reads left-to-right sequentially,
#   fd2 seeks to the right end for each comparison.
#
# Prints "Yes" or "No" (with newline).

.section .rodata
filename:
    .string "input.txt"
yes_msg:
    .string "Yes"
no_msg:
    .string "No"

.text
.globl main

main:
    # ---- Prologue ----
    addi sp, sp, -48
    sd   ra, 40(sp)
    sd   s0, 32(sp)          # s0 = fd_left
    sd   s1, 24(sp)          # s1 = fd_right
    sd   s2, 16(sp)          # s2 = left position
    sd   s3, 8(sp)           # s3 = right position
    # sp+0 .. sp+1 : two 1-byte read buffers

    # ---- Open file twice (two independent cursors) ----
    la   a0, filename
    li   a1, 0               # O_RDONLY
    li   a2, 0
    call open
    mv   s0, a0              # s0 = fd_left

    la   a0, filename
    li   a1, 0
    li   a2, 0
    call open
    mv   s1, a0              # s1 = fd_right

    # ---- Get file size via lseek(fd_right, 0, SEEK_END) ----
    mv   a0, s1
    li   a1, 0
    li   a2, 2               # SEEK_END
    call lseek
    mv   s3, a0              # s3 = file_size

    # ---- Handle empty file ----
    blez s3, .is_palindrome

    # ---- Strip possible trailing newline ----
    addi s3, s3, -1          # s3 = index of last byte
    mv   a0, s1
    mv   a1, s3
    li   a2, 0               # SEEK_SET
    call lseek               # seek fd_right to last byte
    mv   a0, s1
    addi a1, sp, 1           # buffer at sp+1
    li   a2, 1
    call read                # read last byte
    lb   t0, 1(sp)
    li   t1, 10              # '\n'
    bne  t0, t1, .no_strip
    addi s3, s3, -1          # exclude newline from check
.no_strip:

    # ---- Palindrome check ----
    li   s2, 0               # left = 0

.check_loop:
    bge  s2, s3, .is_palindrome   # left >= right → palindrome

    # Read left byte (fd_left cursor advances automatically)
    mv   a0, s0
    mv   a1, sp              # buffer at sp+0
    li   a2, 1
    call read

    # Seek fd_right to position 'right', then read 1 byte
    mv   a0, s1
    mv   a1, s3
    li   a2, 0               # SEEK_SET
    call lseek
    mv   a0, s1
    addi a1, sp, 1           # buffer at sp+1
    li   a2, 1
    call read

    # Compare
    lb   t0, 0(sp)           # left char
    lb   t1, 1(sp)           # right char
    bne  t0, t1, .not_palindrome

    addi s2, s2, 1           # left++
    addi s3, s3, -1          # right--
    j    .check_loop

.is_palindrome:
    la   a0, yes_msg
    call puts
    j    .cleanup

.not_palindrome:
    la   a0, no_msg
    call puts

.cleanup:
    mv   a0, s0
    call close
    mv   a0, s1
    call close

    li   a0, 0               # exit(0)

    # ---- Epilogue ----
    ld   ra, 40(sp)
    ld   s0, 32(sp)
    ld   s1, 24(sp)
    ld   s2, 16(sp)
    ld   s3, 8(sp)
    addi sp, sp, 48
    ret
