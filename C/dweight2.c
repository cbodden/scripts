// compute the dimensional weight of a 12" x 10" x 8" box

#include <stdio.h>

int main(void)
{
    int height = 8, length = 12, width = 10, volume, weight;

    printf("Dimensions: %dx%dx%d\n", length, width, height);
    printf("Volume (cubic inches): %d\n", height * length * width);
    printf("Dimensional weight (pounds): %d\n", (volume + 165) / 166);

    return 0;
}
