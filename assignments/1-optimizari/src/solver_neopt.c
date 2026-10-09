/*
 * Tema 2 ASC
 * 2026 Spring
 */
#include "utils.h"


// Calculeaza C = A^t * B
void multiply_At_B(int N, double *A, double *B, double *C) {

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            double sum = 0.0;
            
            for (int k = 0; k < N; k++) {
                sum += A[k * N + i] * B[k * N + j];
            }

            C[i * N + j] = sum;
        }
    }
}

// Calculeaza D = C * C^t, D simetrica
void multiply_C_Ct_sym(int N, double *C, double *D) {

    for (int i = 0; i < N; i++) {
        for (int j = i; j < N; j++) { // doar triunghiul superior
            double sum = 0.0;
            for (int k = 0; k < N; k++) {
                sum += C[i * N + k] * C[j * N + k]; 
            }
            D[i * N + j] = sum;
            // fill toata matricea
            D[j * N + i] = sum; 
        }
    }
}

// Calculeaza y += D * linie(C, i)
void update_y(int N, double *D, double *C, double *y, int i) {
    double *linie_i_C = &C[i * N];

    for (int row = 0; row < N; row++) {
        double sum = 0.0;
        for (int col = 0; col < N; col++) {
            sum += D[row * N + col] * linie_i_C[col];
        }
        y[row] += sum;
    }
}


void add_y_x(int N, double *y, double *x) {
    for (int i = 0; i < N; i++) {
        y[i] += x[i];
    }
}

/*
 * Add your unoptimized implementation here
 */
double* my_solver(int N, double *A, double *B, double *x) {
	double *C = (double *) calloc(N * N, 8UL);
	double *D = (double *) calloc(N * N, 8UL);
	double *y = (double *) calloc(N, 8UL);

	multiply_At_B(N, A, B, C);
	multiply_C_Ct_sym(N, C, D);

	int i = 0;
	while (i < N) {
		update_y(N, D, C, y, i);
		i++;
	}
    add_y_x(N, y, x);

	free(C);
	free(D);

	return y;
	
}
