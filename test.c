#include <stdio.h>
#include <cuda.h>
#include <cuda_runtime_api.h>
#define debug 0

void * square(void *arr);	

int main(int argc, char* argv[])
{

	if (argc != 3)
    {
        printf("usage ./Main base_path_with_trailing_slash number_of_blocks number_of_threads\n");
        exit(1);
    }
	int n = atoi(argv[1]);
	int m = atoi(argv[2]);
	
	if (debug) printf("Taken number Of blocks and threads.\n");
	// Bag B;

	long int small_arg[12]; // small
	long int med_arg [12];
	long int large_arg[12];

	int i;

	if (debug) printf("Taking input for small work.\n");

	for(i = 0; i < 12; i++)
	{
		small_arg[i] = i;
	}

	if (debug) printf("Taking input for medium work.\n");

	for(i = 0; i < 12; i++)
	{
		small_arg[i] = 100 + i;
	}

	if (debug) printf("Taking input for large work.\n");

	for(i = 0; i < 12; i++)
	{
		small_arg[i] = 10000 + i;
	}

	if (debug) printf("All inputs taken. Will start adding tasks.\n");

	// sm 3,4 - medium
	// sm 5,6 - large

	// sm 1,2 - small

	taskAdd(square,small_arg,1);

	if (debug) printf("In Main:		Added the first (small) task, sm = 1.\n");

	taskAdd(square,small_arg+6,2);

	if (debug) printf("In Main:		Added the second (small) task, sm = 2.\n");

	// medium tasks
	taskAdd(square,med_arg,3);

	if (debug) printf("In Main:		Added the third (medium) task, sm = 3.\n");

	taskAdd(square,med_arg+6,4);

	if (debug) printf("In Main:		Added the fourth (medium) task, sm = 4.\n");


	//large tasks
	taskAdd(square,large_arg,5);

	if (debug) printf("In Main:		Added the fifth (large) task, sm = 5.\n");

	taskAdd(square,large_arg+6,6);

	if (debug) printf("In Main:		Added the sixth (large) task, sm = 6.\n");

	if (debug) printf("In Main:		Will call the schedule function\n");

	// call the kernel function
	schedule(n, m);
	if (debug) printf("In Main:		Schedule over.\n");
}
