#include <stdio.h>

typedef void* (*func)(void *);

typedef struct stest
{
	func f; /* data */
	void* arg;
} svar;

void *ftest(void * param)
{
	printf("\nhello\n");
}

int main()
{
	svar ss;

	void* p;
	ss.arg = p;
	ss.f = ftest;

	ss.f(ss.arg);

	return 0;
}