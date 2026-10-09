#include <stdio.h>

#include "../utils.h"

#define NUM_ELEM (16 * 1024 * 1024)

__global__ void kernel_compute(float* a, float* b, int N) {
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  a[idx] = sin(b[idx]) * (1 - cos(b[idx]));
}

int compute_UnifiedMem(void) {
  float* host_a = 0;
  float* host_b = 0;

  // TODO-unified: Alocare memorie unificata

  if (host_a == 0 || host_b == 0) {
    printf("[HOST] Couldn't allocate memory\n");
    return 1;
  }

  fill_array_random(host_b, NUM_ELEM);

  kernel_compute<<<NUM_ELEM / 256, 256>>>(host_a, host_b, NUM_ELEM);

  // TODO print first partial results

  // TODO-unified: Dealocare memorie unificata

  return 0;
}

int main(void) { compute_UnifiedMem(); }
