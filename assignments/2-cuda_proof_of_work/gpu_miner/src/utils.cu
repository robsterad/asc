#include <stdio.h>
#include <stdint.h>
#include "utils.h"
#include <string.h>
#include <stdlib.h>
#include <cuda_runtime.h>

// CUDA sprintf alternative for nonce finding. Converts integer to its string representation. Returns string's length.
__device__ inline int intToString(uint64_t num, char* out) {
    if (num == 0) {
        out[0] = '0';
        out[1] = '\0'; 
        return 1;
    }

    int i = 0;
    while (num != 0) {
        int digit = num % 10;
        num /= 10;
        out[i++] = '0' + digit;
    }

    // Reverse the string
    for (int j = 0; j < i / 2; j++) {
        char temp = out[j];
        out[j] = out[i - j - 1];
        out[i - j - 1] = temp;
    }
    out[i] = '\0';
    return i;
}

// CUDA strlen implementation.
__host__ __device__ size_t d_strlen(const char *str) {
    size_t len = 0;
    while (str[len] != '\0') {
        len++;
    }
    return len;
}

// CUDA strcpy implementation.
__device__ void d_strcpy(char *dest, const char *src){
    int i = 0;
    while ((dest[i] = src[i]) != '\0') {
        i++;
    }
}

// CUDA strcat implementation.
__device__ void d_strcat(char *dest, const char *src){
    while (*dest != '\0') {
        dest++;
    }
    while (*src != '\0') {
        *dest = *src;
        dest++;
        src++;
    }
    *dest = '\0';
}

// Compute SHA256 and convert to hex
__host__ __device__ void apply_sha256(const BYTE *input, size_t length, BYTE *output) {
    SHA256_CTX ctx;
    BYTE buf[SHA256_BLOCK_SIZE];
    const char hex_chars[] = "0123456789abcdef";

    sha256_init(&ctx);
    sha256_update(&ctx, input, length);
    sha256_final(&ctx, buf);

    for (size_t i = 0; i < SHA256_BLOCK_SIZE; i++) {
        output[i * 2]     = hex_chars[(buf[i] >> 4) & 0x0F];
        output[i * 2 + 1] = hex_chars[buf[i] & 0x0F];
    }
}

__device__ void apply_sha256_from_ctx(SHA256_CTX ctx, const BYTE *suffix, size_t suffix_len, BYTE *output) {
    BYTE buf[SHA256_BLOCK_SIZE];
    const char hex_chars[] = "0123456789abcdef";

    sha256_update(&ctx, suffix, suffix_len);
    sha256_final(&ctx, buf);

    for (size_t i = 0; i < SHA256_BLOCK_SIZE; i++) {
        output[i * 2]     = hex_chars[(buf[i] >> 4) & 0x0F];
        output[i * 2 + 1] = hex_chars[buf[i] & 0x0F];
    }
}

// Compare two hashes
__host__ __device__ inline int compare_hashes(BYTE* hash1, BYTE* hash2) {
    for (int i = 0; i < SHA256_HASH_SIZE - 1; i++) {
        if (hash1[i] < hash2[i]) {
            return -1; // hash1 is lower
        } else if (hash1[i] > hash2[i]) {
            return 1; // hash2 is lower
        }
    }
    return 0; // hashes are equal
}

__global__ void kernel_hash_transactions(int transaction_size, const BYTE *transactions, BYTE *hashes, int n)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= n)
        return;
    
    apply_sha256(transactions + idx * transaction_size, transaction_size - 1, hashes + idx * SHA256_HASH_SIZE);
}

__global__ void kernel_merge_hashes(const BYTE *hashes_in, BYTE *hashes_out, int n)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int new_n = (n + 1) / 2;
    if (idx >= new_n)
        return;

    int left = idx * 2;
    int right;
    if (left + 1 < n) {
        right = left + 1;
    } else { // duplicate last one if there is no pair
        right = left;
    }

    BYTE combined[128];
    int left_idx = left * SHA256_HASH_SIZE;
    int right_idx = right * SHA256_HASH_SIZE;

    for (int i = 0; i < 64; i++) {
        combined[i] = hashes_in[left_idx + i];
        combined[64 + i] = hashes_in[right_idx + i];
    }

    apply_sha256(combined, 128, hashes_out + idx * SHA256_HASH_SIZE);
}

// TODO 1: Implement this function in CUDA
void construct_merkle_root(int transaction_size, BYTE *transactions, int max_transactions_in_a_block, int n, BYTE merkle_root[SHA256_HASH_SIZE]) {
    
    const int THREADS = 256;

    static BYTE *d_transactions = NULL;
    static BYTE *d_a = NULL;
    static BYTE *d_b = NULL;
    if (d_transactions == NULL) {
        cudaMalloc(&d_transactions, (size_t) n * transaction_size);
        cudaMalloc(&d_a, (size_t) max_transactions_in_a_block * SHA256_HASH_SIZE);
        cudaMalloc(&d_b, (size_t) max_transactions_in_a_block * SHA256_HASH_SIZE);
    }

    cudaMemcpy(d_transactions, transactions, (size_t)n * transaction_size, cudaMemcpyHostToDevice);

    // hash every transaction in parallel
    kernel_hash_transactions<<<(n + THREADS - 1) / THREADS, THREADS>>>(transaction_size, d_transactions, d_a, n);
    cudaDeviceSynchronize();

    // half the nr of hashes every iteration
    int cur_n = n;
    while (cur_n > 1) {
        int new_n  = (cur_n + 1) / 2;
        int blocks = (new_n + THREADS - 1) / THREADS;
        kernel_merge_hashes<<<blocks, THREADS>>>(d_a, d_b, cur_n);
        cudaDeviceSynchronize();

        // newly calculated hashes (d_b) become new entries (d_a) in the next step
        BYTE *tmp = d_a; d_a = d_b; d_b = tmp;
        cur_n = new_n;
    }

    cudaMemcpy(merkle_root, d_a, SHA256_HASH_SIZE, cudaMemcpyDeviceToHost);

    // cudaFree(d_transactions);
    // cudaFree(d_a);
    // cudaFree(d_b);

}


__global__ void kernel_find_nonce(BYTE *difficulty, uint32_t max_nonce, SHA256_CTX base_ctx, BYTE *out_hash, uint32_t *out_nonce, int *d_found)
{
    int stride = blockDim.x * gridDim.x; // 256 * 1024
    int start_idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    for (uint32_t nonce = start_idx; nonce < max_nonce; nonce += stride) {
        
        if (*(volatile int*)d_found != 0) return;

        char nonce_str[NONCE_SIZE];
        int nonce_len = intToString((uint64_t)nonce, nonce_str);

        BYTE hash[SHA256_HASH_SIZE];
        
        apply_sha256_from_ctx(base_ctx, (const BYTE *)nonce_str, (size_t)nonce_len, hash);

        if (compare_hashes(hash, difficulty) <= 0) {
            if (atomicCAS(d_found, 0, 1) == 0) {
                *out_nonce = nonce;
                for (int i = 0; i < SHA256_HASH_SIZE; i++) {
                    out_hash[i] = hash[i];
                }
            }
            return;
        }
    }
}

int find_nonce(BYTE *difficulty, uint32_t max_nonce, BYTE *block_content, size_t current_length, BYTE *block_hash, uint32_t *valid_nonce) {
    const int THREADS = 256;
    const int BLOCKS = 1024; // 262144 threads

    SHA256_CTX base_ctx;
    sha256_init(&base_ctx);
    sha256_update(&base_ctx, block_content, current_length);

    static BYTE *d_difficulty = NULL;
    static BYTE *d_hash = NULL;
    static uint32_t *d_nonce = NULL;
    static int *d_found = NULL;

    if (d_difficulty == NULL) {
        cudaMalloc(&d_difficulty, SHA256_HASH_SIZE);
        cudaMalloc(&d_hash, SHA256_HASH_SIZE);
        cudaMalloc(&d_nonce, sizeof(uint32_t));
        cudaMalloc(&d_found, sizeof(int));
    }

    cudaMemcpy(d_difficulty, difficulty, SHA256_HASH_SIZE, cudaMemcpyHostToDevice);
    cudaMemset(d_found, 0, sizeof(int));

    kernel_find_nonce<<<BLOCKS, THREADS>>>(d_difficulty, max_nonce, base_ctx, d_hash, d_nonce, d_found);
    cudaDeviceSynchronize();

    int found = 0;
    cudaMemcpy(&found, d_found, sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(block_hash, d_hash, SHA256_HASH_SIZE, cudaMemcpyDeviceToHost);
    cudaMemcpy(valid_nonce, d_nonce, sizeof(uint32_t), cudaMemcpyDeviceToHost);

    if (found)
        return 0;
    return 1;
}

__global__ void dummy_kernel() {}

// Warm-up function
void warm_up_gpu() {
    BYTE *dummy_data;
    cudaMalloc((void **)&dummy_data, 256);
    dummy_kernel<<<1, 1>>>();
    cudaDeviceSynchronize();
    cudaFree(dummy_data);
}
