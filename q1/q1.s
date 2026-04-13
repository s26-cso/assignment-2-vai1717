# q1.s — Binary Search Tree in RISC-V 64-bit assembly (RV64, LP64 ABI)
#
# struct Node {
#     int val;            // offset 0  (4 bytes)
#     // 4 bytes padding for alignment
#     struct Node* left;  // offset 8  (8 bytes)
#     struct Node* right; // offset 16 (8 bytes)
# };
# sizeof(struct Node) = 24
#
# Calling convention (LP64):
#   Arguments:  a0-a7
#   Return:     a0
#   Callee-saved: ra, sp, s0-s11
#   Caller-saved: t0-t6, a0-a7

.text

.globl make_node
.globl insert
.globl get
.globl getAtMost

# ============================================================
# struct Node* make_node(int val)
#   a0 = val (int, sign-extended to 64 bits)
#   Returns: pointer to newly allocated Node in a0
# ============================================================
make_node:
    addi sp, sp, -16
    sd   ra, 8(sp)
    sd   s0, 0(sp)

    mv   s0, a0            # s0 = val (preserve across malloc call)

    li   a0, 24            # sizeof(Node) = 24
    call malloc             # a0 = pointer to new node

    sw   s0, 0(a0)         # node->val = val
    sd   zero, 8(a0)       # node->left = NULL
    sd   zero, 16(a0)      # node->right = NULL

    ld   ra, 8(sp)
    ld   s0, 0(sp)
    addi sp, sp, 16
    ret

# ============================================================
# struct Node* insert(struct Node* root, int val)
#   a0 = root, a1 = val
#   Returns: root in a0
#
# Equivalent C:
#   if (root == NULL) return make_node(val);
#   if (val < root->val)
#       root->left = insert(root->left, val);
#   else if (val > root->val)
#       root->right = insert(root->right, val);
#   return root;
# ============================================================
insert:
    beqz a0, .insert_null          # if root == NULL, create new node

    addi sp, sp, -32
    sd   ra, 24(sp)
    sd   s0, 16(sp)
    sd   s1, 8(sp)

    mv   s0, a0                    # s0 = root
    mv   s1, a1                    # s1 = val

    lw   t0, 0(s0)                 # t0 = root->val (sign-extended)
    blt  s1, t0, .insert_left     # if val < root->val, go left
    bgt  s1, t0, .insert_right    # if val > root->val, go right
    j    .insert_done              # val == root->val, no duplicate insert

.insert_left:
    ld   a0, 8(s0)                 # a0 = root->left
    mv   a1, s1                    # a1 = val
    call insert
    sd   a0, 8(s0)                 # root->left = insert(root->left, val)
    j    .insert_done

.insert_right:
    ld   a0, 16(s0)                # a0 = root->right
    mv   a1, s1                    # a1 = val
    call insert
    sd   a0, 16(s0)                # root->right = insert(root->right, val)

.insert_done:
    mv   a0, s0                    # return root
    ld   ra, 24(sp)
    ld   s0, 16(sp)
    ld   s1, 8(sp)
    addi sp, sp, 32
    ret

.insert_null:
    mv   a0, a1                    # a0 = val
    tail make_node                 # return make_node(val)  [tail call, no stack needed]

# ============================================================
# struct Node* get(struct Node* root, int val)
#   a0 = root, a1 = val
#   Returns: pointer to node with value val, or NULL
#
# Iterative implementation (BST search is naturally tail-recursive):
#   while (root != NULL) {
#       if (val == root->val) return root;
#       if (val < root->val) root = root->left;
#       else root = root->right;
#   }
#   return NULL;
# ============================================================
get:
.get_loop:
    beqz a0, .get_not_found        # if root == NULL, return NULL
    lw   t0, 0(a0)                 # t0 = root->val
    beq  a1, t0, .get_found        # if val == root->val, found it
    blt  a1, t0, .get_go_left      # if val < root->val, go left
    ld   a0, 16(a0)                # root = root->right
    j    .get_loop

.get_go_left:
    ld   a0, 8(a0)                 # root = root->left
    j    .get_loop

.get_found:
    ret                            # a0 already = root (the found node)

.get_not_found:
    li   a0, 0                     # return NULL
    ret

# ============================================================
# int getAtMost(int val, struct Node* root)
#   a0 = val, a1 = root       *** NOTE: argument order differs ***
#   Returns: greatest value in tree that is <= val, or -1
#
# Equivalent C:
#   if (root == NULL) return -1;
#   if (root->val == val) return val;
#   if (root->val > val) return getAtMost(val, root->left);
#   // root->val < val: root is a candidate
#   int result = getAtMost(val, root->right);
#   if (result == -1) return root->val;
#   return result;
# ============================================================
getAtMost:
    beqz a1, .gam_null             # if root == NULL, return -1

    lw   t0, 0(a1)                 # t0 = root->val (sign-extended)
    beq  t0, a0, .gam_exact        # root->val == val: return val
    bgt  t0, a0, .gam_go_left      # root->val > val: go left (tail call)

    # root->val < val: root is a candidate, try right subtree
    addi sp, sp, -16
    sd   ra, 8(sp)
    sd   s0, 0(sp)

    mv   s0, t0                    # s0 = candidate value (root->val)
    ld   a1, 16(a1)                # a1 = root->right
    # a0 = val (unchanged)
    call getAtMost

    li   t0, -1
    bne  a0, t0, .gam_return       # if result != -1, return it (already in a0)
    mv   a0, s0                    # else return candidate (root->val)

.gam_return:
    ld   ra, 8(sp)
    ld   s0, 0(sp)
    addi sp, sp, 16
    ret

.gam_go_left:
    ld   a1, 8(a1)                 # root = root->left
    j    getAtMost                 # tail call (no stack frame needed)

.gam_exact:
    # a0 already contains val (which equals root->val)
    ret

.gam_null:
    li   a0, -1                    # return -1
    ret
