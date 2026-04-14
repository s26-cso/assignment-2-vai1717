[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/d5nOy1eX)

# Computer Systems Organization - Assignment 2

GitHub Repository: [assignment-2-vai1717](https://github.com/s26-cso/assignment-2-vai1717)

## Directory Structure

```text
assignment-2-vai1717/
├── q1/
│   └── q1.s          # Binary Search Tree implementation in RISC-V assembly
├── q2/
│   └── q2.s          # Next Greater Element algorithm in RISC-V assembly
├── q3/
│   ├── a/
│   │   ├── payload.txt      # Input to pass the reverse engineering challenge A
│   │   └── target_vai1717   # Target executable A
│   └── b/
│       ├── payload          # Input (buffer overflow) to pass challenge B
│       └── target_vai1717   # Target executable B
├── q4/
│   └── q4.c          # Calculator app with dynamic library loading in C
└── q5/
    └── q5.s          # Palindrome checker in RISC-V assembly
```

## How to Run the Code

You will need `qemu-riscv64` (the RISC-V user-space emulator) and the RISC-V GNU toolchain (`riscv64-linux-gnu-gcc`) installed on your system.

### Running Q1
Since `q1.s` contains only function definitions, you need to compile it with a custom `main.c` testing program (not included).
```bash
cd q1
riscv64-linux-gnu-gcc -static -o test_q1 q1.s main.c
qemu-riscv64 -L /usr/riscv64-linux-gnu ./test_q1
```

### Running Q2
This reads from command-line arguments.
```bash
cd q2
riscv64-linux-gnu-gcc -static -o q2_prog q2.s
qemu-riscv64 -L /usr/riscv64-linux-gnu ./q2_prog 85 96 70 80 102
```

### Running Q3 (Reverse Engineering Targets)
Use the provided payloads to bypass the password check:
```bash
# Part A
cd q3/a
qemu-riscv64 -L /usr/riscv64-linux-gnu ./target_vai1717 < payload.txt

# Part B
cd q3/b
qemu-riscv64 -L /usr/riscv64-linux-gnu ./target_vai1717 < payload
```

### Running Q4
This is dynamically linked, so use the `-ldl` flag and don't use `-static`.
```bash
cd q4
riscv64-linux-gnu-gcc -o q4_prog q4.c -ldl
qemu-riscv64 -L /usr/riscv64-linux-gnu ./q4_prog
# Then type commands like: add 10 20 (requires libadd.so in the same dir)
```

### Running Q5
This reads from an `input.txt` file in the same directory.
```bash
cd q5
riscv64-linux-gnu-gcc -static -o q5_prog q5.s
echo "racecar" > input.txt
qemu-riscv64 -L /usr/riscv64-linux-gnu ./q5_prog
```
