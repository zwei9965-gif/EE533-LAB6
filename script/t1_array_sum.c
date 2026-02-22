// T1: array_sum.c
// Thread 1 — Compute the sum of N integers
// Data: N=10, array={10, 20, 30, 40, 50, 60, 70, 80, 90, 100}
// Expected output: result = 550

int N = 10;
int array[10] = {10, 20, 30, 40, 50, 60, 70, 80, 90, 100};
int result = 0;

void array_sum() {
    int i, s = 0;
    for (i = 0; i < N; i++) {
        s += array[i];
    }
    result = s;
}
