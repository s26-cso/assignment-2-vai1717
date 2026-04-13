# Question 1: Binary Search Tree in RISC-V Assembly

## Implementation Details

`q1.s` contains the implementation of a basic Binary Search Tree in RV64 LP64 assembly. The node structure follows the C `struct` layout:

```c
struct Node {
    int val;            // Offset 0, Size 4
    // Padding          // Offset 4, Size 4
    struct Node* left;  // Offset 8, Size 8
    struct Node* right; // Offset 16, Size 8
}; // Total Size: 24 bytes
```

### Functions

1. **`make_node(int val)`**
   - Takes: `a0` = `val`
   - Allocates 24 bytes of memory utilizing `malloc`.
   - Initializes `val` and sets `left`, `right` to NULL.

2. **`insert(struct Node* root, int val)`**
   - Takes: `a0` = `root`, `a1` = `val`
   - Uses recursion to traverse the BST to the correct placement position.
   - Saves necessary callee registers (`s0`, `s1`) to the stack to preserve state across recursive calls.
   - Ignores duplicate insertions.

3. **`get(struct Node* root, int val)`**
   - Takes: `a0` = `root`, `a1` = `val`
   - Iterative search through the BST (tail-call optimized manually) to minimize stack overhead.

4. **`getAtMost(int val, struct Node* root)`**
   - Takes: `a0` = `val`, `a1` = `root` (Note: signature explicitly specifies this argument order)
   - Performs a floor-like query to find the maximum element `<= val`.
   - Returns `-1` if no such element exists in the current subtree.

## Calling Convention (LP64)

We adhered strictly to the RISC-V LP64 ABI:
- Integer/Pointer operations utilize `lw`/`sw` and `ld`/`sd` respectively.
- Stack pointers (`sp`) are strictly 16-byte aligned.
- Argument passing utilizes `a0`-`a7`.
- Callee-saved operations handle `s0`-`s11` correctly before modifying them.
