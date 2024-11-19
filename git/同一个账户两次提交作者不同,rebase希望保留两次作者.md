## 问题描述
创建了一个新分支，第一次提交作者是cc，第二次提交写了--author "ehorizon <xxx@qq.com>"，现在我想把这两次提交合并，但是保留两次提交的作者，就是到时候在代码界面可以看到作者是不一样的。

## 过程问题解决`
因为我第一次提交的时候message信息有误所以我先git rebase -i HEAD~2将错误的那个pick更换为r reword = use commit, but edit the commit message

## 解决方案
 - 第一次提交之后，再拉一个新分支，然后把第二次在这个新分支提交(改作者)，然后master合并这个新分支
 - 使用还是在一个分支上提交两次，然后修改rebase -i HEAD~2的内容(不知道怎么做)
