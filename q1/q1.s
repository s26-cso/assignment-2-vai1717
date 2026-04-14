
# LP64 calling convention: # Explaining standard RISC-V conventions used
#   Arguments:            a0–a7 # Argument registers
#   Return value:         a0 # Return value register
#   Caller-saved (temp):  t0–t6, a0–a7 # Registers that don't need to be preserved
#   Callee-saved:         ra, sp, s0–s11 # Registers that must be saved and restored
#   Stack alignment:      16 bytes at every call site # Stack pointer alignment rule

.text # Identifies this section as executable code

.globl make_node # Export function symbol out of file scope
.globl insert # Export function symbol out of file scope
.globl get # Export function symbol out of file scope
.globl getAtMost # Export function symbol out of file scope

# ───────────────────────────────────────────────────────────────── # Section divider
# struct Node* make_node(int val) # Function signature in C format
#
#   a0 = val (int – sign-extended from 32 to 64 bits by convention) # Input argument explanation
#   Returns new Node* in a0. # Output explanation
#
#   Does: # High-level summary of what function does
#     node = malloc(24) # Ask OS for 24 bytes of memory
#     node->val   = val    (sw – 32-bit store) # Save value into node structure
#     node->left  = NULL   (sd zero) # Initialize left pointer to zero/null
#     node->right = NULL   (sd zero) # Initialize right pointer to zero/null
#     return node # Return the pointer to new node
# ───────────────────────────────────────────────────────────────── # Section divider
make_node: # Function entry point
    addi sp, sp, -16       # Allocate 16 bytes on stack (16-byte aligned)
    sd   ra,  8(sp)        # Save return address to the stack frame
    sd   s0,  0(sp)        # Save register s0 to the stack frame

    mv   s0, a0            # s0 = val (caller-saved across malloc) # Backup argument 'val' so malloc doesn't overwrite it

    li   a0, 24            # sizeof(struct Node) # Put 24 in a0 as argument for malloc sizes
    call malloc            # a0 = new Node* # Call memory allocator

    sw   s0,  0(a0)        # node->val   = val  (32-bit int) # Save the 'val' integer into new struct's val field
    sd   zero, 8(a0)       # node->left  = NULL # Put a zero (NULL pointer) in the left child field
    sd   zero,16(a0)       # node->right = NULL # Put a zero (NULL pointer) in the right child field

    ld   ra,  8(sp)        # Load original return address from stack frame
    ld   s0,  0(sp)        # Load original s0 from stack frame
    addi sp, sp, 16        # Deallocate the 16 bytes of stack frame
    ret                    # Return the allocated node pointer now in a0


# struct Node* insert(struct Node* root, int val) # Function signature in C format
#
#   a0 = root (Node* – may be NULL) # First argument is root node pointer
#   a1 = val  (int) # Second argument is the integer to insert
#   Returns (possibly new) root in a0. # Explanation of return value
#
#   Algorithm (standard recursive BST insert, no duplicate values): # How algorithm works
#     if root == NULL  → return make_node(val) # Base case: empty gap, inject new node
#     if val < root->val → root->left  = insert(root->left,  val) # Recursive case left: Value is smaller, go left
#     if val > root->val → root->right = insert(root->right, val) # Recursive case right: Value is bigger, go right
#     else               → (duplicate: do nothing) # Base case: Exact duplicate found, ignore
#     return root # Return the modified or original root

insert: # Function entry point
    beqz a0, .insert_null      # NULL root → tail-call make_node(val) # If tree doesn't exist, create it

    addi sp, sp, -32       # Allocate 32 bytes on stack
    sd   ra, 24(sp)        # Save return address
    sd   s0, 16(sp)        # Save s0 register on stack
    sd   s1,  8(sp)        # Save s1 register on stack

    mv   s0, a0                # s0 = root (preserved across recursive call) # Backup the current node pointer
    mv   s1, a1                # s1 = val # Backup the value being inserted

    lw   t0, 0(s0)             # t0 = root->val  (32-bit, sign-extended) # Load current node's integer
    blt  s1, t0, .ins_left     # val < root->val → recurse left # If incoming value < node value, go left
    bgt  s1, t0, .ins_right    # val > root->val → recurse right # If incoming value > node value, go right
    j    .ins_done             # val == root->val → duplicate, skip # Else they are equal, jump to end

.ins_left: # Label for inserting to the left
    ld   a0, 8(s0)             # a0 = root->left # Load the left child pointer into argument register
    mv   a1, s1                # Ensure value is still in second argument register
    call insert                # Recursively call insert on left child
    sd   a0, 8(s0)             # root->left = returned subtree root # Update left child with result of recursive call
    j    .ins_done             # Jump over the right side logic

.ins_right: # Label for inserting to the right
    ld   a0, 16(s0)            # a0 = root->right # Load the right child pointer into argument register
    mv   a1, s1                # Ensure value is still in second argument register
    call insert                # Recursively call insert on right child
    sd   a0, 16(s0)            # root->right = returned subtree root # Update right child with result of recursive call

.ins_done: # Label for end of insert logic
    mv   a0, s0                # return original root (unchanged) # Put current node pointer back into return register
    ld   ra, 24(sp)            # Restore return address from stack
    ld   s0, 16(sp)            # Restore s0 register from stack
    ld   s1,  8(sp)            # Restore s1 register from stack
    addi sp, sp, 32            # Deallocate stack frame
    ret                        # Return to parent

.insert_null: # Label called when we want to just make a node
    # root is NULL: create a new leaf node and return it. # Comment explaining case
    # val is still in a1; move it to a0 as argument for make_node. # Explanation of argument shifting
    mv   a0, a1                # Copy value to first argument register
    tail make_node             # tail call – no extra stack frame needed # Go to make_node and have it return to our parent


# struct Node* get(struct Node* root, int val) # Function signature in C format
#
#   a0 = root, a1 = val # Argument mapping
#   Returns Node* if found, NULL otherwise. # Meaning of return register
#
#   Implemented iteratively (no recursion, no stack allocation): # High-level design note
#     while (root != NULL): # Main loop condition
#         if val == root->val  → return root # Matches
#         if val <  root->val  → root = root->left # Must be to the left
#         else                 → root = root->right # Must be to the right
#     return NULL # Did not find

get: # Function entry point
.get_loop: # Label for loop start
    beqz a0, .get_null         # root == NULL → not found # If pointer is null, exit loop with failure
    lw   t0, 0(a0)             # t0 = root->val # Fetch current node value into logic register
    beq  a1, t0, .get_done     # found # If value matches the search, jump to successfully returning
    blt  a1, t0, .get_left     # val < root->val → go left # If search is smaller, branch to left logic

    ld   a0, 16(a0)            # root = root->right # Assign right child pointer as new root
    j    .get_loop             # Repeat loop

.get_left: # Label for moving left
    ld   a0, 8(a0)             # root = root->left # Assign left child pointer as new root
    j    .get_loop             # Repeat loop

.get_done: # Label for finding the target
    ret                        # a0 already = found node # Return immediately (a0 is valid)

.get_null: # Label for failing to find target
    li   a0, 0                 # return NULL # Put logical False / NULL into return register
    ret                        # Return that failure


# int getAtMost(int val, struct Node* root) # Function signature in C format
#
#   a0 = val  (int – the upper bound) # Explanation of argument 1
#   a1 = root (Node*) # Explanation of argument 2
#   Returns greatest value v in the tree such that v <= val, # Output description
#   or -1 if no such value exists. # Backup condition
#
#   NOTE: argument order is (val, root) not (root, val)! # Important warning for the user
#
#   Algorithm: # How the math works
#     if root == NULL          → return -1 # Missing leaf check
#     if root->val == val      → return val           (exact match) # Got exact value
#     if root->val >  val      → return getAtMost(val, root->left)   [tail] # Go checking smaller numbers leftward
#     // root->val < val: root->val is a candidate # Found an "at most" value, save it
#     result = getAtMost(val, root->right) # Recursively ensure right side doesn't have a *better* answer
#     return (result == -1) ? root->val : result # Decide between left answer and our local answer
#
#   Important: when we go right, we save root->val as the fallback. # Design comment for recursion
#   The "go left" path is a pure tail call (no candidate yet – or # Design comment for memory saving
#   a better candidate lives to the left, which is impossible since # Additional description of the edgecase logic
#   root->val would already exceed val). # More recursive logic tracing
# ───────────────────────────────────────────────────────────────── # Section divider
getAtMost: # Function entry point
    beqz a1, .gam_null         # root == NULL → -1 # Empty node check

    lw   t0, 0(a1)             # t0 = root->val (sign-extended to 64) # Fetch value from node
    beq  t0, a0, .gam_exact    # root->val == val → return val # Found exactly perfectly matching number
    bgt  t0, a0, .gam_left     # root->val >  val → tail-recurse left # Number is too big, go to smaller values leftwards

    # root->val < val: this node is a candidate; try right subtree # Comment marking case when number is smaller
    addi sp, sp, -16       # Allocate stack space layout
    sd   ra, 8(sp)         # Store return address layout
    sd   s0, 0(sp)         # Store register that will keep local answer

    mv   s0, t0                # s0 = candidate = root->val # Backup our own potentially best answer
    ld   a1, 16(a1)            # a1 = root->right # Setup right branch node as next recursion's root
    # a0 = val (unchanged) # Note that search constraint stays unchanged
    call getAtMost             # result in a0 # Recursive call into right half

    li   t1, -1                # Constant load -1 representing failure 
    bne  a0, t1, .gam_ret     # right subtree had a closer value → use it # If recursion did NOT fail, keep its answer instead of ours

    mv   a0, s0                # right subtree had nothing → use candidate # Since recursion failed, output our answer as final best answer

.gam_ret: # Label signifying return path
    ld   ra, 8(sp)         # Load return address
    ld   s0, 0(sp)         # Load local register
    addi sp, sp, 16        # Free stack space
    ret                    # Return value in a0

.gam_left: # Label handling left recursion logic
    # root->val > val: the answer (if any) is in the left subtree. # Explanation 
    # Pure tail call – reuse current ra/frame. # Explanation for doing direct jump instead of call
    ld   a1, 8(a1)             # a1 = root->left # Make argument 1 point at left child
    j    getAtMost             # Recursively process left half

.gam_exact: # Exact match handler
    # a0 == val already; the node stores exactly val. # Note that perfect situation saves operations
    ret                        # Simply exit

.gam_null: # Missing result handler
    li   a0, -1                # Set return to failure condition
    ret                        # Simply exit
