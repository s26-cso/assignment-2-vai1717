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
#
.section .rodata # Start of read-only data section for constants
fmt_d:   .string "%d"   # printf format for a single int # String format for printing integers

.text # Start of the executable code section
.globl main # Export main function so it can be called

# Register allocation: # Explanation of how registers are used
#   s0 = arr    (int*)            — input values, 4 bytes each # s0 stores pointer to input array
#   s1 = result (int*)            — output answers, 4 bytes each # s1 stores pointer to result array
#   s2 = stk    (int*)            — monotonic stack of indices # s2 stores pointer to our stack tracking array
#   s3 = n                        — number of elements # s3 stores total count of numbers
#   s4 = stk_top                  — current stack depth (0 = empty) # s4 tracks how many items are in the stack
#   s5 = i                        — loop counter # s5 is used as the index 'i' in our loops
#   s6 = base of argv[1]          — &argv[1], pointer arithmetic in 8-byte steps # s6 points to the string arguments
#   s7 = n*4 (byte stride for int arrays) # s7 stores total byte size for integer arrays

main: # Main function entry point
    # ── prologue ────────────────────────────────────────────────── # Start of function prologue
    addi sp, sp, -80           # Allocate 80 bytes on stack (16-byte aligned)
    sd   ra, 72(sp)            # Save return address to stack
    sd   s0, 64(sp)            # Save register s0 to stack
    sd   s1, 56(sp)            # Save register s1 to stack
    sd   s2, 48(sp)            # Save register s2 to stack
    sd   s3, 40(sp)            # Save register s3 to stack
    sd   s4, 32(sp)            # Save register s4 to stack
    sd   s5, 24(sp)            # Save register s5 to stack
    sd   s6, 16(sp)            # Save register s6 to stack
    sd   s7,  8(sp)            # Save register s7 to stack

    # a0=argc, a1=argv # Reminds us a0 contains argument count, a1 contains argument array
    addi s3, a0, -1            # n = argc - 1  (number of elements) # Calculate true number of inputs
    addi s6, a1, 8             # s6 = &argv[1] # Point s6 to the first input argument string

    blez s3, .exit_ok          # n <= 0: nothing to print # If no elements were given, exit the program

    # ── allocate three int arrays: arr, result, stk ─────────────── # Section for reserving memory
    # Total: n * 4 * 3 = n * 12 bytes # We need enough memory for 3 integer arrays
    slli s7, s3, 2             # s7 = n * 4 # Multiply number of elements by 4 bytes (int size)
    slli t0, s3, 2             # Multiply n by 4, store in t0 temporarily
    slli t1, t0, 1             # Multiply t0 by 2, store in t1  (so t1 = n * 8)
    add  a0, t0, t1            # a0 = n*4 + n*8 = n*12 # Add to get total needed bytes (n*12)
    call malloc                # Allocate this memory using malloc # Call malloc to get the memory block
    beqz a0, .exit_ok          # malloc failed → exit gracefully # If memory wasn't granted, exit program

    mv   s0, a0                # arr    starts at a0 # arr points to start of allocated block
    add  s1, s0, s7            # result starts at arr + n*4 # result points after arr ends
    add  s2, s1, s7            # stk    starts at result + n*4 # stk points after result ends

    # ── parse argv[1..n] → arr[] ────────────────────────────────── # Section to convert string arguments to ints
    li   s5, 0                 # Set loop counter s5 (i) to 0
.parse: # Label indicating start of parse loop
    bge  s5, s3, .parse_end    # If i >= n, exit loop
    slli t0, s5, 3             # i * 8 (pointer width) # Calculate byte offset for pointer array (8 bytes each)
    add  t0, s6, t0            # &argv[i+1] # Add offset to base argument pointer
    ld   a0, 0(t0)             # argv[i+1] (char*) # Load the string pointer into a0
    call atoi                  # a0 = integer # Convert string to integer using atoi
    slli t0, s5, 2             # i * 4 (int width) # Calculate integer offset (4 bytes each)
    add  t0, s0, t0            # Find address in our arr where this int should go
    sw   a0, 0(t0)             # arr[i] = value # Store the int in the array
    addi s5, s5, 1             # i++ # Move to next index
    j    .parse                # Jump to start of parse loop
.parse_end: # Label for end of parse loop

    # ── initialise result[] to -1 ───────────────────────────────── # Section to prepare result array
    li   s5, 0                 # Reset loop counter s5 (i) to 0
    li   t2, -1                # Set t2 to -1, which is our default not-found answer
.init: # Label for initialise loop
    bge  s5, s3, .init_end     # If i >= n, exit this loop
    slli t0, s5, 2             # Calculate offset for current result item
    add  t0, s1, t0            # Find address in the result array
    sw   t2, 0(t0)             # result[i] = -1 # Store -1 at the result index
    addi s5, s5, 1             # i++ # Move to next index
    j    .init                 # Jump to start of init loop
.init_end: # Label for end of init loop

    # ── monotonic stack: right-to-left ──────────────────────────── # Section where main logic happens
    li   s4, 0                 # stk_top = 0 (stack empty) # Init stack as empty
    addi s5, s3, -1            # i = n - 1 # Start loop counter from the very last element index

.nge_loop: # Label for next-greater-element main loop
    bltz s5, .nge_done         # If completed all elements (i < 0), we are done

    # t1 = arr[i] # Setup to get current array value
    slli t0, s5, 2             # Calculate array offset for current element
    add  t0, s0, t0            # Determine address in array
    lw   t1, 0(t0)             # t1 = arr[i]  (sign-extended) # Load the current element value into t1

    # pop indices whose values are <= arr[i] # Remove useless indices from stack
.pop: # Label for popping elements
    beqz s4, .pop_done         # stack empty # If stack is empty, nothing to pop, exit pop loop
    addi t2, s4, -1            # Temporarily subtract 1 from stack top to peek at elements
    slli t2, t2, 2             # Calculate stack offset
    add  t2, s2, t2            # Determine memory address in stack array
    lw   t3, 0(t2)             # t3 = stk[top-1]  (an index) # Get the index sitting at top of stack
    slli t4, t3, 2             # Setup to retrieve value at that index
    add  t4, s0, t4            # Get memory address in data array
    lw   t4, 0(t4)             # t4 = arr[t3]     (a value) # Get the actual array value
    bgt  t4, t1, .pop_done     # arr[stk.top] > arr[i] → stop popping # If stack top element is greater than current, stop popping
    addi s4, s4, -1            # Decrease stack size by 1 (it pops the item)
    j    .pop                  # Loop to pop next element
.pop_done: # Label when popping is finished

    # if stack not empty, result[i] = stk.top() # Checking if any element left in stack
    beqz s4, .no_result        # If stack is empty, jump past setting a result
    addi t2, s4, -1            # Get index of stack top
    slli t2, t2, 2             # Calculate offset in stack memory
    add  t2, s2, t2            # Find address of stack top memory
    lw   t3, 0(t2)             # t3 = stk.top() index # Read index from stack top
    slli t0, s5, 2             # Calculate offset for result array
    add  t0, s1, t0            # Find target memory in result array
    sw   t3, 0(t0)             # result[i] = t3 # Store the index found as the next greater element
.no_result: # Label for jump target when there is no result

    # stk.push(i) # Push current index on to stack
    slli t0, s4, 2             # Calculate offset for new stack top location
    add  t0, s2, t0            # Find address in stack memory
    sw   s5, 0(t0)             # stk[stk_top] = i # Save the current loop index on stack
    addi s4, s4, 1             # stk_top++ # Increase stack size counter

    addi s5, s5, -1            # i-- # Move to the previous index
    j    .nge_loop             # Loop for next integer
.nge_done: # Label for when the full next-greater-element loop is finished

    # ── print result[] space-separated, then newline ────────────── # Output section starts
    li   s5, 0                 # reset loop counter s5 (i) to 0
.print: # Label for printing loop
    bge  s5, s3, .print_done   # if i >= n, all elements have been printed

    bgtz s5, .print_space      # print space before elements 1..n-1 # Only print spaces between elements
    j    .print_val            # For first element run straight to printing value
.print_space: # Label to print space
    li   a0, ' '               # Load space char into register a0
    call putchar               # Print a single space character
.print_val: # Label to print value
    la   a0, fmt_d             # Load %d format string into a0 for printf
    slli t0, s5, 2             # Calculate offset for current result item
    add  t0, s1, t0            # Find address in result array
    lw   a1, 0(t0)             # result[i]  (sign-extended for printf %d) # Load result value into a1
    call printf                # Call printf to print the result integer

    addi s5, s5, 1             # i++ # Move to next index
    j    .print                # Loop to next element
.print_done: # Label indicating all results printed

    li   a0, '\n'              # Load newline char into register a0
    call putchar               # Print a newline character

.exit_ok: # Label for successful exit path
    li   a0, 0                 # return 0 # Set return code to 0

    # ── epilogue ───────────────────────────────────────────────── # Restore saved register context and exit
    ld   ra, 72(sp)            # Restore return address from stack
    ld   s0, 64(sp)            # Restore register s0 from stack
    ld   s1, 56(sp)            # Restore register s1 from stack
    ld   s2, 48(sp)            # Restore register s2 from stack
    ld   s3, 40(sp)            # Restore register s3 from stack
    ld   s4, 32(sp)            # Restore register s4 from stack
    ld   s5, 24(sp)            # Restore register s5 from stack
    ld   s6, 16(sp)            # Restore register s6 from stack
    ld   s7,  8(sp)            # Restore register s7 from stack
    addi sp, sp, 80            # Deallocate 80 bytes from stack
    ret                        # Return control to caller

