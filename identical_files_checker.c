// Eyal Lantzman 205502818

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

char makeLowcase(char c) {
    if (c >= 'A' && c <= 'Z') {
        c += 32;
    }

    return c;
}

int areIdentical(char* pathToFirst, char* pathToSecond) {
    char bufFirst, bufSecond;
    int first = open(pathToFirst, O_RDONLY);
    int second = open(pathToSecond, O_RDONLY);

    // If opening the first or second file has failed
    if (first < 0 || second < 0) {
        const char err[] = "Error in System Call";
        write(2, err, sizeof(err));
    }

    int counter = 0;
    ssize_t firstRead = read(first, &bufFirst, 1);
    ssize_t secondRead = read(second, &bufSecond, 1);

    while (firstRead != 0 || secondRead != 0) {
        counter++;
        // printf("Comparing %c with %c\n", bufFirst, bufSecond);

        if (firstRead == 0) {
            bufFirst = EOF;
        }

        if (secondRead == 0) {
            bufSecond = EOF;
        }

        if (bufFirst != bufSecond) {
            printf("Read a total of %d bytes\n", counter);
            printf("Files don't match!\n");
            return 0;
        }

        firstRead = read(first, &bufFirst, 1);
        secondRead = read(second, &bufSecond, 1);
    }

    close(first);
    close(second);
    printf("Files match!\n");
    return 1;
}

int areSimilar(char* pathToFirst, char* pathToSecond) {
    char bufFirst, bufSecond, lastLetterFirst = EOF, lastLetterSecond = EOF;
    int first = open(pathToFirst, O_RDONLY);
    int second = open(pathToSecond, O_RDONLY);

    // If opening the first or second file has failed
    if (first < 0 || second < 0) {
        const char err[] = "Error in System Call\n";
        write(2, err, sizeof(err));
    }

    int counter = 0, comparedLastChars = 0, skipFirstRead = 0, skipSecondRead = 0;
    ssize_t firstRead = read(first, &bufFirst, 1);
    ssize_t secondRead = read(second, &bufSecond, 1);

    while (firstRead != 0 || secondRead != 0) {
        bufFirst = makeLowcase(bufFirst);
        bufSecond = makeLowcase(bufSecond);
        skipFirstRead = 0;
        skipSecondRead = 0;

        counter++;
        printf("Comparing %c with %c\n", bufFirst, bufSecond);

        if (firstRead == 0) {
            bufFirst = lastLetterFirst;
        }

        if (secondRead == 0) {
            bufSecond = lastLetterSecond;
        }

        // 1
        if (bufFirst != bufSecond) {
            if ((bufFirst != ' ' && bufFirst != '\n' && bufFirst != '\t')
                && (bufSecond == ' ' || bufSecond == '\n' || bufSecond == '\t')) {
                skipFirstRead = 1;
            }
        }

        // 2
        if (bufFirst != bufSecond) {
            if ((bufFirst == ' ' || bufFirst == '\n' || bufFirst == '\t')
                && (bufSecond != ' ' && bufSecond != '\n' && bufSecond != '\t')) {
                skipSecondRead = 1;
            }
        }

        if (bufFirst != bufSecond) {
            if ((bufFirst != ' ' && bufFirst != '\n' && bufFirst != '\t')
                && (bufSecond != ' ' && bufSecond != '\n' && bufSecond != '\t')) {
                printf("Files aren't similar!\n");
                close(first);
                close(second);
                return 0;
            }
        }

        if (!skipFirstRead) {
            firstRead = read(first, &bufFirst, 1);
        }

        if (!skipSecondRead) {
            secondRead = read(second, &bufSecond, 1);
        }

        if (firstRead == 0 && secondRead == 0 && !comparedLastChars) {
                bufFirst = lastLetterFirst;
                bufSecond = lastLetterSecond;
                firstRead = 1;
                secondRead = 1;
                comparedLastChars = 1;
        }
    }

    close(first);
    close(second);
    printf("Read a total of %d bytes\n", counter);
    printf("Files are similar!\n");
    return 1;
}

int main(int argc, char **argv) {

    // Check if the files are identical:
    int retVal = areIdentical(argv[1], argv[2]);
    if (retVal == 1) {
        return 3;
    }

    if (retVal == 0) {
        int simRetVal = areSimilar(argv[1], argv[2]);

        if (simRetVal == 1) {
            return 2;
        }

        if (simRetVal == 0) {
            return 1;
        }
    }
}

