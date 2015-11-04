#include <stdio.h>


// small func
void f1()
{

}
void f4()
{

}
// medium func
void f2()
{

}
void f5()
{

}
// large func
void f3()
{

}
void f6()
{

}

int main()
{
Bag B;

int f1arg[1000];
int f2arg[1000];
int f3arg[1000];

int f4arg[1000];
int f5arg[1000];
int f6arg[1000];

// sm 1,2 - small
// sm 3,4 - medium
// sm 5,6 - large

B.taskAdd(f1,f1arg,1);

B.taskAdd(f2,f1arg,3);

B.taskAdd(f3,f1arg,5);

B.taskAdd(f4,f1arg,2);

B.taskAdd(f5,f1arg,4);

B.taskAdd(f6,f1arg,6);

// call the kernel function
schedule();
}
