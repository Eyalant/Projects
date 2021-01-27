#include <stdio.h>
#include <malloc.h>
#include <unistd.h>
#include "threadPool.h"

void  function1();
void  function2();
void  function3();
void  function1WithSleep();
void  function2Sleep();

int main() {
    ThreadPool* threadPool =tpCreate(1);
    char * args = (char *)malloc(10);
    tpInsertTask(threadPool,function1,args);
    sleep(5);
    tpInsertTask(threadPool,function2,args);
    tpInsertTask(threadPool,function3,args);
    int temp;
    scanf("%d",&temp);
    return 0;
}

/*
void hello (void* a)
{
    printf("hello\n");
    sleep(3);
}


void test_thread_pool_sanity()
{
    int i;

    ThreadPool* tp = tpCreate(5);

    for(i=0; i<10; ++i)
    {
        tpInsertTask(tp,hello,NULL);
    }
    //sleep(5);
    tpDestroy(tp,0);
}
int main(){
    test_thread_pool_sanity();
    return 0;

}
*/
void  function3() {
   int i;
   for(i=1; i<100;i++) {
      printf("3\n");

   }
}

void  function1() {
   int i;
   for(i=1; i<100;i++) {
      printf("1\n");

   }
}
void  function1WithSleep() {
   int i;
   for(i=1; i<10;i++) {
      printf("1\n");
      sleep(1);

   }
}

void  function2() {
   int i;
   for(i=1; i<100;i++) {
      printf("2\n");
   }
}
void  function2Sleep() {
   int i;
   for(i=1; i<10;i++) {
      printf("2\n");
      sleep(1);
   }
}


void * function3Sleep() {
   int i;
   for(i=1; i<100;i++) {
      printf("3\n");
      sleep(1);

   }
}
