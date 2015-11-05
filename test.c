#include <stdio.h>
#include <cuda.h>
#include <cuda_runtime_api.h>


// func
// void square()
// {

// }


int main(int argc, char* argv[])
{

	if (argc != 3)
    {
        printf("usage ./Main base_path_with_trailing_slash number_of_blocks number_of_threads\n");
        exit(1);
    }
	int n = atoi(argv[1]);
	int m = atoi(argv[2]);
	
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
	taskAdd(square,small_arg,1);
	taskAdd(square,small_arg+6,2);

	// medium tasks
	taskAdd(square,med_arg,3);
	taskAdd(square,med_arg+6,4);

	//large tasks
	taskAdd(square,large_arg,5);
	taskAdd(square,large_arg+6,6);

	// call the kernel function
	schedule(n, m);
}
