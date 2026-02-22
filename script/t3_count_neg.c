// T3: count_neg.c
// Thread 3 — Count the number of negative integers in the array
// Data: N=10, array={5, 4, 3, 2, 1, -1, -2, -3, -4, -5}
// Expected output: result = 5

int N = 10;
int array[10] = {5, 4, 3, 2, 1, -1, -2, -3, -4, -5};
int result = 0;

void count_neg() {
    int i, cnt = 0;
    for (i = 0; i < N; i++) {
        if (array[i] < 0) {
            cnt++;
        }
    }
    result = cnt;
}
