#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>


unsigned int jobChunkArray[1000];
int jobChunkCounter = 0;
unsigned int SMC_workerCount[] = {0, 0, 0, 0, 0, 0}; // Array of counter for blocks created for each SM.

// __device__ __host__ void square(long int * d_array_in, long int * d_array_out, int length)//, unsigned int * __SMC_chunkCount, unsigned int * __SMC_newChunkSeq, unsigned int __SMC_chunksPerSM)
// {
// 	// __SMC_Begin
// 	int x = threadIdx.x + blockIdx.x * blockDim.x;
// 	//printf("The value of x is %d \n",x);
// 	//printf("The value of threadIdx.x is %d\n",threadIdx.x);
//       //  printf("The value of blockIdx.x is %d\n", blockIdx.x);
// 	//printf("The value of blockIdx.x is %d\n",blockDim.x);
// 	if (x > length)
// 		return;
//     int f = d_array_in[x];
//     d_array_out[x] = f * f;
//     // __SMC_End
// }

// #define __SMC_init  \
// int __SMC_workersNeeded = 2; \ //__SMC_numNeeded();  // Need to be made dynamic based on user input.
// int * __SMC_newChunkSeq = jobChunkArray;  \
// int * __SMC_workerCount = SMC_workerCount; // Array of counter for blocks created for each SM.

// #define __SMC_Begin  \
// __shared int __SMC_workingCTAs;  \
// __SMC_getSMid;  \
// if (offsetInCTA == 0)  \
//     __SMC_workingCTAs = atomicInc(&__SMC_workerCount[__SMC_smid], INT_MAX);  \
// __syncthreads();  \
// if (__SMCS_workingCTAs >= __SMC_workersNeeded)  \
//     return;  \
// int __SMC_chunksPerCTA = \
//     __SMC_chunksPerSM / __SMC_workersNeeded; \
// int __SMC_startChunkIDidx = __SMC_smid * __SMC_chunksPerSM + \
//     __SMC_workingCTAs * __SMC_chunksPerCTA;  \
// for (int __SMC_chunkIDidx = __SMC_startChunkIDidx; \
//     __SMC_chunkIDidx < __SMC_startChunkIDidx + \
//         __SMC_chunksPerCTA; \
//     __SMC_chunkDidx ++) {  \
//     __SMC_chunkID = __SMC_newChunkSeq[__SMC_chunkIDidx]};

// #define __SMC_End  }

// #define __SMC_getSMid  \
// uint __SMC_smid;  \
//  asm("mov.u32 %0, %smid;" : "=r"(__SMC_smid) );

__device__ void * square(void *arr)
{
	// __SMC_Begin
	//printf("The value of x is %d \n",x);
	//printf("The value of threadIdx.x is %d\n",threadIdx.x);
      //  printf("The value of blockIdx.x is %d\n", blockIdx.x);
	//printf("The value of blockIdx.x is %d\n",blockDim.x);
	

	//if (x > length)
	//	return;
	int* array = (int*) arr;
    int f = array[threadIdx.x];
    array[threadIdx.x] = f * f;
    return (void *)array;
    // __SMC_End
}

typedef void* (*func)(void *);

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

int taskAdd(void* (*func)(void*), void* arg, int sm)
{
	(Bag[sm_index[sm]][sm]).y = square;
	(Bag[sm_index[sm]][sm]).arg = arg;
	int retval = jobchunk_id;
	jobchunk_id++;
	jobChunkArray[jobChunkCounter] = retval; // Doubtful.
	jobChunkCounter++;
	return retval;
}


__global__ void persistent_func(Bag_elem* Bag, unsigned int * __SMC_chunkCount, unsigned int * __SMC_newChunkSeq, unsigned int __SMC_chunksPerSM)
{
	__shared__ int __SMC_workingCTAs;
	int __SMC_chunkID;
	uint __SMC_smid;  \
 	asm("mov.u32 %0, %smid;" : "=r"(__SMC_smid) );
	//if (offsetInCTA == 0)
    __SMC_workingCTAs = atomicInc(&__SMC_chunkCount[__SMC_smid], INT_MAX);
	__syncthreads(); 
	if (__SMC_workingCTAs >= __SMC_chunksPerSM)
    return;
	int __SMC_chunksPerCTA = __SMC_chunksPerSM / __SMC_chunksPerSM; 
	int __SMC_startChunkIDidx = __SMC_smid * __SMC_chunksPerSM + __SMC_workingCTAs * __SMC_chunksPerCTA;
	for (int __SMC_chunkIDidx = __SMC_startChunkIDidx; __SMC_chunkIDidx < __SMC_startChunkIDidx + __SMC_chunksPerCTA; __SMC_chunkIDidx ++) { 
    __SMC_chunkID = __SMC_newChunkSeq[__SMC_chunkIDidx];

	int x = threadIdx.x + __SMC_chunkID * blockDim.x;

	// (Bag[__SMC_smid][x])->y((Bag[__SMC_smid][x])->arg);
	
	}


}

extern "C" void schedule(int n, int m)
{
	// allocating memory on cuda for cpu variables
	Bag_elem* d_Bag;
	cudaMalloc((void**) &d_Bag, sizeof(Bag_elem)*6*1000);

	// copying data from cpu to gpu
	cudaMemcpy(d_Bag, Bag, sizeof(Bag_elem)*6*1000, cudaMemcpyHostToDevice);

	unsigned int __SMC_workersNeeded = 2;  //__SMC_numNeeded();  // Need to be made dynamic based on user input.
	unsigned int * __SMC_newChunkSeq = jobChunkArray;
	unsigned int * __SMC_workerCount = SMC_workerCount; // Array of counter for blocks created for each SM.

	persistent_func <<< n, m >>> (d_Bag, __SMC_workerCount, __SMC_newChunkSeq, __SMC_workersNeeded);

	cudaMemcpyAsync(Bag, d_Bag, sizeof(Bag_elem)*6*1000, cudaMemcpyDeviceToHost);

	int i, y;
	for(i = 0; i < 6; i++)
	{
		for (y = 0; y < length_of_chunk; y++)
			// printf("%d ", (Bag[0][i].arg)[y]);
		printf("\n");
	}
	cudaFree(d_Bag);

}

