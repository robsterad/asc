#include <stdio.h>

#define OPS_SCALE (2048)

#define KERNEL_OPS_COUNT (2 * OPS_SCALE)

__global__ void kernel_gflops(float *a, float *b) {
  int idx = threadIdx.x;

  a[idx] = b[idx];  // 1 LOAD + 1 STORE, 0 FP32 ops, 0 FP64 ops

  /**
   * ~TODO~
   * Measure FP32 GFlops and FP64 Gflops of the device
   * Try and achieve close to theoretical peak performance
   */
}

void fill_array_int(int *a, int N) {
  for (int i = 0; i < N; ++i) {
    a[i] = i;
  }
}

void fill_array_float(float *a, int N) {
  for (int i = 0; i < N; ++i) {
    a[i] = (float)i;
  }
}

void fill_array_random(float *a, int N) {
  for (int i = 0; i < N; ++i) {
    a[i] = (float)rand() / RAND_MAX;
  }
}

int main(void) {
  int nDevices;

  // Get the number of CUDA-capable GPU(s)
  cudaGetDeviceCount(&nDevices);
  cudaSetDevice(0);

  float *device_a = 0;
  float *device_b = 0;
  float *host_a = 0;
  float *host_b = 0;

  int size = OPS_SCALE * OPS_SCALE;

  // Arrays a and b are of size N * N
  host_a = (float *)malloc(size * sizeof(float));
  host_b = (float *)malloc(size * sizeof(float));
  cudaMalloc((void **)&device_a, size * sizeof(float));
  cudaMalloc((void **)&device_b, size * sizeof(float));

  if (host_a == 0 || host_b == 0 || device_a == 0 || device_b == 0) {
    printf("[HOST] Couldn't allocate memory\n");
    return 1;
  }

  // Populate array a randomly
  fill_array_random(host_a, size);
  cudaMemcpy(device_a, host_a, size * sizeof(float), cudaMemcpyHostToDevice);

  cudaEvent_t start, stop;

  /**
   * ~TODO~
   * Create two cuda events (start and stop)
   * by using the cudaEventCreate function.
   */
  kernel_gflops<<<size / 512, 512>>>(device_a, device_b);
  cudaEventSynchronize(stop);

  float ms = 0;
  float seconds = ms / pow((float)10, 3);

  /**
   *
   * Set num_ops to the number of floating point operations
   * done in the kernel multiplied with the size of the matrix.
   */

  double num_ops = (double)KERNEL_OPS_COUNT * size;
  double gflops = (double)num_ops / seconds / 1e+9;
  printf("GFLOPS: %.2f\n", gflops);

  free(host_a);
  free(host_b);
  cudaFree(device_a);
  cudaFree(device_b);

  return 0;
}
