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
    int     p;                          //total number of processors    
    int     proc_num;                   //this processor's rank
    int     n;                          //size of the matrix we will use
    int     nc;                         //the "width" of each matrix column"
    int     i,j,k;                      //counter variables
    double  start, finish;              //used for timing matrix computations
    char    hostname[20];               //hostname of this machine (for debug)
    double  *A, *B, *C, *Atemp;         //the matrices we'll use

    /* Initializations */
    MPI_Init(NULL, NULL);
    MPI_Comm_size(MPI_COMM_WORLD, &num_procs);
    MPI_Comm_rank(MPI_COMM_WORLD, &proc_num);
    hostname[19] = '\0';
    gethostname(hostname, 19);
#   ifdef DEBUG
    printf("Process %d of %d running on host %s\n", proc_num, p, hostname);
#   endif
    if(argc == 1)           n = 1024;
    else if (argc == 2)     n = atoi(argv[1]);
    else
    {
        printf(usage);
        return 1;
    }

    A     = (double *)malloc(n * nc * sizeof(double));
    Atemp = (double *)malloc(n * nc * sizeof(double));
    B     = (double *)malloc(n * nc * sizeof(double));
    C     = (double *)malloc(n * nc * sizeof(double));
     
    srand(0);

    /* 
     * TODO:
     * Have root process intialize all the data and then
     * send it out to the worker processes
     */

    k = proc_num; //just to follow the pseudocode easier

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

    /* Matrix Calculations */
    MPI_Barrier(MPI_COMM_WORLD); //do barrier so that we synchronize for better time
    GET_TIME(start);
    
    //real code
    calc_c(k,k);
    Atemp = Ak;
    j = k;
    for(i = 1; i < p-1; i++)
    {
        j = mod(j+1, p);
        
        //send left
        if(k > 0)
        {
            MPI_Send(Atemp, nc, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);
        }
        //send right
        if(k < p-1)
        {
            MPI_Receive(Atemp, nc, MPI_DOUBLE,k+1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        }
        calc_c(j,k); 
    }
    MPI_Barrier(MPI_COMM_WORLD);    
    GET_TIME(finish);
    printf("%f\n", finish-start);

    MPI_Finalize();
    return 0;
} /* main */

/* Used to avoid having really messy code.  */
void calc_c(int j2, int k2)
{
    //Ck = Ck + Ak*Bkk
    int sum;
    int x,y,z;
    for (x=0; x<n; x++) 
    {
        for (y=0; y<nc; y++) 
        {
            sum = cmat(x,y);
            for (z=0; z<nc; z++) 
            {
                sum = sum + amat(x,k2+y) * bmat(j2+z,k2+y);
            }
            cmat(x,y) = sum;
        }
    }
}
