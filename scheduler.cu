#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

typedef struct bag_elem
{
	void* (*func)(void*);
	void* arg;
} Bag_elem;

Bag_elem Bag[6][1000];

int sm_index[] = {0,0,0,0,0,0}; // index for 6 SMs

int taskAdd(void* (*func)(void*), void* arg, int sm)
{
	Bag[sm][sm_index[sm]].func = func;
	Bag[sm][sm_index[sm]].arg = arg;
}

extern "C" void schedule()
{

}

