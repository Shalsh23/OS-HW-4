#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#define debug 1


unsigned int jobChunkArray[1000];
int jobChunkCounter = 0;
unsigned int SMC_workerCount[] = {0, 0, 0, 0, 0, 0}; // Array of counter for blocks created for each SM.

extern "C" __device__ void * square(void *func_arg)
{
	// __SMC_Begin
	//printf("The value of x is %d \n",x);
	//printf("The value of threadIdx.x is %d\n",threadIdx.x);
      //  printf("The value of blockIdx.x is %d\n", blockIdx.x);
	//printf("The value of blockIdx.x is %d\n",blockDim.x);
	

	//if (x > length)
	//	return;
	printf("In square\n.");
	int* array = (int*) func_arg;
	// int threadIdx = func_arg->threadIdx;
    int f = array[threadIdx.x];
    array[threadIdx.x] = f * f;
    return (void *)array;
    // __SMC_End
}

typedef void* (*func)(void *);

// Static pointers to device functions
__device__ func function;

typedef struct bag_elem
{
	//void* (*func)(void*);
	func y;
	void* arg;
} Bag_elem;

Bag_elem Bag[6][1000];

int sm_index[] = {0,0,0,0,0,0}; // index for 6 SMs

int jobchunk_id = 0;

int length_of_chunk = 6;

extern "C" int taskAdd(func userfunc, void* arg, int sm)
{
	if (debug) printf("In taskAdd:		Adding the task for sm = %d.\n", sm);
	function = userfunc;
	if (debug) printf("In taskAdd:		Adding the argument array for sm = %d. Bag's row_number is %d, column number is %d\n", sm, sm_index[sm], sm);
	(Bag[sm_index[sm]][sm]).arg = arg;
	int retval = jobchunk_id;
	jobchunk_id++;
	if (debug) printf("In taskAdd:		Adding to the jobChunkArray: jobChunkCounter: %d, retval: %d\n", jobChunkCounter, retval);
	jobChunkArray[jobChunkCounter] = retval; // Doubtful.
	jobChunkCounter++;
	return retval;
}


__global__ void persistent_func(Bag_elem Bag[6][1000], func d_user_func, unsigned int * __SMC_chunkCount, unsigned int * __SMC_newChunkSeq, unsigned int __SMC_chunksPerSM)
{
	//printf("In kernel:		Enter. Will start __SMC_Begin.\n");

	__shared__ int __SMC_workingCTAs;
	int __SMC_chunkID;
	uint __SMC_smid;
 	asm("mov.u32 %0, %smid;" : "=r"(__SMC_smid) );

 	int i;
		for (i = 0; i < 6; i++)
			printf("%u ",__SMC_chunkCount[i]);
		printf("\n");

	 printf("In kernel:		Got the Smid. It is %u.\n",__SMC_smid);


 	int offsetInCTA = threadIdx.x;
	if (offsetInCTA == 0)
    	__SMC_workingCTAs = atomicInc((unsigned int *)&__SMC_chunkCount[__SMC_smid], INT_MAX);

    printf("In kernel:		workingCTAs. It is %d.\n",__SMC_workingCTAs);

	__syncthreads(); 

	printf("In kernel:		workingCTAs. It is %d.\n",__SMC_workingCTAs);

	if (__SMC_workingCTAs >= __SMC_chunksPerSM)
    return;
	int __SMC_chunksPerCTA = __SMC_chunksPerSM / __SMC_chunksPerSM; 
	int __SMC_startChunkIDidx = __SMC_smid * __SMC_chunksPerSM + __SMC_workingCTAs * __SMC_chunksPerCTA;
	for (int __SMC_chunkIDidx = __SMC_startChunkIDidx; __SMC_chunkIDidx < __SMC_startChunkIDidx + __SMC_chunksPerCTA; __SMC_chunkIDidx ++) { 
    __SMC_chunkID = __SMC_newChunkSeq[__SMC_chunkIDidx];

	int x = threadIdx.x + __SMC_chunkID * blockDim.x;

	( *d_user_func )( (Bag[__SMC_smid][x]).arg );
	// (Bag[__SMC_smid][x])->y((Bag[__SMC_smid][x])->arg);
	
	}


}

extern "C" void schedule(int n, int m)
{
	if (debug) printf("In schedule:		Enter. Will copy device function pointer to host side.\n");

	func h_user_func;

	// Copy device function pointer to host side
	cudaMemcpyFromSymbol( &h_user_func, function, sizeof( func ) );

	if (debug) printf("In schedule:		Copying of the device function pointer done.\n");

	func d_user_func = h_user_func;

	// allocating memory on cuda for cpu variables
	Bag_elem d_Bag[6][1000];
	Bag_elem h_Bag[6][1000];

	if (debug) printf("In schedule:		TBD - Cuda Malloc for Bag in GPU.\n");

	// cudaMalloc((void**) &__SMC_newChunkSeq, sizeof(int) * 1000);
	// cudaMalloc((void**) &__SMC_workerCount, sizeof(Bag_elem)*6*1000);
	// cudaMalloc((void**) &d_Bag, sizeof(Bag_elem)*6*1000);
	// cudaMalloc((void**) &d_Bag, sizeof(Bag_elem)*6*1000);


	if (debug) printf("In schedule:		TBD - Cuda Memcpy for Bag in GPU.\n");
	// copying data from cpu to gpu
	cudaMemcpy(d_Bag, Bag, sizeof(Bag_elem)*6*1000, cudaMemcpyHostToDevice);

	if (debug) printf("In schedule:		SMC BEGIN.\n");

	if (debug)
	{
		int i;
		for (i = 0; i < 6; i++)
			printf("%d ",SMC_workerCount[i]);
		printf("\n");
	}


	unsigned int __SMC_workersNeeded = 2;  // Need to be made dynamic based on user input.
	unsigned int * __SMC_newChunkSeq = jobChunkArray;
	unsigned int * __SMC_workerCount = SMC_workerCount; // Array of counter for blocks created for each SM.


	if (debug)
	{
		int i;
		for (i = 0; i < 6; i++)
			printf("%u ",__SMC_workerCount[i]);
		printf("\n");
	}

	if (debug) printf("In schedule:		Kernel Call.\n");

	persistent_func <<< n, m >>> (d_Bag, d_user_func, __SMC_workerCount, __SMC_newChunkSeq, __SMC_workersNeeded);

	cudaDeviceSynchronize();
	cudaThreadSynchronize();

	if (debug) printf("In schedule:		Kernel Call Ends. Do CudaMemCpy.\n");

	cudaMemcpy(h_Bag, d_Bag, sizeof(Bag_elem)*6*1000, cudaMemcpyDeviceToHost);

	if (debug) printf("In schedule:		Results copied into the CPU. Time for printing.\n");

	int i, y;
	int *temp_ans;
	for(i = 0; i < 6; i++)
	{
		temp_ans = (int *)h_Bag[i][0].arg;
		for (y = 0; y < length_of_chunk; y++)
			printf("%d ", temp_ans[y]);
		printf("\n");
	}
	cudaFree(d_Bag);

}

