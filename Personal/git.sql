下面给你一份 **Git 基础命令速查表**，按实际使用场景整理。你平时做项目，掌握这些就够用了。

---

# 一、查看状态类

## 查看当前仓库状态

```shell script
git status
```


常用来看：

- 当前在哪个分支
- 有哪些文件被修改
- 有没有文件待提交
- 本地是否领先/落后远程

---

## 查看提交历史

```shell script
git log
```


简洁版：

```shell script
git log --oneline
```


图形版：

```shell script
git log --oneline --graph --decorate --all
```


---

## 查看某个文件修改内容

```shell script
git diff
```


查看某个文件：

```shell script
git diff 文件名
```


例如：

```shell script
git diff script.sql
```


---

## 查看已暂存的修改

```shell script
git diff --cached
```


---

# 二、初始化和克隆

## 初始化 Git 仓库

```shell script
git init
```


把当前文件夹变成 Git 仓库。

---

## 克隆远程仓库

```shell script
git clone 仓库地址
```


例如：

```shell script
git clone https://github.com/用户名/仓库名.git
```


---

# 三、添加、提交代码

## 添加单个文件到暂存区

```shell script
git add 文件名
```


例如：

```shell script
git add script.sql
```


---

## 添加所有修改

```shell script
git add .
```


---

## 提交代码

```shell script
git commit -m "提交说明"
```


例如：

```shell script
git commit -m "Add database script"
```


---

## 添加并提交已跟踪文件

```shell script
git commit -am "提交说明"
```


注意：这个命令只对 **已经被 Git 跟踪过的文件** 有效。
新文件还是要先：

```shell script
git add 文件名
```


---

# 四、分支相关

## 查看本地分支

```shell script
git branch
```


---

## 查看本地和远程所有分支

```shell script
git branch -a
```


---

## 创建新分支

```shell script
git branch 分支名
```


例如：

```shell script
git branch dev
```


---

## 切换分支

```shell script
git checkout 分支名
```


新版本 Git 推荐：

```shell script
git switch 分支名
```


例如：

```shell script
git switch dev
```


---

## 创建并切换到新分支

旧写法：

```shell script
git checkout -b 分支名
```


新写法：

```shell script
git switch -c 分支名
```


例如：

```shell script
git switch -c feature/login
```


---

## 删除本地分支

```shell script
git branch -d 分支名
```


强制删除：

```shell script
git branch -D 分支名
```


---

# 五、远程仓库相关

## 查看远程仓库地址

```shell script
git remote -v
```


---

## 添加远程仓库

```shell script
git remote add origin 仓库地址
```


例如：

```shell script
git remote add origin https://github.com/用户名/仓库名.git
```


---

## 修改远程仓库地址

```shell script
git remote set-url origin 新仓库地址
```


---

## 删除远程仓库

```shell script
git remote remove origin
```


---

# 六、拉取和推送

## 拉取远程更新

```shell script
git pull
```


指定远程和分支：

```shell script
git pull origin main
```


---

## 推荐：用 rebase 拉取

```shell script
git pull --rebase origin main
```


这个可以让提交历史更清晰。

---

## 推送到远程

```shell script
git push
```


指定远程和分支：

```shell script
git push origin main
```


---

## 第一次推送并设置上游分支

```shell script
git push -u origin main
```


以后就可以直接：

```shell script
git push
```


---

## 强制推送

```shell script
git push --force origin main
```


更安全的强制推送：

```shell script
git push --force-with-lease origin main
```


建议优先使用 `--force-with-lease`，比 `--force` 安全。

---

# 七、撤销修改

## 撤销工作区某个文件的修改

```shell script
git restore 文件名
```


例如：

```shell script
git restore script.sql
```


---

## 撤销所有未暂存修改

```shell script
git restore .
```


---

## 取消暂存某个文件

```shell script
git restore --staged 文件名
```


例如：

```shell script
git restore --staged script.sql
```


---

## 取消暂存所有文件

```shell script
git restore --staged .
```


---

# 八、回退版本

## 回退到上一个提交，但保留修改

```shell script
git reset --soft HEAD~1
```


适合：提交信息写错了，想重新提交。

---

## 回退到上一个提交，修改回到工作区

```shell script
git reset --mixed HEAD~1
```


这是默认方式：

```shell script
git reset HEAD~1
```


---

## 回退到上一个提交，并删除修改

```shell script
git reset --hard HEAD~1
```


危险：会丢弃修改。

---

## 回退到指定提交

```shell script
git reset --hard 提交ID
```


例如：

```shell script
git reset --hard abc1234
```


---

## 安全撤销某个提交

```shell script
git revert 提交ID
```


`revert` 会新增一个“反向提交”，适合已经推送到远程的提交。

---

# 九、合并分支

## 合并某个分支到当前分支

```shell script
git merge 分支名
```


例如你当前在 `main`，要合并 `dev`：

```shell script
git merge dev
```


---

## 变基

```shell script
git rebase 分支名
```


常见：

```shell script
git pull --rebase origin main
```


---

# 十、冲突处理

当 `pull`、`merge`、`rebase` 出现冲突后：

## 查看冲突文件

```shell script
git status
```


---

## 解决冲突后添加文件

```shell script
git add 冲突文件
```


或：

```shell script
git add .
```


---

## 如果是 merge 冲突，继续提交

```shell script
git commit
```


---

## 如果是 rebase 冲突，继续 rebase

```shell script
git rebase --continue
```


---

## 放弃 rebase

```shell script
git rebase --abort
```


---

## 放弃 merge

```shell script
git merge --abort
```


---

# 十一、标签 tag

## 查看标签

```shell script
git tag
```


---

## 创建标签

```shell script
git tag v1.0.0
```


带说明的标签：

```shell script
git tag -a v1.0.0 -m "Version 1.0.0"
```


---

## 推送标签

```shell script
git push origin v1.0.0
```


推送所有标签：

```shell script
git push origin --tags
```


---

## 删除本地标签

```shell script
git tag -d v1.0.0
```


---

## 删除远程标签

```shell script
git push origin --delete v1.0.0
```


---

# 十二、忽略文件

## 创建或编辑 `.gitignore`

```shell script
touch .gitignore
```


常见内容：

```.gitignore (gitignore)
.DS_Store
.idea/
target/
*.log
*.class
```


---

## 已经被 Git 跟踪的文件，加入 `.gitignore` 后仍然生效吗？

不会。

需要先取消跟踪：

```shell script
git rm --cached 文件名
```


例如：

```shell script
git rm --cached ".DS_Store"
```


目录：

```shell script
git rm -r --cached 目录名
```


---

# 十三、查看远程信息

## 查看远程分支信息

```shell script
git remote show origin
```


---

## 查看远程分支

```shell script
git branch -r
```


---

## 获取远程更新，但不合并

```shell script
git fetch origin
```


`fetch` 只是下载远程信息，不会改你的工作区。

---

# 十四、保存临时修改 stash

## 暂存当前修改

```shell script
git stash
```


带说明：

```shell script
git stash push -m "临时保存修改"
```


---

## 查看 stash 列表

```shell script
git stash list
```


---

## 恢复最近一次 stash

```shell script
git stash pop
```


---

## 只应用但不删除 stash

```shell script
git stash apply
```


---

## 删除某个 stash

```shell script
git stash drop stash@{0}
```


---

## 清空所有 stash

```shell script
git stash clear
```


---

# 十五、常用组合流程

## 日常提交代码

```shell script
git status
git add .
git commit -m "提交说明"
git push origin main
```


---

## 推送前先同步远程

```shell script
git pull --rebase origin main
git push origin main
```


---

## 新项目第一次推送到 GitHub

```shell script
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/用户名/仓库名.git
git push -u origin main
```


---

## 删除 Git 跟踪的 `.DS_Store`

```shell script
echo .DS_Store >> .gitignore
find . -name .DS_Store -print0 | xargs -0 git rm --cached --ignore-unmatch
git add .gitignore
git commit -m "Ignore DS_Store files"
git push origin main
```


---

# 十六、你最常用的 10 个命令

日常开发基本用这些：

```shell script
git status
git add .
git commit -m "提交说明"
git pull --rebase origin main
git push origin main
git log --oneline
git diff
git branch
git switch 分支名
git restore 文件名
```


---

# 十七、简单记忆路线

```plain text
查看状态：git status
添加修改：git add .
提交本地：git commit -m "说明"
拉取远程：git pull --rebase origin main
推送远程：git push origin main
撤销修改：git restore 文件名
查看历史：git log --oneline
```


如果你刚开始学 Git，优先掌握这 7 个就够了。