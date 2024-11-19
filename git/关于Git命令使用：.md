## 关于Git命令使用：

```bash
git clone url
git add .
git add fileName
git restore .
git restore fileName
git commit -m "commit message"
git commit -amend -m "commit message"
git commit --amend --author "name <email>"
git push 
git push -f
git branch -avv
git remote -v
git remote set-url origin git@xxxxxxx
tig --all
git log -number
git checkout -b `newBranchName`
git push origin --delete `branchName`
git branch -D `branchName`
git branch `branchName`
git fetch -p
git rebase `branchName`
git rebase --abort
git rebase -i HEAD~`number`
git remote set-url origin `url`
export http_proxy=http://127.0.01:7890
export https_proxy=http://127.0.0.1:7890
git branch -m `oldBranchName` `newBranchName`
git push origin --delete `oldBranchName`
git branch --unset-upstream
git push --set-upstream `branchName`

// 撤销操作
git reset ???
git reset --soft HEAD~1
git checkout .
```



