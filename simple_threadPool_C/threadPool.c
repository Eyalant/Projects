#include "threadPool.h"

ThreadPool *tpCreate(int numOfThreads) {
    //Thread pool allocation
    ThreadPool *threadPool = (ThreadPool *) malloc(sizeof(ThreadPool));
    if (threadPool == NULL) {
        exit(-1);
    }
    threadPool->numOfThreads = numOfThreads;
    //Threads array allocation
    (*threadPool).threadsArray = (pthread_t *) malloc(numOfThreads * sizeof(pthread_t));
    if (threadPool->threadsArray == NULL) {
        exit(-1);
    }
    threadPool->enableTasksInsertion = TRUE;
    threadPool->isDestroyed = FALSE;
    threadPool->tasksInQueueArray = osCreateQueue();
    threadPool->continueExecutingTasks = TRUE;
    createMutex(threadPool);
    createThreads(threadPool);
    return threadPool;
}

void tpDestroy(ThreadPool *threadPool, int shouldWaitForTasks) {
    pthread_mutex_lock(&threadPool->destroyMutex);
    //The thread pool has already been destroyed
    if (threadPool->isDestroyed == TRUE) {
        return;
    } else {
        threadPool->isDestroyed = TRUE;
        pthread_mutex_unlock(&threadPool->destroyMutex);
        threadPool->enableTasksInsertion = FALSE;
        if (shouldWaitForTasks != 0) {
            threadPool->continueExecutingTasks = TRUE;
            pthread_cond_broadcast(&(threadPool->notify));
        } else {
            threadPool->continueExecutingTasks = FALSE;
        }
        waitForActiveTasks(threadPool);
        clearThreadPoolData(threadPool);
        free(threadPool);
    }
}

int tpInsertTask(ThreadPool *threadPool, void (*computeFunc)(void *), void *param) {
    if (threadPool->enableTasksInsertion == FALSE) {
        return -1;
    } else {
        //Allocate a new task
        Task *task = (Task *) malloc(sizeof(Task));
        if (task == NULL) {
            exit(-1);
        }
        task->args = param;
        task->func = computeFunc;
        pthread_mutex_lock(&threadPool->queueMutex);
        osEnqueue(threadPool->tasksInQueueArray, task);
        if (pthread_cond_signal(&(threadPool->notify)) != 0) {
            exit(-1);
        }
        pthread_mutex_unlock(&threadPool->queueMutex);
    }
    return 0;
}

void *execute(void *args) {
    ThreadPool *threadPool = (ThreadPool *) args;
    OSQueue *queue = threadPool->tasksInQueueArray;
    //Loop through the tasks in the queue
    while (osIsQueueEmpty(queue) == FALSE && threadPool->continueExecutingTasks == TRUE) {
        pthread_mutex_lock(&(threadPool->queueMutex));
        //If the queue is empty avoid busy waiting
        if ((osIsQueueEmpty(queue))) {
            pthread_cond_wait(&(threadPool->notify), &(threadPool->queueMutex));
        }
        pthread_mutex_unlock(&(threadPool->queueMutex));

        pthread_mutex_lock(&(threadPool->poolLockMutex));
        //Fetch a task from the queue and invoke its function
        if (osIsQueueEmpty(queue) == FALSE && threadPool->continueExecutingTasks == TRUE) {
            Task *task = osDequeue(queue);
            pthread_mutex_unlock(&(threadPool->poolLockMutex));
            task->func(task->args);
            free(task);
        } else {
            pthread_mutex_unlock(&(threadPool->poolLockMutex));
        }
    }
}

void createThreads(ThreadPool *threadPool) {
    int i = 0;
    while (i < threadPool->numOfThreads) {
        pthread_create(&(threadPool->threadsArray[i]), NULL, execute, (void *) threadPool);
        i++;
    }
}

void createMutex(ThreadPool *threadPool) {
    pthread_mutex_init(&(threadPool->poolLockMutex), NULL);
    pthread_mutex_init(&(threadPool->destroyMutex), NULL);
    pthread_mutex_init(&(threadPool->queueMutex), NULL);
    pthread_cond_init(&(threadPool->notify), NULL);
}

void waitForActiveTasks(ThreadPool *threadPool) {
    int i = 0;
    while (i < threadPool->numOfThreads) {
        pthread_join(threadPool->threadsArray[i], NULL);
        i++;
    }
}

void clearTasksInQueue(OSQueue *queue) {
    while (osIsQueueEmpty(queue) == FALSE) {
        Task *task = osDequeue(queue);
        free(task);
    }
}

void clearThreadPoolData(ThreadPool *threadPool) {
    clearTasksInQueue(threadPool->tasksInQueueArray);
    osDestroyQueue(threadPool->tasksInQueueArray);
    free(threadPool->threadsArray);
    pthread_mutex_destroy(&(threadPool->poolLockMutex));
    pthread_mutex_destroy(&(threadPool->queueMutex));
    pthread_mutex_destroy(&(threadPool->destroyMutex));
}