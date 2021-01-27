#define MAX_LINE 161
#define LINES_IN_CONFIG_FILE 3
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <dirent.h>
#include <memory.h>
#include <wait.h>
#include <stdlib.h>

typedef enum {NO_C_FILE = 0, COMPILATION_ERROR = 1, TIMEOUT = 2, BAD_OUTPUT = 60,
SIMILAR_OUTPUT = 80, GREAT_JOB = 100} res;

void assignScore(char* studentName, res result, int fd) {

    // Write "name,"
    char student[MAX_LINE];
    strcpy(student, studentName);

    // Write grade
    switch (result) {
        case NO_C_FILE: strcat(student, ",0,NO_C_FILE"); break;
        case TIMEOUT: strcat(student, ",0,TIMEOUT"); break;
        case COMPILATION_ERROR: strcat(student, ",0,COMPILATION_ERROR"); break;
        case BAD_OUTPUT: strcat(student, ",60,BAD_OUTPUT"); break;
        case SIMILAR_OUTPUT: strcat(student, ",80,SIMILAR_OUTPUT"); break;
        case GREAT_JOB: strcat(student, ",100,GREAT_JOB"); break;
    }

    strcat(student,"\n");
    if (write(fd, student, strlen(student)) < 0) {
        const char err[] = "Writing student name to res file has failed.\n";
        write(2, err, sizeof(err));
        exit(1);
    }
}

res compareOutputs(char* pathToCreatedOutput, char* pathToCorrectOutput) {
    int status;
    pid_t retVal;

    printf("Comparing outputs between tempOut.txt and the correct output\n");

    retVal = fork();
    if (retVal == -1) {

        // Forking has failed
        const char err[] = "Forking has failed\n";
        write(2, err, sizeof(err));
        exit(1);
    }

    if (retVal == 0) {

        // This is the child
        char *args[4];
        args[0] = "./comp.out";
        args[1] = "tempOut.txt";
        args[2] = pathToCorrectOutput;
        args[3] = NULL;

        // Calling exec and checking if it failed:
        if (execvp(args[0], args) == -1) {
            const char err[] = "Command exec. failed to launch.\n";
            write(2, err, sizeof(err));
            exit(1);
        }

    } else if (retVal > 0) {

        // If the program times out:
        waitpid(retVal, &status, 0);
        int comparisonResult = WEXITSTATUS(status);

        if (comparisonResult == 1) {

            // Files not similar
            return BAD_OUTPUT;
        }

        else if (comparisonResult == 2) {

            // Files are similar
            return SIMILAR_OUTPUT;
        }

        else if (comparisonResult == 3) {

            // Files are identical
            return GREAT_JOB;
        }
    }
}

res runFile(char* outFilePath, char* pathToInputFile, char* pathToCorrectOutput) {
    int status, input, output;
    pid_t retVal;
    retVal = fork();
    if (retVal == -1) {

        // Forking has failed
        const char err[] = "Forking has failed\n";
        write(2, err, sizeof(err));
        exit(1);
    }

    if (retVal == 0) {

        // This is the child
        input = open(pathToInputFile, O_RDONLY);
        output = open("tempOut.txt", O_CREAT | O_WRONLY | O_TRUNC, 0666);

        if (output < 0 || input < 0) {
            const char err[] = "Failed returning FDs.\n";
            write(2, err, sizeof(err));
            exit(1);
        }

        // Redirect I/O:
        if (dup2(input, STDIN_FILENO) < 0) {
            const char err[] = "Failed duplicating FDs.\n";
            write(2, err, sizeof(err));
            exit(1);
        }

        if (dup2(output, STDOUT_FILENO) < 0) {
            const char err[] = "Failed duplicating FDs.\n";
            write(2, err, sizeof(err));
            exit(1);
        }

        char *args[2];
        args[0] = outFilePath;
        args[1] = NULL;

        // Calling exec and checking if it failed:
        if (execvp(args[0], args) == -1) {
            const char err[] = "Command exec. failed to launch.\n";
            write(2, err, sizeof(err));
            exit(1);
        }

        close(output);
        close(input);

    } else if (retVal > 0) {

        // This is the parent
        sleep(5);

        // If the program times out:
        if (waitpid(retVal, &status, WNOHANG) == 0) {
            puts("\n\nTimed out\n\n");
            return TIMEOUT;
        };
        printf("Ran %s successfully.\n", outFilePath);

        res result = compareOutputs("tempOut.txt", pathToCorrectOutput);
        return result;
    }
}



res compileFile(char* pathToFile, char* outFilePath, char* fileName, char* pathToInputFile, char* pathToCorrectOutput) {
    int status;
    pid_t retVal;
    retVal = fork();

    if (retVal == -1) {

        // Forking has failed
        const char err[] = "Forking has failed\n";
        write(2, err, sizeof(err));
        exit(1);
    }

    if (retVal == 0) {

        // This is the child
        char *args[5];
        args[0] = "gcc";
        args[1] = pathToFile;
        args[2] = "-o";
        args[3] = outFilePath;
        args[4] = NULL;

        // Calling exec and checking if it failed:
        if (execvp(args[0], args) == -1) {
            const char err[] = "Command exec. failed to launch.\n";
            write(2, err, sizeof(err));
            exit(1);
        }

    } else if (retVal > 0) {

        // This is the parent
        if (waitpid(retVal, &status, 0) > 0 && WEXITSTATUS(status) != 0) {
            return COMPILATION_ERROR;
        }

        printf("Compiled %s which is in %s successfully. Now running it.\n", fileName, pathToFile);
        res result = runFile(outFilePath, pathToInputFile, pathToCorrectOutput);
        return result;
    }
}

res searchDir(char* pathToDir, char* pathToInputFile, char* pathToCorrectOutput) {
    DIR* dirP;
    struct dirent* dir;
    dirP = opendir(pathToDir);
    printf("Opening directory %s\n", pathToDir);

    if (dirP == NULL) {
        const char err[] = "Cannot open directory\n";
        write(2, err, sizeof(err));
        exit(1);
    }

    dir = readdir(dirP);
    while (dir != NULL) {

        if (dir->d_type == DT_DIR && (strcmp(dir->d_name, ".") == 0 || strcmp(dir->d_name, "..") == 0)) {
            dir = readdir(dirP);
            continue;
        }

        // Go through files/folders in directory
        printf("Now looking at file %s in folder %s\n", dir->d_name, pathToDir);

        // If it's a folder, search it's subfolders
        if (dir->d_type == DT_DIR &&
                strcmp(dir->d_name, ".") != 0 && strcmp(dir->d_name, "..") != 0) {
            char subPath[MAX_LINE];
            strcpy(subPath, pathToDir);
            strcat(subPath, "/");
            strcat(subPath, dir->d_name);
            res result = searchDir(subPath, pathToInputFile, pathToCorrectOutput);
            if (result != NO_C_FILE) {
                return result;
            }
        }

        // Check if the file is a REG file and extension is .c
        if (dir->d_type == DT_REG &&
                dir->d_name[strlen(dir->d_name) - 2] == '.' && dir->d_name[strlen(dir->d_name) - 1] == 'c') {
            printf("Found a C file called %s\n", dir->d_name);

            // COMPILE THIS FILE
            char filePath[MAX_LINE];
            char outFilePath[MAX_LINE];
            strcpy(filePath, pathToDir);
            strcat(filePath, "/");
            strcat(filePath, dir->d_name);

            strcpy(outFilePath, pathToDir);
            strcat(outFilePath, "/");
            strcat(outFilePath, dir->d_name);
            outFilePath[strlen(outFilePath) - 1] = 'o';
            strcat(outFilePath, "ut");

            res result = compileFile(filePath, outFilePath, dir->d_name, pathToInputFile, pathToCorrectOutput);
            return result;
        }

        dir = readdir(dirP);
    }

    // if (!found) {
        return NO_C_FILE;
    // }
}

int main(int argc, char* argv[]) {

    char configInfo[LINES_IN_CONFIG_FILE][MAX_LINE];
    char buf;

    // Start by reading the config file which contains 3 lines:
    int config = open(argv[1], O_RDONLY);

    // If opening the config file has failed
    if (config < 0) {
        const char err[] = "Error in System Call in main function\n";
        write(2, err, sizeof(err));
        return -1;
    }

    int line = 0, letter = 0;

    // Read the config file
    while (read(config, &buf, 1) != 0) {
        configInfo[line][letter] = buf;
        letter++;

        if (buf == '\n') {

            // Terminate the string and move to the next line:
            configInfo[line][letter-1] = '\0';
            line++;
            letter = 0;
        }
    }

    // Results of reading the config file:
    printf("The folder path is: %s\n", configInfo[0]);
    printf("The input file path is: %s\n", configInfo[1]);
    printf("The correct output path is: %s\n\n", configInfo[2]);


    // Prepare the results file:
    int fd = open("results.csv", O_CREAT | O_WRONLY | O_TRUNC, 0666);
    if (fd < 0) {
        const char err[] = "Creating res file has failed.\n";
        write(2, err, sizeof(err));
        exit(1);
    }

    DIR* dirP;
    struct dirent* dir;
    dirP = opendir(configInfo[0]);

    if (dirP == NULL) {
        const char err[] = "Cannot open directory\n";
        write(2, err, sizeof(err));
        return -1;
    }

    dir = readdir(dirP);
    while (dir != NULL) {

        if (dir->d_type == DT_DIR && (strcmp(dir->d_name, ".") == 0 || strcmp(dir->d_name, "..") == 0)) {
            dir = readdir(dirP);
            continue;
        }

        // Go through files/folders in directory
        printf("Now looking at folder %s in the base folder\n", configInfo[0]);

        if (dir->d_type == DT_DIR &&
            strcmp(dir->d_name, ".") != 0 && strcmp(dir->d_name, "..") != 0) {
            char subPath[MAX_LINE];
            strcpy(subPath, configInfo[0]);
            strcat(subPath, "/");
            strcat(subPath, dir->d_name);
            res result = searchDir(subPath, configInfo[1], configInfo[2]);
            assignScore(dir->d_name, result, fd);

            // Print the result for each student:
            if (result == TIMEOUT || result == NO_C_FILE || result == COMPILATION_ERROR) {
                result = NO_C_FILE;
            }
            printf("Student: %s, Grade: %d\n", dir->d_name, result);

            // SEARCHING IN ALL SUBFOLDERS, EACH ONE SHOULD RETURN A RESULT
        }

        dir = readdir(dirP);
    }

    return 0;
}