# q5.s — Palindrome checker  (O(n) time, O(1) space) # Name of file and algorithm details
# RV64, LP64 ABI, linked with glibc. # Platform and linkage details
#
# Reads "input.txt" from the current directory. # Describes the input file
# The file contains only lowercase alphabets (and possibly a trailing # Describes expected data
# newline).  Prints "Yes" if the string is a palindrome, "No" otherwise. # Expected outputs
#
# Strategy (two-pointer, O(1) space): # Explain dual-pointer reading mechanism
#   Open the file twice to get two independent file-position cursors. # Uses two independent OS file handles
#   fd_left  reads sequentially from position 0 forward. # One reader scans strictly forward
#   fd_right seeks backwards from the last content byte. # One reader jumps sequentially backward
#   Compare fd_left[i] with fd_right[n-1-i] for i = 0,1,... # Validates mirror similarity 
#   Stop when the two pointers meet or cross. # Halts early upon verifying entire structure matches
#
# System calls used (via glibc wrappers): # Exposes the OS functions
#   open, lseek, read, close, puts # Five different UNIX standard I/O functions
#
# Stack frame layout (sp after prologue): # Explain exact memory layout required on stack
#   sp+ 0 : 1-byte buffer for left  char # Reserved a single byte for Left pointer's reading
#   sp+ 1 : 1-byte buffer for right char # Reserved a single byte for Right pointer's reading
#   sp+ 2 : (6 bytes padding for alignment) # Used up remaining space in first block
#   sp+ 8 : saved s3 # Backup space for standard s-registers
#   sp+16 : saved s2 # Backup space for standard s-registers
#   sp+24 : saved s1 # Backup space for standard s-registers
#   sp+32 : saved s0 # Backup space for standard s-registers
#   sp+40 : saved ra # Backup space for return address
#   (frame size = 48, 16-byte aligned) # Frame summary

.section .rodata # Begin Read-Only memory section defined here
path_str:   .string "input.txt" # Define string literal for input.txt target filename
yes_str:    .string "Yes" # Define string literal for Yes output
no_str:     .string "No" # Define string literal for No output
err_open:   .ascii "Error: open failed\n" # Error message for open failure (19 bytes)
err_lseek:  .ascii "Error: lseek failed\n" # Error message for lseek failure (20 bytes)
err_read:   .ascii "Error: read failed\n" # Error message for read failure (19 bytes)
err_close:  .ascii "Error: close failed\n" # Error message for close failure (20 bytes)

.text # Identifies this section as executable code segment
.globl main # Export main function so OS can hit it to start

main: # Main logic execution point section
    # ── prologue ───────────────────────────────────────────────── # Starting standard function wrapper setup block
    addi sp, sp, -48         # Make 48 bytes of room on stack layout
    sd   ra, 40(sp)          # saved ra # Back up old return address into stack slot safely
    sd   s0, 32(sp)          # s0 = fd_left # Back up old s0 register config into stack memory location
    sd   s1, 24(sp)          # s1 = fd_right # Back up old s1 register config into stack memory location
    sd   s2, 16(sp)          # s2 = left  index (advances 0 → …) # Back up old s2 register config
    sd   s3,  8(sp)          # s3 = right index (retreats … → 0) # Back up old s3 register config safely
    # sp+0, sp+1 : one-byte read buffers for left and right char # Reminder of byte storage mapped slots available

    # ── open file twice ────────────────────────────────────────── # Process of getting file accesses
    la   a0, path_str        # Place address of input file name in argument register 1
    li   a1, 0               # O_RDONLY # Sets read-only mode flag for opening file process
    li   a2, 0               # mode (ignored for O_RDONLY) # Leave third argument as zero blank
    call open                # Execute 'open' system function inside standard C library wrapper
    bltz a0, .fail_open_left # Check if open failed (return < 0), branch to failure logic
    mv   s0, a0              # s0 = fd_left # Extract our new OS file descriptor 1 to safe s0 register

    la   a0, path_str        # Place address of input file name in argument register 1 once again
    li   a1, 0               # O_RDONLY # Sets read-only mode for duplicate file open
    li   a2, 0               # Setup 3rd zero argument again for safety standard
    call open                # Execute 'open' system function to fetch second separate access token
    bltz a0, .fail_open_right# Check if open failed (return < 0), branch to failure logic
    mv   s1, a0              # s1 = fd_right # Extract OS file descriptor 2 into s1 tracking register

    # ── get file length: lseek(fd_right, 0, SEEK_END) ─────────── # Command section finding total filesize
    mv   a0, s1              # Put file descriptor 2 into primary work argument 1
    li   a1, 0               # Give it zero physical shifting offset metric 
    li   a2, 2               # SEEK_END # Provide command parameter defining instruction "Jump to end of file"
    call lseek               # Execute 'lseek' system function to perform length calculation
    bltz a0, .fail_lseek     # Check if lseek failed, branch to failure handling logic
    # a0 = file size ( >= 0 ) # lseek implicitly dumps length metric into a0 upon returning from END_SEEK pattern

    # ── handle empty file → palindrome ────────────────────────── # Code chunk checking extreme size scenarios
    beqz a0, .yes            # If file size is identically zero, an empty file is technically perfectly mirrored

    # ── check and strip trailing newline ───────────────────────── # Cleaning unwanted formatting characters section
    # Read the last byte; if it's '\n', exclude it from the check. # Plain text comment explaining goal of chunk
    mv   s3, a0              # s3 = file_size (will become right boundary) # Duplicate length into our right counter variable
    addi s3, s3, -1          # s3 = index of last byte # Offset true size number to valid memory index via subtraction

    # seek fd_right to the last byte and peek at it # Plain text overview of step
    mv   a0, s1              # Put right reader descriptor object into arg 1
    mv   a1, s3              # Provide index of last character as argument 2 target jumping point
    li   a2, 0               # SEEK_SET # Instruct function to measure index offset starting straight from initial early bit
    call lseek               # Order 'lseek' standard wrapper to physically reposition reader cursor there
    bltz a0, .fail_lseek     # Check if lseek failed, branch to failure handling logic

    mv   a0, s1              # Put right file reader in argument 1
    addi a1, sp, 1           # buffer at sp+1 # Get string target pointing to local temporary layout space
    li   a2, 1               # Provide instructions that we intend to snatch only one single byte payload
    call read                # Grab one byte and actually write it to temp pointer layout
    blez a0, .fail_read      # Check if read failed or returned 0, branch to failure handling logic

    lb   t0, 1(sp)           # Read local stack layout offset memory byte into our standard logic test register
    li   t1, '\n'            # Load typical unix newline into second test register comparison
    bne  t0, t1, .check_init # Check if char matches newline: if NOT MATCH skip fixing the boundary logic entirely
    addi s3, s3, -1          # exclude the newline: right boundary = s3-1 # Move the actual checking boundary backward off the newline text payload
    # If file was only "\n", s3 is now -1; handled below. # Note explaining extreme case condition logic below

.check_init: # Core initialization phase label marker
    li   s2, 0               # left  index = 0 # Establish left tracking pointer at zero offset position explicitly

    # ── rewind fd_left to position 0 ───────────────────────────── # Reminder chunk
    # (fd_left was opened fresh so position is 0 – no seek needed) # Statement of OS truth avoiding unnecessary calculations

    # ── two-pointer loop ───────────────────────────────────────── # Header label segment logical loop
.loop: # Logical cycle starting block label
    # if left >= right, all compared chars matched → palindrome # Math comment explaining collision scenario over index
    bge  s2, s3, .yes        # Trigger collision detection successfully ending loop via jump-yes instruction

    # read one byte from fd_left (advances automatically) # Left OS call logic execution header
    mv   a0, s0              # Setup descriptor parameter in a0 for read function target
    mv   a1, sp              # buffer at sp+0 # Provide 0 stack offset as writeable pointer
    li   a2, 1               # Define exactly 1 payload length load request order
    call read                # Read left file descriptor into pointer target byte space
    blez a0, .fail_read      # Check if read failed, error out

    # seek fd_right to current right index and read one byte # Setting up and fetching backwards chunk via seeking right descriptor
    mv   a0, s1              # Provide descriptor for 'lseek' to work target on
    mv   a1, s3              # Specify backwards moving cursor goal tracking mark
    li   a2, 0               # SEEK_SET # Absolute measure request instruction constraint
    call lseek               # Tell 'lseek' to rigorously re-point to target index
    bltz a0, .fail_lseek     # Check if lseek failed, error out

    mv   a0, s1              # Request to standard read on second file descriptor
    addi a1, sp, 1           # buffer at sp+1 # Provide 1 stack offset location marker
    li   a2, 1               # Single query payload byte
    call read                # Extract exactly the one target byte at new target index location
    blez a0, .fail_read      # Check if read failed, error out

    # compare the two bytes # Simple evaluation logical block setup
    lb   t0,  0(sp)          # left  char # Fetch left stack buffer loaded element
    lb   t1,  1(sp)          # right char # Fetch right stack buffer loaded element
    bne  t0, t1, .no         # mismatch → not a palindrome # Validate the math completely, branching NO if chars failed strict equality test

    addi s2, s2, 1           # left++ # Advance left counter 1 slot position
    addi s3, s3, -1          # right-- # De-advance right counter 1 slot position
    j    .loop               # Re-loop backwards execution sequence

.yes: # Label block describing palindrome confirmation logical state
    la   a0, yes_str         # Stage confirmation string pointer text in argument structure layout
    call puts                # Trigger standard C-based newline string dump IO wrapper
    j    .done               # Final jump toward memory closing releases

.no: # Label defining failure states branching trigger layout block
    la   a0, no_str          # Provide negative response string base location target
    call puts                # Deliver negative payload via terminal std outputs IO

.done: # Target jumping pad for final script destruction block memory commands
    mv   a0, s0              # Push specific left file descriptor to shutdown cycle pipe
    call close               # Destroy descriptor 1 and fully release its OS hold
    bltz a0, .fail_close     # Check if close failed

    mv   a0, s1              # Provide second object wrapper physical reference target 
    call close               # Destroy descriptor 2 and permanently its internal tracking locks 
    bltz a0, .fail_close     # Check if close failed

    li   a0, 0               # exit status 0 # Enforce basic unix return codes integer successfully
    j    .epilogue           # Jump to common epilogue block to restore registers

# ── Error Handling Blocks ───────────────────────────────────── # Section handling failures cleanly
.fail_open_left: # Error case for first open
    la   a1, err_open        # Load address of open error string
    li   a2, 19              # Load length of open error string
    j    .print_err_and_exit # Jump to print and exit routine

.fail_open_right: # Error case for second open
    mv   a0, s0              # Retrieve first file descriptor that was successfully opened
    call close               # Close the first file descriptor safely
    la   a1, err_open        # Load address of open error string
    li   a2, 19              # Load length of open error string
    j    .print_err_and_exit # Jump to print and exit routine

.fail_read: # Error case for read failure
    la   a1, err_read        # Load address of read error string
    li   a2, 19              # Load length of read error string
    j    .close_both_and_fail# Jump to safely close descriptors and fail

.fail_lseek: # Error case for lseek failure
    la   a1, err_lseek       # Load address of lseek error string
    li   a2, 20              # Load length of lseek error string
    j    .close_both_and_fail# Jump to safely close descriptors and fail

.fail_close: # Error case for close failure
    la   a1, err_close       # Load address of close error string
    li   a2, 20              # Load length of close error string
    j    .print_err_and_exit # Already trying to close, just fail out with code 1

.close_both_and_fail: # Common failure block for safety
    mv   s2, a1              # Temporarily backup error string pointer pointer inside preserved register
    mv   s3, a2              # Temporarily backup error string length metric inside preserved register
    mv   a0, s0              # Retrieve first file descriptor
    call close               # Attempt closure cleanup
    mv   a0, s1              # Retrieve second file descriptor
    call close               # Attempt closure cleanup
    mv   a1, s2              # Restore error string pointer for writer
    mv   a2, s3              # Restore error string length for writer
    j    .print_err_and_exit # Proceed to exit sequence

.print_err_and_exit: # Final step of failure route
    li   a0, 2               # Set argument 1 to '2' (Standard Error output stream fd)
    call write               # Call standard OS string writer function on stderr
    li   a0, 1               # Set standard program return value variable to 1 signifying explicit error
    # Fallthrough straight into epilogue cleanup code

.epilogue: # Common Cleanup Target
    # ── epilogue ───────────────────────────────────────────────── # Core script unrolling wrapper block marking layout exit
    ld   ra, 40(sp)          # Pull back ra original config structural layout
    ld   s0, 32(sp)          # Undo initial backup config push state entirely
    ld   s1, 24(sp)          # Set s1 back into system starting block state safely
    ld   s2, 16(sp)          # Deactivate custom changes inside trackable object s2 
    ld   s3,  8(sp)          # Pull away latest active s3 testing variables inside frame
    addi sp, sp, 48          # Release out our fully allocated 48 byte memory chunks
    ret                      # Bounce back program origin structure completely successfully 
