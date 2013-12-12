#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <unistd.h>
#include <string.h>
#include "timer.h"

//#define VALUES

char* usage = "Usage: ./a.out <num_procs>\n where <num_procs> is the number of processors to use.  Using this option is not mandatory.\n";

int     n;                          //size of the matrix we will use
int     nc;                         //the "width" of each matrix column"
double  *A, *B, *C, *Atemp;         //the matrices we'll use

void calc_c(int,int);

int main(int argc, char* argv[])
{
/* Preprocessor Definitions */
#define atempmat(I,J) Atemp[I + n*J]
#define amat(I,J) A[I + n*J]
#define bmat(I,J) B[I + n*J]
#define cmat(I,J) C[I + n*J]
//#define DEBUG 1

   /* Variables */
   int     p;                          //total number of processors    
   int     k;                          //this processor's rank
   int     i,j;                        //counter variables
   double  start, finish;              //used for timing matrix computations
   char    hostname[20];               //hostname of this machine (for debug)
   double *Amatrix, *Bmatrix, *Cmatrix;//actual matrices (used by process 0)
   /* Initializations */
   MPI_Init(NULL, NULL);
   MPI_Comm_size(MPI_COMM_WORLD, &p);
   MPI_Comm_rank(MPI_COMM_WORLD, &k);
   hostname[19] = '\0';
   gethostname(hostname, 19);
#   ifdef DEBUG
   printf("Process %d of %d running on host %s\n", k, p, hostname);
#   endif
   //handle command line input
   if(argc == 1)           n = 1024;
   else if (argc == 2)     n = atoi(argv[1]);
   else
   {
       printf(usage);
       return 1;
   }

   nc = n/p;
   A     = (double *)malloc(n * nc * sizeof(double));
   Atemp = (double *)malloc(n * nc * sizeof(double));
   B     = (double *)malloc(n * nc * sizeof(double));
   C     = (double *)malloc(n * nc * sizeof(double));
    
   srand(0);

   for(i = 0; i < n*nc; i++)
   {
       C[i]=0;
   }
   /* Root process: generate and distribute data */
   if(k == 0)
   {
       Amatrix = (double *)malloc(n * n * sizeof(double));
       Bmatrix = (double *)malloc(n * n * sizeof(double));
       Cmatrix = (double *)malloc(n * n * sizeof(double));
       
       //Initialize data
       for(i = 0; i < n*n; i++)
       {
           Amatrix[i] = 0;
           Bmatrix[i] = 0;
           Cmatrix[i] = 0;
           //C[i] = 0;
       }
#ifdef VALUES //for correctness testing
       printf("\n%d\n", n);
       if(k==0)
       {
           printf("A = B = \n");
           for(i = 0; i < n; i++)
           {
               for(j = 0; j < n; j++)
               {
                   Amatrix[i+n*j] = i+j;
                   Bmatrix[i+n*j] = i+j;
                   printf("%f ", Amatrix[i+n*j]);
               }
               printf("\n");
           }
       }
#endif
   }
   //Now distribute.  Can do outside the root block
   MPI_Scatter(Amatrix, n*nc, MPI_DOUBLE, A, n*nc, MPI_DOUBLE, 0, MPI_COMM_WORLD);
   MPI_Scatter(Bmatrix, n*nc, MPI_DOUBLE, B, n*nc, MPI_DOUBLE, 0, MPI_COMM_WORLD);

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
   memcpy(Atemp,A,(n * nc * sizeof(double)));

   calc_c(k,k);
   j = k;
   int send_to = k-1;
   int receive_from = k+1;
   if (receive_from == p) receive_from = 0;
   if (send_to == -1) {
       send_to = p-1;
   }
   for(i = 0; i < p-1; i++)
   {
       j = (j+1) % p;
       //send left
       MPI_Sendrecv_replace(Atemp, n*nc, MPI_DOUBLE,
                            send_to, 0, receive_from, 0,
                            MPI_COMM_WORLD, MPI_STATUS_IGNORE);
       calc_c(j,k);
   }
   GET_TIME(finish);
   MPI_Barrier(MPI_COMM_WORLD);
   //output
   if(k == 0) printf("%f\n", finish-start);

   MPI_Gather(C, n*nc, MPI_DOUBLE, Cmatrix, n*nc, MPI_DOUBLE, 0, MPI_COMM_WORLD);
#ifdef VALUES
   if(k == 0)
   {
       printf("\n\n C = \n");
       for(i = 0; i < n; i++)
       {
           for(j = 0; j < n; j++)
           {
               printf("%f ", Cmatrix[i+n*j]);
           }
           printf("\n");
       }
   }
#endif
   MPI_Finalize();
   
   return 0;
} /* main */

/* Used to avoid having really messy code.  */
void calc_c(int j2, int k2)
{
   //Ck = Ck + Ak*Bjk
   int x,y,z;
   int sum;
   for (x=0; x<n; x++)
   {
       for (y=0; y<nc; y++)
       {
      
           for (z=0; z<nc; z++)
           {
               sum = sum + atempmat(x,z) * bmat(z+j2*nc,y);
           }
           cmat(x,y) = sum;
       }
   }
}
