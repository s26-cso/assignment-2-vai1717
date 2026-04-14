# q1.s — Binary Search Tree in RISC-V 64-bit assembly (RV64, LP64 ABI)
#
# struct Node {
#     int val;            // offset  0  (4 bytes)
#     // 4 bytes implicit padding for pointer alignment
#     struct Node* left;  // offset  8  (8 bytes)
#     struct Node* right; // offset 16  (8 bytes)
# };                      // sizeof = 24
#
# LP64 calling convention:
#   Arguments:            a0–a7
#   Return value:         a0
#   Caller-saved (temp):  t0–t6, a0–a7
#   Callee-saved:         ra, sp, s0–s11
#   Stack alignment:      16 bytes at every call site

.text

.globl make_node
.globl insert
.globl get
.globl getAtMost

# ─────────────────────────────────────────────────────────────────
# struct Node* make_node(int val)
#
#   a0 = val (int – sign-extended from 32 to 64 bits by convention)
#   Returns new Node* in a0.
#
#   Does:
#     node = malloc(24)
#     node->val   = val    (sw – 32-bit store)
#     node->left  = NULL   (sd zero)
#     node->right = NULL   (sd zero)
#     return node
# ─────────────────────────────────────────────────────────────────
make_node:
    addi sp, sp, -16
    sd   ra,  8(sp)
    sd   s0,  0(sp)

    mv   s0, a0            # s0 = val (caller-saved across malloc)

    li   a0, 24            # sizeof(struct Node)
    call malloc            # a0 = new Node*

    sw   s0,  0(a0)        # node->val   = val  (32-bit int)
    sd   zero, 8(a0)       # node->left  = NULL
    sd   zero,16(a0)       # node->right = NULL

    ld   ra,  8(sp)
    ld   s0,  0(sp)
    addi sp, sp, 16
    ret

# ─────────────────────────────────────────────────────────────────
# struct Node* insert(struct Node* root, int val)
#
#   a0 = root (Node* – may be NULL)
#   a1 = val  (int)
#   Returns (possibly new) root in a0.
#
#   Algorithm (standard recursive BST insert, no duplicate values):
#     if root == NULL  → return make_node(val)
#     if val < root->val → root->left  = insert(root->left,  val)
#     if val > root->val → root->right = insert(root->right, val)
#     else               → (duplicate: do nothing)
#     return root
# ─────────────────────────────────────────────────────────────────
insert:
    beqz a0, .insert_null      # NULL root → tail-call make_node(val)

    addi sp, sp, -32
    sd   ra, 24(sp)
    sd   s0, 16(sp)
    sd   s1,  8(sp)

    mv   s0, a0                # s0 = root (preserved across recursive call)
    mv   s1, a1                # s1 = val

    lw   t0, 0(s0)             # t0 = root->val  (32-bit, sign-extended)
    blt  s1, t0, .ins_left     # val < root->val → recurse left
    bgt  s1, t0, .ins_right    # val > root->val → recurse right
    j    .ins_done             # val == root->val → duplicate, skip

.ins_left:
    ld   a0, 8(s0)             # a0 = root->left
    mv   a1, s1
    call insert
    sd   a0, 8(s0)             # root->left = returned subtree root
    j    .ins_done

.ins_right:
    ld   a0, 16(s0)            # a0 = root->right
    mv   a1, s1
    call insert
    sd   a0, 16(s0)            # root->right = returned subtree root

.ins_done:
    mv   a0, s0                # return original root (unchanged)
    ld   ra, 24(sp)
    ld   s0, 16(sp)
    ld   s1,  8(sp)
    addi sp, sp, 32
    ret

.insert_null:
    # root is NULL: create a new leaf node and return it.
    # val is still in a1; move it to a0 as argument for make_node.
    mv   a0, a1
    tail make_node             # tail call – no extra stack frame needed

# ─────────────────────────────────────────────────────────────────
# struct Node* get(struct Node* root, int val)
#
#   a0 = root, a1 = val
#   Returns Node* if found, NULL otherwise.
#
#   Implemented iteratively (no recursion, no stack allocation):
#     while (root != NULL):
#         if val == root->val  → return root
#         if val <  root->val  → root = root->left
#         else                 → root = root->right
#     return NULL
# ─────────────────────────────────────────────────────────────────
get:
.get_loop:
    beqz a0, .get_null         # root == NULL → not found
    lw   t0, 0(a0)             # t0 = root->val
    beq  a1, t0, .get_done     # found
    blt  a1, t0, .get_left     # val < root->val → go left

    ld   a0, 16(a0)            # root = root->right
    j    .get_loop

.get_left:
    ld   a0, 8(a0)             # root = root->left
    j    .get_loop

.get_done:
    ret                        # a0 already = found node

.get_null:
    li   a0, 0                 # return NULL
    ret

# ─────────────────────────────────────────────────────────────────
# int getAtMost(int val, struct Node* root)
#
#   a0 = val  (int – the upper bound)
#   a1 = root (Node*)
#   Returns greatest value v in the tree such that v <= val,
#   or -1 if no such value exists.
#
#   NOTE: argument order is (val, root) not (root, val)!
#
#   Algorithm:
#     if root == NULL          → return -1
#     if root->val == val      → return val           (exact match)
#     if root->val >  val      → return getAtMost(val, root->left)   [tail]
#     // root->val < val: root->val is a candidate
#     result = getAtMost(val, root->right)
#     return (result == -1) ? root->val : result
#
#   Important: when we go right, we save root->val as the fallback.
#   The "go left" path is a pure tail call (no candidate yet – or
#   a better candidate lives to the left, which is impossible since
#   root->val would already exceed val).
# ─────────────────────────────────────────────────────────────────
getAtMost:
    beqz a1, .gam_null         # root == NULL → -1

    lw   t0, 0(a1)             # t0 = root->val (sign-extended to 64)
    beq  t0, a0, .gam_exact    # root->val == val → return val
    bgt  t0, a0, .gam_left     # root->val >  val → tail-recurse left

    # root->val < val: this node is a candidate; try right subtree
    addi sp, sp, -16
    sd   ra, 8(sp)
    sd   s0, 0(sp)

    mv   s0, t0                # s0 = candidate = root->val
    ld   a1, 16(a1)            # a1 = root->right
    # a0 = val (unchanged)
    call getAtMost             # result in a0

    li   t1, -1
    bne  a0, t1, .gam_ret     # right subtree had a closer value → use it

    mv   a0, s0                # right subtree had nothing → use candidate

.gam_ret:
    ld   ra, 8(sp)
    ld   s0, 0(sp)
    addi sp, sp, 16
    ret

.gam_left:
    # root->val > val: the answer (if any) is in the left subtree.
    # Pure tail call – reuse current ra/frame.
    ld   a1, 8(a1)             # a1 = root->left
    j    getAtMost

.gam_exact:
    # a0 == val already; the node stores exactly val.
    ret

.gam_null:
    li   a0, -1
    ret
