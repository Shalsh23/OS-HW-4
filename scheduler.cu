#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#define debug 1


unsigned int jobChunkArray[] = {0, 1, 2, 3, 4, 5, 6 ,7 , 8, 9, 10, 11};
int jobChunkCounter = 0;
unsigned int SMC_workerCount[] = {0, 0, 0, 0, 0, 0}; // Array of counter for blocks created for each SM.

extern "C" __device__ void * square(void *func_arg)
{
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
__device__ func function = square;

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
	//function = userfunc;
	if (debug) printf("In taskAdd:		Adding the argument array for sm = %d. Bag's row_number is %d, column number is %d\n", sm, sm_index[sm], sm);
	(Bag[sm][sm_index[sm]]).arg = arg;
	int retval = jobchunk_id;
	jobchunk_id++;
	if (debug) printf("In taskAdd:		Adding to the jobChunkArray: jobChunkCounter: %d, retval: %d\n", jobChunkCounter, retval);
	// jobChunkArray[jobChunkCounter] = retval; // Doubtful.
	// jobChunkCounter++;
	// jobChunkArray[jobChunkCounter] = retval + 1; // Hardcode.

	return retval;
}


__global__ void persistent_func(Bag_elem *d_Bag, func op, unsigned int * __SMC_chunkCount, unsigned int * __SMC_newChunkSeq, unsigned int __SMC_chunksPerSM)
{
	printf("In kernel:		Enter. Will start __SMC_Begin.\n");
	int *temp, i, y;
	__shared__ int __SMC_workingCTAs;
	int __SMC_chunkID;
	uint __SMC_smid;
 	asm("mov.u32 %0, %smid;" : "=r"(__SMC_smid) );
		// for (i = 0; i < 6; i++)
		// 	printf("%u ",__SMC_chunkCount[i]);
		// printf("\n");

	printf("In kernel:		Got the Smid. It is %u.\n",__SMC_smid);


 	int offsetInCTA = threadIdx.x;
	if (offsetInCTA == 0)
    {
    	__SMC_workingCTAs = atomicInc((unsigned int *)&__SMC_chunkCount[__SMC_smid], INT_MAX);
		printf("In kernel:		workingCTAs. It is %d. Block is %d. SMID is %d\n",__SMC_workingCTAs, blockIdx.x, __SMC_smid);
	}

	__syncthreads(); 

	printf("In kernel:		__SMC_chunksPerSM is %d. __SMC_workingCTAs is %d. SMID is %d.\n",__SMC_chunksPerSM, __SMC_workingCTAs, __SMC_smid);

	if (__SMC_workingCTAs >= __SMC_chunksPerSM)
    return;

	int __SMC_chunksPerCTA = __SMC_chunksPerSM / __SMC_chunksPerSM; 
	int __SMC_startChunkIDidx = __SMC_smid * __SMC_chunksPerSM + __SMC_workingCTAs * __SMC_chunksPerCTA;

	printf("In kernel:		__SMC_startChunkIDidx is %d. SMID is %d.\n", __SMC_startChunkIDidx, __SMC_smid);
	for (int __SMC_chunkIDidx = __SMC_startChunkIDidx; __SMC_chunkIDidx < __SMC_startChunkIDidx + __SMC_chunksPerCTA; __SMC_chunkIDidx ++) { 
    printf("SMID is %d. __SMC_chunkIDidx is %d. __SMC_newChunkSeq[__SMC_chunkIDidx] is %d.\n", __SMC_smid,__SMC_chunkIDidx, __SMC_newChunkSeq[__SMC_chunkIDidx]);

    __SMC_chunkID = __SMC_newChunkSeq[__SMC_chunkIDidx];
    //printf("chunk id \n%d\n", __SMC_chunkID);
	int x = threadIdx.x + __SMC_chunkID * blockDim.x;
    printf("ThreadId is %d. __SMC_ChunkId is %d. blockDim.x is %d. x = %d\n", threadIdx.x, __SMC_chunkID, blockDim.x,x);

	//printf("Inside loop\n");
	// square((Bag[__SMC_smid][x]).arg );
	//int anum[] = {1,2};
	int *bagval = (int*)d_Bag[__SMC_smid * 1000 + x].arg;
	for(i = 0; i < 6; i++)
	{
		printf("%d\n", bagval[i]);
	}
	// square(d_Bag[__SMC_smid * 1000 + x].arg);
	// (Bag[__SMC_smid][x])->y((Bag[__SMC_smid][x])->arg);
	printf("After function call\n");

	}


}

extern "C" void schedule(int n, int m)
{

	int *temp, i,y;
	if (debug) printf("In schedule:		Enter. Will copy device function pointer to host side.\n");

	func h_user_func;
	unsigned int * __SMC_newChunkSeq;
	unsigned int * __SMC_chunkCount;

	// Copy device function pointer to host side
	cudaMemcpyFromSymbol( &h_user_func, function, sizeof( func ) );

	if (debug) printf("In schedule:		Copying of the device function pointer done.\n");

	func d_user_func = h_user_func;

	// allocating memory on cuda for cpu variables
	//Bag_elem d_Bag[6][1000];
	//Bag_elem h_Bag[6][1000];
	Bag_elem *d_Bag_1d;
	Bag_elem h_Bag_1d[6000];

	int *d_array;

	Bag_elem * Bag_ptr = &Bag[0][0];
	for(i = 0; i < 6; i++)
	{	
		temp = (int *)((Bag_ptr[1000 * i]).arg);
		for (y = 0; y < 6; y++)
			printf("%d ", temp[y]);
	}

	if (debug) printf("In schedule:		TBD - Cuda Malloc for Bag in GPU.\n");

	// cudaMalloc((void**) &__SMC_newChunkSeq, sizeof(int) * 1000);
	// cudaMalloc((void**) &__SMC_workerCount, sizeof(Bag_elem)*6*1000);
	// cudaMalloc((void**) &d_Bag, sizeof(Bag_elem)*6*1000);
	cudaMalloc((void**) &d_Bag_1d, sizeof(Bag_elem)*6*1000);
	cudaMalloc((void**) &__SMC_chunkCount, sizeof(int)*1000);
	cudaMalloc((void**) &__SMC_newChunkSeq, sizeof(int)*12);


	if (debug) printf("In schedule:		TBD - Cuda Memcpy for Bag in GPU.\n");
	// copying data from cpu to gpu
	// cudaMemcpy(d_Bag, Bag, sizeof(Bag_elem)*6*1000, cudaMemcpyHostToDevice);
	cudaMemcpy(d_Bag_1d, Bag_ptr, sizeof(Bag_elem)*6*1000, cudaMemcpyHostToDevice);

	for (i = 0; i < 6; i++)
	{
		cudaMalloc((void**) &(d_array), sizeof(int)*6);

		cudaMemcpy(d_array, Bag_ptr[i].arg, sizeof(int) * 6, cudaMemcpyHostToDevice);

		Bag_ptr[i].arg = d_array;
	}
	// for(i = 0; i < 6; i++)
	// {	
	// 	temp = (int *)((Bag_ptr[1000 * i]).arg);
	// 	cudaMemcpy(d_Bag_1d[1000 * i].arg, Bag_ptr[1000 * i].arg, sizeof(int) * 6, cudaMemcpyHostToDevice);
	// }


	cudaMemcpy(__SMC_chunkCount, SMC_workerCount, sizeof(int)*6, cudaMemcpyHostToDevice);
	cudaMemcpy(__SMC_newChunkSeq, jobChunkArray, sizeof(int)*12, cudaMemcpyHostToDevice);

	//cudaMemcpy(d_Bag, Bag, sizeof(Bag_elem)*6*1000, cudaMemcpyHostToDevice);


	if (debug) printf("In schedule:		SMC BEGIN.\n");

	if (debug)
	{
		int i;
		for (i = 0; i < 6; i++)
			printf("%d ",SMC_workerCount[i]);
		printf("\n");
	}


	// unsigned int __SMC_workersNeeded = 2;  // Need to be made dynamic based on user input.
	// unsigned int * __SMC_newChunkSeq = jobChunkArray;
	// unsigned int * __SMC_workerCount = SMC_workerCount; // Array of counter for blocks created for each SM.

	if (debug) printf("In schedule:		Kernel Call.\n");

//unsigned int * __SMC_chunkCount, unsigned int * __SMC_newChunkSeq, unsigned int __SMC_chunksPerSM
	// persistent_func <<< n, m >>> (d_Bag, d_user_func, __SMC_chunkCount, __SMC_newChunkSeq, 2);
	persistent_func <<< n, m >>> (Bag_ptr, d_user_func, __SMC_chunkCount, __SMC_newChunkSeq, 2);

	cudaDeviceSynchronize();
	cudaThreadSynchronize();

	if (debug) printf("In schedule:		Kernel Call Ends. Do CudaMemCpy.\n");

	cudaMemcpy(h_Bag_1d, d_Bag_1d, sizeof(Bag_elem)*6*1000, cudaMemcpyDeviceToHost);

	if (debug) printf("In schedule:		Results copied into the CPU. Time for printing.\n");

	int *temp_ans;
	for(i = 0; i < 6; i++)
	{
		temp_ans = (int *)h_Bag_1d[i * 1000].arg;
		for (y = 0; y < length_of_chunk; y++)
			printf("%d ", temp_ans[y]);
		printf("\n");
	}
	cudaFree(d_Bag_1d);

}

