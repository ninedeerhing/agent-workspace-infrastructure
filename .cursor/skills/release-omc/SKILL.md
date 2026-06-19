---
name: release-omc
description: 当需要自动化发布工作流时使用。触发条件：release、ship it、prepare release、发布新版本、打 tag、推送发布。
---
# Release OMC — 发布助手
## 定位
仓库感知的发布助手。首次运行时分析项目和 CI 配置，推导发布规则并缓存，之后按规则引导完成发布流程。所有规则从仓库检测中推导，不硬编码任何项目特定逻辑。
## 触发条件
- 用户提到 `release`、`ship it`、`prepare release`
- 需要发布新版本
- 需要自动化版本号更新、CHANGELOG 生成、打 tag、推送
## 前置条件
- 仓库有版本管理文件（package.json、pyproject.toml、Cargo.toml 等）
- 代码变更已提交
- CI 绿色
## 执行流程
### 第 1 步：加载或构建发布规则
检查 `.omc/RELEASE_RULE.md` 是否存在。
**不存在时（或 `--refresh`）**：执行完整的仓库分析：
#### 1a. 版本来源
- 定位所有包含版本字符串的文件
- 列出每个文件的版本字段或正则模式
- 检测是否有发布自动化脚本（如 `scripts/release.*`、`Makefile` release 目标、`bump2version`、`release-it`、`semantic-release`、`changesets`、`goreleaser`）
#### 1b. 注册中心/分发
- npm（`package.json` 含 `publishConfig` 或 CI 中有 `npm publish`）
- PyPI（`pyproject.toml` + `twine`/`flit`）
- Cargo（`Cargo.toml`）
- Docker（`Dockerfile` + push 步骤）
- 是否有 CI 步骤在 tag push 时自动发布
#### 1c. 发布触发
- 识别发布触发方式：tag push（`v*`）、手动调度（`workflow_dispatch`）、合并到 main、发布分支合并、commit 消息模式
#### 1d. 测试门控
- 识别测试命令及其在 CI 中的位置
- 测试是否必须在发布前通过
#### 1e. 发布说明 / CHANGELOG
- 是否存在 `CHANGELOG.md`
- 使用什么约定：Keep a Changelog、Conventional Commits、GitHub 自动生成
- 是否有发布正文文件
#### 1f. 首次用户检查
- 是否存在发布 CI 工作流
- 构建产物是否被 gitignore
- 是否使用 git tag
- 标记缺失部分并提供建议
**存在时**：读取规则文件，快速增量检查 CI 配置是否有更新。
### 第 2 步：确定版本号
- 如果用户提供了版本参数，直接使用
- 否则：显示当前版本，展示 patch/minor/major 分别产生什么版本，询问用户选择
- 验证版本号为合法 semver 格式
### 第 3 步：发布前检查清单
根据发布规则生成检查清单：
- [ ] 本次发布的所有变更已提交并推送
- [ ] 目标分支 CI 绿色
- [ ] 本地测试通过
- [ ] 版本号已更新到所有版本源文件
- [ ] CHANGELOG 已准备就绪
### 第 4 步：CHANGELOG 指导
帮助用户撰写发布说明：
- 以**用户可见的变化**开头，而非内部实现细节
- 按类型分组：新功能、Bug 修复、破坏性变更、弃用、内部/杂务
- 每条一行，关联 PR 或 issue 链接
- 破坏性变更放在最前面，包含迁移指南
- 省略用户看不到的变更
如果仓库使用 Conventional Commits，从 `git log <上一版tag>..HEAD --no-merges` 自动生成 CHANGELOG 草稿。
### 第 5 步：执行发布
1. **更新版本号**：应用到所有版本源文件
2. **运行测试**：执行测试门控命令
3. **提交**：`git add <版本文件> CHANGELOG.md` + `git commit -m "chore(release): bump version to vX.Y.Z"`
4. **打 tag**：`git tag -a vX.Y.Z -m "vX.Y.Z"`（推荐 annotated tag）
5. **推送**：`git push origin <branch> && git push origin vX.Y.Z`
6. **CI 接手**：如果触发是 tag push，提醒用户 CI 会处理后续
7. **手动发布**：如果无 CI 自动化，列出手动发布命令
### 第 6 步：验证
推送后：
- 检查 CI 状态
- 检查注册中心是否有新版本
- 确认 GitHub Release 已创建
- 报告成功或标记失败
## 首次用户建议
- **无发布 CI 工作流**：提供搭建 `.github/workflows/release.yml` 的选项
- **无 git tag**：解释 git tag 的重要性，首次发布会创建第一个 tag
- **构建产物未 gitignore**：提供添加 `.gitignore` 条目的选项
## 发布规则缓存格式
```markdown
# Release Rules
<!-- last-analyzed: YYYY-MM-DDTHH:MM:SSZ -->
## Version Sources
<!-- 文件 + 模式列表 -->
## Release Trigger
<!-- 什么触发发布 -->
## Test Gate
<!-- 命令 + CI 作业名 -->
## Registry / Distribution
<!-- npm、PyPI、Docker 等 + 发布的 CI 作业 -->
## Release Notes Strategy
<!-- 约定 + 文件 -->
## CI Workflow Files
<!-- 相关工作流文件路径 -->
## First-Time Setup Gaps
<!-- 分析期间发现的缺失项 -->
```
## 反模式 / 红牌
| 反模式 | 说明 |
|--------|------|
| 跳过测试门控 | 红牌。发布前必须运行测试 |
| 不更新所有版本源文件 | 红牌。必须同步所有版本文件 |
| 用 lightweight tag | 黄牌。推荐 annotated tag |
| 跳过 CHANGELOG | 黄牌。每个发布应有发布说明 |
| 不验证 CI 状态 | 红牌。推送后必须确认 CI 通过 |
| 未推送 tag | 红牌。tag 必须推送才能触发 CI |
| 硬编码项目规则 | 红牌。规则必须从仓库检测推导 |
## 成功标准
- 版本号已正确更新到所有源文件
- CHANGELOG 已更新
- 测试通过
- commit 和 tag 已推送到远程
- CI 发布流程已触发或手动发布命令已执行
- 发布验证已确认
