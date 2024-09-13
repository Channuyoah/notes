# 笨办法学C
链接: [笨办法学C](https://wizardforcel.gitbooks.io/lcthw/content/)

慢慢来会更快
### 练习1～2
注意：关于写makefile文件的时候Tab符号的操作，我是自己自定义了.vimrc文件，将Tab符给展开了:set expandtab，所以导致无法运行make的自定clean等其他功能
```makefile
CFLAGS=-Wall -g

clean:
    rm -f ex1
all:$xx
    make ex1
    ./ex1
    rm -f ex1
```