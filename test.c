#include <stdio.h>


// func
void f1()
{

}


int main()
{
Bag B;

long int small_arg[12]; // small
long int med_arg [12];
long int large_arg[12];

int i;
for(i = 0; i < 12; i++)
{
	small_arg[i] = i;
}

for(i = 0; i < 12; i++)
{
	small_arg[i] = 100 + i;
}

for(i = 0; i < 12; i++)
{
	small_arg[i] = 10000 + i;
}

// sm 3,4 - medium
// sm 5,6 - large

// sm 1,2 - small
taskAdd(f1,small_arg,1);
taskAdd(f1,small_arg+6,2);

// medium tasks
taskAdd(f1,med_arg,3);
taskAdd(f1,med_arg+6,4);

//large tasks
taskAdd(f1,large_arg,5);
taskAdd(f1,large_arg+6,6);

// call the kernel function
schedule();
}
