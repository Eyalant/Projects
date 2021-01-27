// This function checks if the machine we're on uses little or big
// endian. The maximum value we can assign to a single byte is 255, so
// in the function we define some random number which needs more than one
// byte for the test. We declare an unsigned short (at least 2 bytes) and assign
// a value of 500 to it. It's LS byte is 11110100 and it's MS byte is 00000001.
// Then we declare a pointer to an unsigned char (1 byte), make it point to
// the address of our short, and check it's contents. If the address holds
// 244 (which is 11110100) it's the LSB and so we're in a little endian
// machine. Else the content should be 1 (The MSB) in which case we're in
// a big endian machine.
int is_little_endian() {

    // y needs more than one byte
    unsigned short y = 500;

    // c is a pointer to unsigned char (1 byte)
    // and points to the (first) address of y:
    unsigned char* c = (unsigned char*) (&y);

    // If the value of what c points to is 244 (LS Byte), the CPU is little endian:
    if (*c == 244) {
        return 1;
    }

    // If there's another value, the CPU is big endian:
    return 0;
}

// This function takes the LS byte of y and inserts
// it instead of the LS byte of x. To get the LS bytes,
// we declare 2 pointers to an unsigned char (which are 1 byte),
// and point them to the addresses of y and x. On a little endian CPU,
// the first address will hold the LS byte. On a big endian CPU,
// the last address will hold it so we advance the pointers to the
// last addresses. Then because they are the LSB, we just need to
// subtract the LSB of x and add the LSB of y to get our number.
unsigned long merge_bytes(unsigned long x, unsigned long y) {

        // On a little endian CPU the first address will hold the LSB:
        if (is_little_endian()) {
            unsigned char *yLSB = (unsigned char *) &y;
            unsigned char *xLSB = (unsigned char *) (&x);

            // Subtract the LSB of x and add the LSB of y:
            x = x - *xLSB + *yLSB;
            return x;
        }

        // And on big endian, it will be the last:
        else {
            unsigned char *yLSB = (unsigned char *) &y+(sizeof(unsigned long) - 1);
            unsigned char *xLSB = (unsigned char *) &x+(sizeof(unsigned long) - 1);

            // Subtract the LSB of x and add the LSB of y:
            x = x - *xLSB + *yLSB;
            return x;
        }
}

// This function get an unsigned long x, a byte in the form of
// unsigned char and an int to indicate the byte # to replace in x
// (i = 0 is the LSB). This function declares an array of unsigned chars
// in the size of x (unsigned long). We go through the array from the LSB
// to the MSB and assign the original bytes of x accordingly except for
// the byte to replace, in which we insert the argument we were given.
// Then we have an array of the new bytes. We cast it to a pointer
// to an unsigned long number and return the value of that pointer,
// meaning the new number with the correct byte replaced.
// The LSB and MSB are in reverse order in little and big endian
// so in little endian, we access the ith byte from the beginning
// and in big endian, the ith byte from the end.
unsigned long put_byte(unsigned long x, unsigned char b, int i) {

        // If there is no ith byte in x, end and
        // return the original number:
        if (i > sizeof(unsigned long) - 1 || i < 0) {
            return x;
        }

        int j = 0;

        // Declare an array of bytes the size of x.
        // This array will hold the bytes of the new number:
        unsigned char newBytes[sizeof(unsigned long)];

        // We go over the bytes of x, put each one as
        // an element in the bytes array, but change the
        // byte we need.

        // If the CPU is little endian, the byte to replace
        // will be the ith byte from the beginning.
        if (is_little_endian()) {

            for (j; j < sizeof(unsigned long); j++) {

                // When the byte to replace is reached,
                // assign the value of argument "b" to it
                // and continue.
                if (j == i) {
                    newBytes[j] = b;
                    continue;
                }

                // We declare a pointer to an unsigned char
                // (1 byte), and point it to the address of x
                // plus the current offset.
                unsigned char *byte = (unsigned char *) &x + j;

                // We put the value that's in this address
                // in the array.
                newBytes[j] = *byte;
            }
        }

        // If the CPU is big endian, the byte to replace
        // will be the ith byte from the end so we check
        // if i is sizeof(unsigned long) - 1 - j.
        else {
            int j = 0;
            for (j; j < sizeof(unsigned long); j++) {

                // When the byte to replace is reached,
                // assign the value of argument "b" to it
                // and continue.
                if (sizeof(unsigned long) - 1 - j == i) {
                    newBytes[j] = b;
                    continue;
                }

                // We declare a pointer to an unsigned char
                // (1 byte), and point it to the address of x
                // plus the current offset.
                unsigned char *byte = (unsigned char *) &x + j;

                // We put the value that's in this address
                // in the array.
                newBytes[j] = *byte;
            }
        }

        // We have a bytes array, so we cast it to a pointer
        // to unsigned long, and then return the value of
        // that pointer.
        return *(unsigned long *) newBytes;
}
