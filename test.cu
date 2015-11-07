#include <stdio.h>



typedef float (*op_func_t) (float, float);



__device__ float add_func (float x, float y)

{

    return x + y;

}



__device__ float mul_func (float x, float y)

{

    return x * y;

}



// Static pointers to device functions

__device__ op_func_t p_add_func = add_func;

__device__ op_func_t p_mul_func = mul_func;



__global__ void kernel( op_func_t op )

{

        printf("Result: %f\n", ( *op )( 1.0, 2.0 ) );

}



int main()

{



    op_func_t h_add_func;

    op_func_t h_mul_func;



    // Copy device function pointer to host side

    cudaMemcpyFromSymbol( &h_mul_func, p_mul_func, sizeof( op_func_t ) );

    cudaMemcpyFromSymbol( &h_add_func, p_add_func, sizeof( op_func_t ) );



    op_func_t d_myfunc = h_mul_func;



    kernel<<<1,1>>>( d_myfunc );



    cudaThreadSynchronize();



    return EXIT_SUCCESS;

}