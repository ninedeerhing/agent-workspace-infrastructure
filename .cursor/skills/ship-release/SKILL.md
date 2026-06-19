---
name: ship-release
description: 发布工程师视角的发布流程。触发条件：代码已就绪，需要执行标准化发布流程。
---
<!-- DEPRECATED: 此技能已被 $release-omc 替代。release-omc 提供仓库感知的自动化发布，覆盖了 ship-release 的全部功能。 -->
# Ship Release — 发布上线
## 定位
以发布工程师的视角执行标准化发布流程。确保每次发布安全、可回滚、有记录。
## 触发条件
- 所有代码审查通过
- 所有测试通过
- `verification-before-completion` 完成
- 准备发布
## 发布流程
### 第 1 步：同步 Main
```bash
git switch main
git pull origin main
```
确保本地 main 是最新的。
### 第 2 步：测试
```bash
# 运行完整测试套件
npm test  # 或项目测试命令
npm run build  # 确认构建成功
```
### 第 3 步：合并
```bash
git merge feature/xxx
# 解决冲突
git push origin main
```
### 第 4 步：创建 PR（如适用）
如果需要 PR 流程：
1. 推送功能分支
2. 创建 PR
3. 等待 CI 通过
4. 合并 PR
### 第 5 步：部署
- 确认部署流水线触发
- 监控部署状态
- 验证生产环境健康
### 第 6 步：发布验证
- 冒烟测试关键路径
- 监控错误率和延迟
- 确认功能在生产可用
### 第 7 步：清理
```bash
git branch -d feature/xxx
git worktree remove ../project-feature-xxx  # 如有
```
## 回滚预案
发布前确认：
- [ ] 回滚步骤已明确
- [ ] 回滚责任人已指定
- [ ] 回滚触发条件已定义
- [ ] 数据兼容性已验证
## 反模式 / 红牌
| 反模式 | 说明 |
|--------|------|
| 无回滚预案 | 红牌。每次发布必须有回滚计划 |
| 跳过生产验证 | 红牌。必须在生产环境验证 |
| 发布后不监控 | 红牌。至少监控 30 分钟 |
| 周五下午发布 | 黄牌。避免在非工作时间发布 |
| 多人同时发布 | 黄牌。避免发布冲突 |
