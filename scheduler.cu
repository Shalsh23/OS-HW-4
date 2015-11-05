#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

unsigned int* __SMC_buildChunkSeq()
{

}

#define __SMC_init  \
unsigned int * __SMC_workersNeeded = 2; \ //__SMC_numNeeded();  \
unsigned int * __SMC_newChunkSeq = __SMC_buildChunkSeq();  \
unsigned int * __SMC_workerCount = __SMC_initiateArray();

#define __SMC_Begin  \
__shared int __SMC_workingCTAs;  \
__SMC_getSMid;  \
if (offsetInCTA == 0)  \
    __SMC_workingCTAs = atomicInc(&__SMC_workerCount[__SMC_smid], INT_MAX);  \
__syncthreads();  \
if (__SMCS_workingCTAs >= __SMC_workersNeeded)  \
    return;  \
int __SMC_chunksPerCTA = \
    __SMC_chunksPerSM / __SMC_workersNeeded; \
int __SMC_startChunkIDidx = __SMC_smid * __SMC_chunksPerSM + \
    __SMC_workingCTAs * __SMC_chunksPerCTA;  \
for (int __SMC_chunkIDidx = __SMC_startChunkIDidx; \
    __SMC_chunkIDidx < __SMC_startChunkIDidx + \
        __SMC_chunksPerCTA; \
    __SMC_chunkDidx ++) {  \
    __SMC_chunkID = __SMC_newChunkSeq[__SMC_chunkIDidx]};

#define __SMC_End  }

#define __SMC_getSMid  \
uint __SMC_smid;  \
 asm("mov.u32 %0, %smid;" : "=r"(__SMC_smid) );



typedef struct bag_elem
{
	void* (*func)(void*);
	void* arg;
} Bag_elem;

Bag_elem Bag[6][1000];

int sm_index[] = {0,0,0,0,0,0}; // index for 6 SMs

int jobchunk_id = 0;

int taskAdd(void* (*func)(void*), void* arg, int sm)
{
	Bag[sm_index[sm]][sm].func = func;
	Bag[sm_index[sm]][sm].arg = arg;
	int retval = jobchunk_id;
	jobchunk_id++;
	return retval;
}

__global__ persistent_func(Bag_elem* Bag)
{

}

extern "C" void schedule()
{

	// allocating memory on cuda for cpu variables
	Bag_elem* d_Bag;
	cudaMalloc((void**) &d_Bag, sizeof(Bag_elem)*6*1000);

	// copying data from cpu to gpu
	cudaMemcpy(d_Bag, Bag, sizeof(Bag_elem)*6*1000, cudaMemcpyHostToDevice);

	__SMC_init;

}

