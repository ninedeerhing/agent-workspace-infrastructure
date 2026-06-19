---
name: git-publish
description: Git 仓库发布与同步——自动提交变更、生成约定式提交信息、推送到远程仓库、处理冲突。触发条件：需要发布代码到 GitHub、需要提交变更、需要更新远程仓库。
---
# Git Publish — Git 仓库发布与同步
## 定位
AWI 的 Git 发布技能。遵循 Conventional Commits 规范，自动检测变更类型并生成提交信息，处理发布全流程。
## 触发条件
- 用户说"发布到 GitHub"、"提交变更"、"push"、"上传"
- 一系列功能完成后需要发布
- 需要同步远程仓库
## 发布流程
### 第 1 步：变更检测
1. `git status` 检查当前状态
2. `git diff --stat` 查看变更文件列表
3. 分类变更：feat（新功能）/ fix（修复）/ chore（杂项）/ docs（文档）/ refactor（重构）
### 第 2 步：生成提交信息
遵循 Conventional Commits 格式：
```
type(scope): 简短描述
详细说明（可选）
变更文件列表（可选）
```
类型自动检测规则：
- 新增文件 > 5 个 且包含 SKILL.md → `feat(skills)`
- 新增文件 > 3 个 且包含 .md → `feat(docs)`
- 修改 AGENTS.md / README.md → `docs`
- 修改 harness/ 状态文件 → `chore(harness)`
- 修改 agents/ → `feat(agents)`
- 修改 .trae/skills/ → `chore(sync)`
- 删除文件 → `refactor` 或 `chore`
### 第 3 步：执行提交与推送
1. `git add -A`
2. `git commit -m "生成的提交信息"`
3. `git push origin main`（或其他当前分支）
4. 如果推送失败（无远程仓库），提示用户先配置远程仓库
### 第 4 步：发布确认
输出：
- 提交 hash
- 变更文件数和行数
- 推送结果
## 远程仓库配置
如果未配置远程仓库：
```bash
# 用户需要先在 GitHub 上创建空仓库，然后：
git remote add origin https://github.com/ninedeerhing/<repo-name>.git
git push -u origin main
```
## 分支策略
本技能默认在 `main` 分支上工作。如果使用分支开发：
- `git checkout -b feature/xxx` 创建功能分支
- 完成后合并回 main：`git checkout main && git merge feature/xxx`
- 推送：`git push origin main`
## 冲突处理
| 冲突类型 | 处理方式 |
|----------|----------|
| 本地有未提交变更 + 远程有新提交 | 先 `git stash` → `git pull` → `git stash pop` |
| 合并冲突 | 手动解决冲突文件 → `git add` → `git commit` |
| 推送被拒绝 | `git pull --rebase` → 解决冲突 → `git push` |
## 反模式
| 反模式 | 说明 |
|--------|------|
| 提交信息为 "update" 或 "fix" | 必须遵循 Conventional Commits 格式 |
| 大爆炸提交（100+ 文件变更一次提交） | 拆分为逻辑上独立的多次提交 |
| 不检查 git status 就直接提交 | 先看变更再决定提交内容 |
| 提交包含密钥或敏感数据 | 提交前必须检查（参考 CONSTITUTION.md） |
| force push 到 main 分支 | 禁止 `git push --force` 到 main/main |
## 与 GitHub 调研技能的配合
`$github-research` 用于调研外部项目，`$git-publish` 用于发布自己的项目。两者形成完整的 GitHub 工作流：
```
github-research → 调研参考项目 → 吸收方法论
git-publish     → 提交本地变更 → 推送到 GitHub
```
