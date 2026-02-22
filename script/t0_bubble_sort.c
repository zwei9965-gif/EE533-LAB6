// T0: bubble_sort.c
// Thread 0 — Sort N integers in ascending order
// Data: N=10, array={323, 123, -455, 2, 98, 125, 10, 65, -56, 0}
// Expected output: {-455, -56, 0, 2, 10, 65, 98, 123, 125, 323}

int N = 10;
int array[10] = {323, 123, -455, 2, 98, 125, 10, 65, -56, 0};

void bubble_sort() {
    int i, j, tmp;
    for (i = 0; i < N - 1; i++) {
        for (j = 0; j < N - 1 - i; j++) {
            if (array[j] > array[j + 1]) {
                tmp        = array[j];
                array[j]   = array[j + 1];
                array[j+1] = tmp;
            }
        }
    }
}
