/*
 * Tema 2 ASC
 * 2024 Spring
 */
#include "utils.h"
#include <cblas.h>

/* 
 * Add your BLAS implementation here
 */
double* my_solver(int N, double *A, double *B, double *x) {

	double *C = (double *) malloc(N * N * 8UL);
	double *D = (double *) malloc(N * N * 8UL);
	double *y = (double *) malloc(N * 8UL);

	// C = 1.0 * A^t * B + 0.0 * C
	cblas_dgemm(CblasRowMajor, 
            CblasTrans,    // transpunem matricea A
            CblasNoTrans,  // matricea B ramane la fel
            N, N, N,       // dimensiuni
            1.0,           // alpha
            A, N,          // matricea A si leading dimension (N)
            B, N,          // matricea B si leading dimension (N)
            0.0,           // beta
            C, N);         // matricea rezultat C si leading dimension (N)

	// D = 1.0 * C * C^t + 0.0 * D
	cblas_dsyrk(CblasRowMajor, 
            CblasUpper,    // doar triunghiul superior
            CblasNoTrans,  // C pur
            N, N,          // dimensiuni
            1.0,           // alpha
            C, N,          // matricea C si ldc
            0.0,           // beta
            D, N);         // matricea rezultat D si ldd

	int i = 0;
	while (i < N) {
		// y = 1.0 * D * linie_C + 1.0 * y 
		cblas_dsymv(CblasRowMajor, 
            CblasUpper,    // doar triunghiul superior
            N,             // dimenisunea
            1.0,           // alpha
            D, N,          // matricea simetrica D
            &C[i * N], 1,  // adresa de inceput a liniei i din C, stride = 1
            1.0,           // beta
            y, 1);         // vectorul destinatie, stride = 1

		i++;
	}

	// y = 1.0 * x + y
	cblas_daxpy(N,  	// numarul de elemente din vector
            1.0,    	// alpha
            x, 1,   	// vectorul x si distanta intre elemente
            y, 1);  	// vectorul y si distanta intre elemente

	free(C);
	free(D);
	return y;
}
