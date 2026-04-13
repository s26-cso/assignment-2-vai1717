# Question 2: Next Greater Element

## Overview

This question implements a solution to the "Next Greater Element" mathematical setup using a Monotonic Stack algorithmic pattern in $O(n)$ time and $O(n)$ space.

### Monotonic Stack Algorithm

A monotonic stack is simply a stack that maintains its elements sorted ascending or descending. For finding the "next greater element", we traverse the sequence from right-to-left:
1. Since we check from right to left, items in the stack are those elements that are to the right of the current element.
2. We iterate `i` from `n-1` to `0` and pop any element from the stack that is `<= arr[i]`. These elements can't be the "next greater element" for the current `arr[i]` or any element to its left.
3. If the stack is not empty after the pops, the top of the stack is the next greater element for `arr[i]`.
4. Push `i` to the stack for further processing.

### Assembly Details

We perform a dynamically determined allocation representing:
- `arr[n]`: Array size $n \times 4$ bytes (integer)
- `result[n]`: Result array size $n \times 4$ bytes
- `stk[n]`: Stack indices storing elements of size $n \times 4$ bytes

The total allocation from `malloc` is compactly kept track of. For space-separated formatting logic, we evaluate `beqz s5, .no_space` mapping our loop properly. The resulting implementation effectively skips the complexity of branching functions to optimize throughput.
