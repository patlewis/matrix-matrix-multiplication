#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <unistd.h>
#include "timer.h"

char* usage = "Usage: ./a.out <num_procs>\n where <num_procs> is the number of processors to use.  Using this option is not mandatory.\n";

int main(int argc, char* argv[])
{
    /* Preprocessor Definitions */
#define amat(I,J) A[I + n*J]
#define bmat(I,J) B[I + n*J]
#define cmat(I,J) C[I + n*J]
//#define DEBUG 1

    /* Variables */
    int     num_procs;              //total number of processors    
    int     proc_num;               //this processor's rank
    int     n;                      //size of the matrix we will use
    double  start, finish;          //used for timing matrix computations
    char    hostname[20];           //hostname of this machine (for debug)
    double  *A, *B, *C;             //the matrices we'll use

    /* Initializations */
    MPI_Init(NULL, NULL);
    MPI_Comm_size(MPI_COMM_WORLD, &num_procs);
    MPI_Comm_rank(MPI_COMM_WORLD, &proc_num);
    hostname[19] = '\0';
    gethostname(hostname, 19);
#   ifdef DEBUG
    printf("Process %d of %d running on host %s\n", proc_num, num_procs, hostname);
#   endif
    if(argc == 1)           n = 1024;
    else if (argc == 2)     n = atoi(argv[1]);
    else
    {
        printf(usage);
        return 1;
    }

    A = (double *)malloc(n * n * sizeof(double));
    B = (double *)malloc(n * n * sizeof(double));
    C = (double *)malloc(n * n * sizeof(double));

    int i;
    srand(0);
    for(i = 0; i < n*n; i++)
    {
        A[i] = rand();
        B[i] = rand();
    }


    /* Matrix Calculations */
    GET_TIME(start);
    //pseudocode
    //Ck = Ck + Ak*Bkk
    //Atemp = Ak
    //j = k
    //for i = 1 to p-1 do
    //  j=(j+1) mod p
    //  send Atemp to left
    //  receive Atemp from right
    //  Ck = Ck + Atemp*Bjk
    //end
    
    GET_TIME(finish);
    printf("%f\n", hostname, finish-start);

    MPI_Finalize();
    return 0;
} /* main */
