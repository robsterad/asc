#include <stdio.h>
#include <stdlib.h>

#define NUM_ELEMENTS 16

__device__ void swap(int *a, int *b) {
  int temp = *a;
  *a = *b;
  *b = temp;
}

// TODO 2: define parameters
__global__ void oddEvenTranspositionSort() {
  int tid = blockIdx.x * blockDim.x + threadIdx.x;

  for (int i = 0; i < n; i++) {
    if (i % 2 == 0) {  // Even phase
                       // TODO 2: Compare and swap elements if thread id is even
    } else {           // Odd phase
                       // TODO 3: Compare and swap elements if thread id is odd
    }
    // TODO 4: Sync threads
  }
}

void generateData(int *data, int size) {
  srand(time(0));

  for (int i = 0; i < size; i++) {
    data[i] = rand() % 14 + 1;
  }
}

int main() {
  int *array = NULL;
  array = (int *)malloc(NUM_ELEMENTS * sizeof(int));
  generateData(array, NUM_ELEMENTS);

  printf("Original Array: ");
  for (int i = 0; i < NUM_ELEMENTS; i++) {
    printf("%d ", array[i]);
  }
  printf("\n");

  int *d_array;
  // TODO 0: Allocate device array and copy host elements to it

  // TODO 1: Calculate blocks_no and block_size
  oddEvenTranspositionSort<<<blocks_no, block_size>>>(d_array, NUM_ELEMENTS);
  cudaDeviceSynchronize();

  cudaMemcpy(array, d_array, NUM_ELEMENTS * sizeof(int),
             cudaMemcpyDeviceToHost);
  cudaFree(d_array);

  printf("Sorted Array: ");
  for (int i = 0; i < NUM_ELEMENTS; i++) {
    printf("%d ", array[i]);
  }
  printf("\n");

  free(array);
  return 0;
}
