/*
 * q4.c — Dynamic-library calculator for ISS-6701 // This file is a dynamic-library calculator program
 *
 * Protocol: // The communication protocol description
 *   Input (loop on stdin):  <op> <num1> <num2> // Expected user input format
 *   Output:                 result of op(num1, num2) // Expected output printed to terminal
 *
 * For each operation <op>: // Instructions for handling each input operation
 *   - Load ./lib<op>.so using dlopen (RTLD_LAZY) // Loads the shared library file for the operation
 *   - Resolve symbol <op> of type  int (*)(int, int)  via dlsym // Finds the function within the library
 *   - Call it, print the integer result, then dlclose immediately // Executes the function and closes library
 *
 * Memory safety: // Rules regarding memory limits
 *   Each library can be up to 1.5 GB; the 2 GB cap means we MUST // Warns about maximum library size
 *   dlclose before loading the next one.  We never hold more than // Warns we must close to avoid crashes
 *   one library open at a time. // Enforces strict memory usage rule
 *
 * Compile (autograder): // Command used by the grading software to compile
 *   riscv64-linux-gnu-gcc -o a.out q4.c -ldl // GCC compile command that links 'dl' library for dynamic loading
 */

#include <stdio.h> // Includes standard I/O library for printing and scanning
#include <dlfcn.h> // Includes dynamic linking library for opening and using shared objects

int main(void) // The main starting point of the program
{ // Start of the main function block
    char op[8];     /* op <= 5 chars + NUL; 8 bytes for safety */ // Creates an array to hold the operation string like 'add' or 'sub'
    int  num1, num2; // Creates integer variables to hold the two input numbers

    /* Read one line at a time; stop at EOF or malformed input */ // Comment explaining the loop condition
    while (scanf("%5s %d %d", op, &num1, &num2) == 3) { // Loops as long as it successfully reads 1 string and 2 integers

        /* ---- Build path ---- */ // Comment indicating the next section builds the file path
        char libpath[20];   /* "./lib" + 5 + ".so" + NUL = 15 max */ // Array to store the file path for the library
        snprintf(libpath, sizeof libpath, "./lib%s.so", op); // Creates the string path, e.g. "./libadd.so", into libpath

        /* ---- Load ---- */ // Comment indicating the next section loads the library
        void *handle = dlopen(libpath, RTLD_LAZY); // Opens the dynamic library file lazily (only resolves symbols when called)
        if (!handle) { // Checks if the library failed to open
            /* Library not found — skip this line, keep going */ // Comment explaining the failure behavior
            fprintf(stderr, "dlopen: %s\n", dlerror()); // Prints the loading error message to the standard error output
            continue; // Skips the rest of the loop and waits for the next user input
        } // End of the if block

        /* ---- Resolve ---- */ // Comment indicating the next section finds the function
        dlerror();  /* clear stale error */ // Clears any old error messages so we only see new ones
        int (*func)(int, int) = (int (*)(int, int))dlsym(handle, op); // Looks up the operation name (like 'add') inside the library and gets its memory address
        const char *err = dlerror(); // Gets any error that might have occurred during the lookup
        if (err) { // Checks if an error occurred while searching for the function
            fprintf(stderr, "dlsym: %s\n", err); // Prints the lookup error to the standard error output
            dlclose(handle); // Closes the opened library handle to avoid memory leaks
            continue; // Skips the rest of the loop and waits for the next user input
        } // End of the if block

        /* ---- Execute & print ---- */ // Comment indicating execution phase
        printf("%d\n", func(num1, num2)); // Calls the loaded function with num1 and num2, then prints the integer result

        /* ---- Unload immediately (memory constraint) ---- */ // Comment indicating cleanup phase
        dlclose(handle); // Closes the library to free up memory before the next loop starts
    } // End of the while loop

    return 0; // Returns 0 to tell the OS the program finished successfully
} // End of the main function block
