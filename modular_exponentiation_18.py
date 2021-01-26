# This is a simple implementation of modular exponentiation (from an Algebric Structures course).

from math import floor


def main():
    global file
    with open('result.txt', 'w') as file:
        # Run SP as in the question (last two digits are 1,8):
        superpower(1+8+9, 3000+10+8, 89214)

        # num of output rows for this run is 18 < 2logk = 23


def superpower(x, k, n):
    # Calculate m^k (mod n) recursively.

    # Stop condition:
    if k == 0:
        return 1

    # For m^k:

    if k % 2 == 0:
        # k is even, so m^k = (m^(k/2)) ^ 2
        ret = pow(superpower(x, floor(k / 2), n), 2)

    else:
        # k is odd, so m^k = (m^(k/2)) ^ 2 * m. Need to print
        # every time we square as well (m^(k-1)), so call with k-1
        # before multiplying:
        ret = superpower(x, k-1, n)
        ret *= x

    # Perform mod n
    ret %= n

    # Print and save to file
    line = str(x) + "^" + str(k) + " = " + str(ret) + " (mod " + str(n) + ")"
    print(line)
    file.write(line + '\n')
    return ret


if __name__ == "__main__":
    main()
