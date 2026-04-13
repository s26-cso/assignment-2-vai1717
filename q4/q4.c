/*
 * q4.c — Dynamic-library calculator
 *
 * Reads lines of the form:  <op> <num1> <num2>
 * Loads ./lib<op>.so at runtime, calls the function <op>(num1, num2),
 * prints the result, and immediately unloads the library to stay
 * under the 2 GB memory limit (each .so can be up to 1.5 GB).
 */

#include <stdio.h>
#include <dlfcn.h>

int main(void)
{
    char op[8];          /* op is at most 5 characters + NUL */
    int  num1, num2;

    /* Securely read up to 5 characters for the operation */
    while (scanf("%5s %d %d", op, &num1, &num2) == 3) {

        /* Build library path: ./lib<op>.so */
        char libpath[24];                       /* ./lib + 5 + .so + NUL = 14 max */
        snprintf(libpath, sizeof libpath, "./lib%s.so", op);

        /* Load the shared library */
        void *handle = dlopen(libpath, RTLD_LAZY);
        if (!handle) {
            fprintf(stderr, "Error loading library %s: %s\n", libpath, dlerror());
            return 1;
        }

        /* Look up the operation function */
        dlerror(); /* Clear any existing error */
        int (*func)(int, int) = (int (*)(int, int))dlsym(handle, op);
        
        const char *dlsym_err = dlerror();
        if (dlsym_err) {
            fprintf(stderr, "Error finding function %s: %s\n", op, dlsym_err);
            dlclose(handle);
            return 1;
        }

        /* Call and print */
        printf("%d\n", func(num1, num2));

        /* Unload immediately — critical for the 2 GB memory cap */
        dlclose(handle);
    }

    return 0;
}
