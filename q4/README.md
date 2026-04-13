# Question 4: Dynamic Calculator

## Implementation Notes

This question requires calculating inputs iteratively, utilizing custom external libraries loaded during execution. Given massive shared objects (1.5GB) and restricted available memory (2GB cap), we must carefully manage spatial bounds.

### Logic Flow

1. Continuously process `stdin` formatting `"%5s %d %d"`. Utilizing `%5s` actively prevents bounds overflow to the `char op[8]` stack buffer, avoiding security issues with arbitrary external data.
2. Form the name via `snprintf` explicitly to match `"./lib<op>.so"`.
3. Load the library into address space using `dlopen`.
   - `dlerror()` ensures informative failures should the file miss or crash on linking.
4. Extract the exported operation symbol utilizing `dlsym`.
   - Clear existing contexts in `dlerror()` actively to catch real resolution breaks explicitly.
5. Invoke function mapped pointer.
6. Crucial phase: **Free object immediately with `dlclose`**.

If we retain external file mapping handles inside the `while` scope instead of terminating bounds inline, subsequent load sizes rapidly exhaust the explicit total 2GB runtime system allocations leading to `SIGKILL` limits. Closing them securely satisfies `O(1)` process retention.
