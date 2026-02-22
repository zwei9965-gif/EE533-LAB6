// T2: find_max.c
// Thread 2 — Find the maximum value among N integers
// Data: N=10, array={-9, -3, -7, -1, -5, -8, -2, -4, -6, 0}
// Expected output: result = 0

int N = 10;
int array[10] = {-9, -3, -7, -1, -5, -8, -2, -4, -6, 0};
int result = 0;

void find_max() {
    int i, m = array[0];
    for (i = 1; i < N; i++) {
        if (array[i] > m) {
            m = array[i];
        }
    }
    result = m;
}
