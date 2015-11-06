#include <stdio.h>

typedef void* (*func)(void *);

typedef struct s 
{
	func y;
} ss;

void* test(void* p)
{
	printf("\nhello!\n");
}

int main()
{
	ss var;
	var.y = test;
	void *p;
	var.y(p);

	return 0;
}