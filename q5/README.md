# Question 5: Arbitrary Palindrome Validator

## Problem Constraints

The problem specifies checking if a completely arbitrary large file size sequence behaves as a palindrome in $O(n)$ time and strictly $O(1)$ constant space algorithms. Therefore, loading strings iteratively into main stack frames or dynamic tracking pointers utilizing `malloc` is entirely forbidden.

## Assembly Strategy

Instead of retrieving memory blocks directly, the operation offloads parsing logic entirely heavily onto System Kernels utilizing dual File Descriptor objects processing raw bytes:
1. `fd_left` reads file sequences progressing continuously Left $\to$ Right recursively checking byte by byte tracking the front.
2. `fd_right` seeks backward specifically resolving indexing dynamically. Before parsing, we index `lseek` to strictly grab from position limits counting backwards Right $\to$ Left.
3. Every pair is compared. If sequences misalign immediately print `No`.
4. Process iterates effectively ending execution matching pointers crossing thresholds verifying strings.

Since each syscall dynamically handles read bytes into overlapping singular `sp` index stacks, Space Complexity is strictly capped linearly $O(1)$.

## Newlines Edge Cases
Before resolving palindrome bytes, a specific newline trap condition is securely handled by evaluating trailing text formats skipping the newline byte matching cleanly.
