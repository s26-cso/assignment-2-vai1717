/*
 * q4.c — Dynamic-library calculator for ISS-6701
 *
 * Protocol:
 *   Input (loop on stdin):  <op> <num1> <num2>
 *   Output:                 result of op(num1, num2)
 *
 * For each operation <op>:
 *   - Load ./lib<op>.so using dlopen (RTLD_LAZY)
 *   - Resolve symbol <op> of type  int (*)(int, int)  via dlsym
 *   - Call it, print the integer result, then dlclose immediately
 *
 * Memory safety:
 *   Each library can be up to 1.5 GB; the 2 GB cap means we MUST
 *   dlclose before loading the next one.  We never hold more than
 *   one library open at a time.
 *
 * Compile (autograder):
 *   riscv64-linux-gnu-gcc -o a.out q4.c -ldl
 */

#include <stdio.h>
#include <dlfcn.h>

int main(void)
{
    char op[8];     /* op ≤ 5 chars + NUL; 8 bytes for safety */
    int  num1, num2;

    /* Read one line at a time; stop at EOF or malformed input */
    while (scanf("%5s %d %d", op, &num1, &num2) == 3) {

        /* ---- Build path ---- */
        char libpath[20];   /* "./lib" + 5 + ".so" + NUL = 15 max */
        snprintf(libpath, sizeof libpath, "./lib%s.so", op);

        /* ---- Load ---- */
        void *handle = dlopen(libpath, RTLD_LAZY);
        if (!handle) {
            /* Library not found — skip this line, keep going */
            fprintf(stderr, "dlopen: %s\n", dlerror());
            continue;
        }

        /* ---- Resolve ---- */
        dlerror();  /* clear stale error */
        int (*func)(int, int) = (int (*)(int, int))dlsym(handle, op);
        const char *err = dlerror();
        if (err) {
            fprintf(stderr, "dlsym: %s\n", err);
            dlclose(handle);
            continue;
        }

        /* ---- Execute & print ---- */
        printf("%d\n", func(num1, num2));

        /* ---- Unload immediately (memory constraint) ---- */
        dlclose(handle);
    }

    return 0;
}
