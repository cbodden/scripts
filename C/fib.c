// program : fib.c
// author  : cbodden
// description : first attempt at a fibonacci program

#include <stdio.h>

int main(void)
{
    int A = 0, B = 1;
    int Q; // place holder
    int C; // iteration counter
    int IT ; // iterations

    printf("How many itterations should we go to ? : ");
    scanf("%d",&IT);
    for (C=0; C < IT; C++)
    {
        printf("Iteration : %d, Fibonacci number : %d\n", C, A);
        Q = A + B;
        A = B;
        B = Q;
    }

    return 0;
}
