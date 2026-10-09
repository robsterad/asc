#include <stdio.h>
#include <math.h>
#include "utils.h"

// TODO 6: Write the code to add the two arrays element by element and 
// store the result in another array
__global__ void add_arrays(const float *a, const float *b, float *c, int N) {
}

int main(void) {
    cudaSetDevice(0);
    int N = 1 << 20;

    float *host_array_a = 0;
    float *host_array_b = 0;
    float *host_array_c = 0;

    float *device_array_a = 0;
    float *device_array_b = 0;
    float *device_array_c = 0;

    // TODO 1: Allocate the host's arrays

    // TODO 2: Allocate the device's arrays

    // TODO 3: Check for allocation errors


    // TODO 4: Fill array with values; use fill_array_float to fill
    // host_array_a and fill_array_random to fill host_array_b. Each
    // function has the signature (float *a, int n), where n = the size.

    // TODO 5: Copy the host's arrays to device

    // TODO 6: Execute the kernel, calculating first the grid size
    // and the amount of threads in each block from the grid

    // TODO 7: Copy back the results and then uncomment the checking function


    //check_task_3(host_array_a, host_array_b, host_array_c, N);

    // TODO 8: Free the memory

    return 0;
}