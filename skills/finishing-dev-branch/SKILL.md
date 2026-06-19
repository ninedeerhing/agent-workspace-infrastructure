---
name: finishing-dev-branch
description: 当开发工作完成、所有验证通过后使用。触发条件：功能实现完毕、测试通过、代码审查完成，准备决定如何处理开发分支。
---

# Finishing Dev Branch — 完成开发分支

## 定位

开发完成后，需要决定如何处理分支：合并、创建 PR、保留或丢弃。四种结构化选项和决策依据。

## 触发条件

- 所有实现任务完成
- 所有测试通过
- 代码审查完成且无 Critical 问题
- 验证证据齐全

## 前置确认

- [ ] `verification-before-completion` 已完成
- [ ] 所有测试通过（单元 + 集成）
- [ ] Lint / 类型检查通过
- [ ] 代码审查通过

## 四种处理选项

### 选项 1：本地合并（Local Merge）

适用于个人项目、无 PR 流程团队。

```bash
git switch main
git pull origin main
git merge feature/xxx
git push origin main
git branch -d feature/xxx
```

### 选项 2：创建 PR（Create Pull Request）

适用于团队协作、需要审查、有 CI/CD 流水线。

```bash
git push origin feature/xxx
# 创建 PR → 等待 CI → 请求审查 → 处理反馈 → 合并
```

### 选项 3：保留分支（Keep Branch）

适用于长期功能分支、等待外部依赖、阶段性交付。

### 选项 4：丢弃分支（Discard Branch）

适用于实验性工作、方向变更、已被替代。

## 决策树

```
开发完成
├─ 需要他人审查？ → 选项 2：创建 PR
├─ 个人项目？ → 选项 1：本地合并
├─ 还有后续工作？ → 选项 3：保留分支
└─ 实验/废弃？ → 选项 4：丢弃分支
```

## 反模式 / 红牌

| 反模式 | 说明 |
|--------|------|
| 未验证就合并 | 红牌。必须通过完整验证 |
| 合并前不拉取最新 | 红牌。必须先同步 main |
| 忘记清理 worktree | 黄牌。完成后必须清理 |
| 丢弃前不记录经验 | 黄牌。失败实验也有价值 |
