#define BUFFER_SIZE 1024
#include <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <memory.h>
#include <stdlib.h>

int main() {
    char input[BUFFER_SIZE];
    int i = 0;
    char* args[15];
    char splitBy[2] = " ";

    // Getting input from the prompt

    // INFINITE LOOP GOES HERE..
    fgets(input, BUFFER_SIZE, stdin);

    char *word = strtok(input, splitBy);

    // Go through input line:
    while (word != NULL) {

        // Store separate words in tokens (args) array:
        args[i] = word;
        word = strtok(NULL, splitBy);
        i++;
    }
    args[15] = NULL;

    pid_t pid;
    if ((pid == fork() == 0)) {

        // This is the child, we call exec
        if (execvp(args[0], args) == -1) {
            perror("Command exec. failed to launch. Reason:");
            exit(1);
        }
    }
    else

    return 0;
}