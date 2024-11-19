# C++无锁队列

### 一、相关链接

- [什么是无锁队列](https://coolshell.cn/articles/8239.html)

- [C++无锁队列Github](https://github.com/cameron314/concurrentqueue)

### 二、有锁 VS 无锁

都是用于在多线程环境中实现安全的队列操作

#### 1、有锁队列

  有锁队列使用锁机制来保证线程安全性。在多线程环境当中，当一个线程要访问队列时，会先获取一个锁(通常为互斥锁mutex)。获取锁的线程可以安全地对队列进行操作(如出队、入队)，其他线程则会被阻塞，直到锁被释放。这种方法确保了队列操作的原子性和一致性

特点为：
- 线程安全：通过锁机制保证操作的原子性。
- 容易实现：锁的使用使得实现相对简单。
- 性能瓶颈：高并发时可能会出现锁竞争，导致性能下降，特别是在锁争用严重的情况下。

#### 2、无锁队列

无锁队列通过使用原子操作和硬件提供的并发原语（如CAS操作，即Compare-And-Swap）来实现线程安全。无锁队列通常采用一些复杂的算法，如Michael and Scott队列算法，以避免使用锁，从而减少锁竞争和上下文切换带来的开销。

特点为：
- 线程安全：通过原子操作确保操作的原子性。
- 高性能：在高并发情况下，无锁队列通常比有锁队列性能更好，因为没有锁竞争。
- 复杂实现：实现无锁队列需要复杂的算法和对底层硬件的良好理解。

### 三、无锁案例

compare_and_swap函数实现
```C
int compare_and_swap(int* reg, int oldval, int newval) {
    int old_reg_val = *reg;  // 读取当前值
    if (old_reg_val == oldval) {  // 比较当前值与预期值
        *reg = newval;  // 更新为新值
    }
    return old_reg_val;  // 返回旧值
}
```
---
调用案例：
```C
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

volatile int shared_var = 42;

void* thread_func(void* arg) {
    int expected = 42;
    int new_value = 100;
    int result = compare_and_swap(&shared_var, expected, new_value);

    if (result == expected) {
        printf("Thread %ld: CAS succeeded, shared_var updated to %d\n", (long)arg, new_value);
    } else {
        printf("Thread %ld: CAS failed, shared_var is %d\n", (long)arg, result);
    }

    return NULL;
}

int main() {
    pthread_t threads[2];
    
    // 创建两个线程
    for (long i = 0; i < 2; i++) {
        pthread_create(&threads[i], NULL, thread_func, (void*)i);
    }

    // 等待线程完成
    for (int i = 0; i < 2; i++) {
        pthread_join(threads[i], NULL);
    }

    printf("Final shared_var: %d\n", shared_var);
    return 0;
}

```
`pthread_create`和`pthread_join`函数是POSIX线程（pthread）库中用于创建和等待线程的基本函数。

#### CAS函数返回值是有意义的。
- 函数返回旧值（即old_reg_val）是为了让调用者知道CAS操作是否成功。这是通过比较返回值和预期值来判断的。

- 如果返回值等于oldval，则表示CAS操作成功，内存位置reg的值已被更新为newval。
- 如果返回值不等于oldval，则表示CAS操作失败，内存位置reg的值没有被更新，因为它已经被其他线程修改过。

#### 思考：
- 在函数内部不是已经判断了当前值和预期值是否相等吗？为什么我们还需要拿到CAS函数的返回值再进行比较一下当前值和预期值呢？

#### 解思考：
- 这样做的目的是为了确保在并发环境中进行的操作是原子性的，并避免竞争条件

- CAS操作是原子的，这样意味着它要么完全完成，要么完全不完成。直接检查指针指向的内存值和`newval`是无法保证这种原子性的。在多线程环境中，如果只是检查内存值，其他线程可能在你检查和更新之间修改了该值，从而导致竞态条件。

也可以返回类型为bool，这样就可以直观的知道是否更新成功

