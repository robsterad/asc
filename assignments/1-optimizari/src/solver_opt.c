/*
 * Tema 2 ASC
 * 2026 Spring
 */
#include "utils.h"


#define B_SIZE 40 // dimensiunea blocului de cache (N e multiplu de 40)


void multiply_At_B_opt(int N, double *A, double *B, double *C) {
    for (int i_b = 0; i_b < N; i_b += B_SIZE) {
        for (int k_b = 0; k_b < N; k_b += B_SIZE) {
            for (int j_b = 0; j_b < N; j_b += B_SIZE) {
                
                for (int i = i_b; i < i_b + B_SIZE; i++) {
                    double *p_C = &C[i * N + j_b];
    
                    for (int j = 0; j < B_SIZE; j += 8) {
                        // unrolling
                        register double c0 = p_C[j], c1 = p_C[j+1], c2 = p_C[j+2], c3 = p_C[j+3];
                        register double c4=p_C[j+4], c5=p_C[j+5], c6=p_C[j+6], c7=p_C[j+7];
                        
                        for (int k = k_b; k < k_b + B_SIZE; k += 2) {
                            register double Ak0 = A[k * N + i];
                            register double Ak1 = A[(k+1) * N + i];
                            
                            double *p_B0 = &B[k * N + j_b + j];
                            double *p_B1 = &B[(k+1) * N + j_b + j];
                            
                            c0 += Ak0 * p_B0[0] + Ak1 * p_B1[0];
                            c1 += Ak0 * p_B0[1] + Ak1 * p_B1[1];
                            c2 += Ak0 * p_B0[2] + Ak1 * p_B1[2];
                            c3 += Ak0 * p_B0[3] + Ak1 * p_B1[3];

                            c4 += Ak0 * p_B0[4] + Ak1 * p_B1[4];
                            c5 += Ak0 * p_B0[5] + Ak1 * p_B1[5];
                            c6 += Ak0 * p_B0[6] + Ak1 * p_B1[6];
                            c7 += Ak0 * p_B0[7] + Ak1 * p_B1[7];
                        }
                        
                        p_C[j]=c0; p_C[j+1]=c1; p_C[j+2]=c2; p_C[j+3]=c3;
                        p_C[j+4]=c4; p_C[j+5]=c5; p_C[j+6]=c6; p_C[j+7]=c7;
                    }
                }
            }
        }
    }
}

void multiply_C_Ct_opt(int N, double *C, double *D) {
    for (int i_b = 0; i_b < N; i_b += B_SIZE) {
        for (int j_b = i_b; j_b < N; j_b += B_SIZE) {
            for (int k_b = 0; k_b < N; k_b += B_SIZE) {
                
                for (int i = i_b; i < i_b + B_SIZE; i++) {
                    int j_start = (i_b == j_b) ? i : j_b;
                    double *p_Ci = &C[i * N + k_b];
                    double *p_D_row = &D[i * N];  // pointer la randul din D

                    for (int j = j_start; j < j_b + B_SIZE; j++) {
                        register double sum = 0.0; 
                        double *p_Cj = &C[j * N + k_b];

                        // unroll x4
                        register double sum0 = 0.0, sum1 = 0.0, sum2 = 0.0, sum3 = 0.0;
                        for (int k = 0; k < B_SIZE; k += 4) {
                            sum0 += p_Ci[k]   * p_Cj[k];
                            sum1 += p_Ci[k+1] * p_Cj[k+1];
                            sum2 += p_Ci[k+2] * p_Cj[k+2];
                            sum3 += p_Ci[k+3] * p_Cj[k+3];
                        }
                        sum = sum0 + sum1 + sum2 + sum3;
                        
                        p_D_row[j] += sum;  // in loc de D[i*N+j]
                    }
                }
            }
        }
    }

    // copiem triunghiul superior in cel inferior
    for (int i = 0; i < N; i++) {
        double *src = &D[i * N + i + 1];
        for (int j = i + 1; j < N; j++) {
            D[j * N + i] = src[j - i - 1];
        }
    }
}

void update_y(int N, double *D, double *C, double *y, double *x) {
    // iterator peste y
    for (int r = 0; r < N; r++) {
        
        double sum_y = 0.0;
        
        // pointer la linia r din D
        double *p_Dr = &D[r * N];
        
        // iterator pentru linia din C
        for (int i = 0; i < N; i++) {
            
            double *p_Ci = &C[i * N];
            
            register double dot = 0.0;
            
            // unroll x8
            int c;
            for (c = 0; c <= N - 8; c += 8) {
                double d0 = p_Dr[c]   * p_Ci[c];
                double d1 = p_Dr[c+1] * p_Ci[c+1];
                double d2 = p_Dr[c+2] * p_Ci[c+2];
                double d3 = p_Dr[c+3] * p_Ci[c+3];
                double d4 = p_Dr[c+4] * p_Ci[c+4];
                double d5 = p_Dr[c+5] * p_Ci[c+5];
                double d6 = p_Dr[c+6] * p_Ci[c+6];
                double d7 = p_Dr[c+7] * p_Ci[c+7];
                
                dot += (d0 + d1) + (d2 + d3) + (d4 + d5) + (d6 + d7);
            }
            
            // cleanup pentru ultimele elemente (daca N nu e multiplu de 8)
            for (; c < N; c++) {
                dot += p_Dr[c] * p_Ci[c];
            }
            
            sum_y += dot;
        }
        
        y[r] = sum_y + x[r];
    }
}

/*
 * Add your optimized implementation here
 */
double* my_solver(int N, double *A, double *B, double *x) {
	double *C = (double *) calloc(N * N, 8UL);
	double *D = (double *) calloc(N * N, 8UL);
	double *y = (double *) calloc(N, 8UL);
	
	multiply_At_B_opt(N, A, B, C);
	multiply_C_Ct_opt(N, C, D);
	update_y(N, D, C, y, x);

	free(C);
	free(D);

	return y;
}
