#ifndef __THREAD_POOL__
#define __THREAD_POOL__

#include <sys/types.h>
#include "osqueue.h"
#include<stdlib.h>
#include<unistd.h>
#include <malloc.h>
#include <pthread.h>
#include<stdio.h>
#include<string.h>

#define TRUE 1
#define FALSE 0
typedef struct task {
    void (*func)(void *);

    void *args;

} Task;
typedef struct thread_pool {
    pthread_mutex_t queueMutex;
    pthread_mutex_t poolLockMutex;
    pthread_mutex_t destroyMutex;
    pthread_t *threadsArray;
    OSQueue *tasksInQueueArray;
    int numOfThreads;
    int enableTasksInsertion;
    int continueExecutingTasks;
    int isDestroyed;
    pthread_cond_t notify;
} ThreadPool;

/**
 * Creates and initializes a thread pool object.
 * @param numOfThreads number of threads to allocate.
 * @return a pointer to ThreadPool.
 */
ThreadPool *tpCreate(int numOfThreads);

/**
 * Destroys the thread pool and frees the allocated memory.
 * @param threadPool
 * @param shouldWaitForTasks
 */
void tpDestroy(ThreadPool *threadPool, int shouldWaitForTasks);

/**
 * Creates a new task the pushes it to the thread pools inner queue.
 * @param threadPool
 * @param computeFunc
 * @param param
 * @return 0 if the insertion was successful, other wise -1.
 */
int tpInsertTask(ThreadPool *threadPool, void (*computeFunc)(void *), void *param);

/**
 * Executes the task logic according to the input args.
 * @param args
 */
void *execute(void *args);

/**
 * Creates an array of threads.
 * @param threadPool
 */
void createThreads(ThreadPool *threadPool);

/**
 * Creates the necessary mutexes.
 * @param threadPool
 */
void createMutex(ThreadPool *threadPool);

/**
 * Joins all the allocated threads.
 * @param threadPool
 */
void waitForActiveTasks(ThreadPool *threadPool);

/**
 * Frees the allocated tasks.
 * @param queue
 */
void clearTasksInQueue(OSQueue *queue);

/**
 * Frees the allocates threads array, queue and mutexes.
 * @param threadPool
 */
void clearThreadPoolData(ThreadPool *threadPool);

#endif