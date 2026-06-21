# raindeer 项目规则

## 项目定位
raindeer 是一个融合 AWI 治理框架的 A 股量化研究平台。基于 Streamlit + PostgreSQL/TimescaleDB，覆盖股票研究、因子评估、回测、财报分析和 LLM 编排。

## 治理层级
所有操作和决策必须遵循以下文档优先级链（从高到低）：
1. CONSTITUTION.md — 宪法：不可变原则，最高权威
2. SOUL.md — 核心身份：五大原则，构建者哲学
3. AGENTS.md — 代理指令主入口：工作流、技能路由、验证协议
4. RULES.md — 规则契约：必须/禁止清单，格式规范
5. SECURITY.md — 安全策略：密钥管理、不可信输入、外部动作
6. SECURITY-ZONES.md — 运行时安全区：区域定义、数据流转、执行边界

## 语言规范
- 对话和交流：简体中文
- 代码注释：简体中文
- 代码标识符（变量名、函数名、类名）：英文
- Commit Message：英文（Conventional Commits 格式）
- 文档内容：简体中文
- 技能文件（skills/）：简体中文

## 技术约束
- 语言 / 运行时：Python 3.13
- 包管理：uv
- Web 框架：Streamlit 1.45+
- 数据库：PostgreSQL 16 + TimescaleDB
- 测试框架：pytest, with markers: db, external
- Lint：ruff (E4, E7, E9, F)
- 覆盖率目标：80%+
- 系统：Windows 优先（路径使用反斜杠，脚本使用 PowerShell）

## 代码架构约束
- 领域模型：@dataclass(frozen=True, slots=True) + to_json/from_json
- 数据库层：psycopg2 参数化查询，DSN 管理，密码脱敏
- LLM 编排：Brain 两阶段（TaskPlan → Dispatches），合同校验
- 数据源：Tushare + EastMoney + MinerU
- 作业调度：job runner + ingestion watermark

## Agent 行为规则
### 必须遵守
1. 遵循 CONSTITUTION.md 中的不可变原则
2. 所有代码变更必须通过 pytest 和 ruff 验证
3. 使用 frozen dataclass 定义领域模型
4. 保持 fail-closed 设计哲学
5. 所有输入经过严格校验
6. 使用 Type Hints
7. 保持文件在 200-400 行（最大 800 行）

### 禁止行为
1. 不要在代码中硬编码凭证
2. 不要绕过安全门禁
3. 不要无验证声明完成
4. 不要静默吞掉错误
5. 不要引入未经请求的依赖
6. 不要越界重构

## 验证命令
```powershell
# 进入应用目录
cd apps/quant_assistant

# 同步环境
uv sync --frozen --dev

# Lint 检查
uv run ruff check src/qa pages tests

# 运行测试（排除 db 和 external）
uv run pytest -q -m "not db and not external"

# 完整测试（需要数据库）
uv run pytest -q -m "db"

# 覆盖率
uv run coverage run -m pytest -q -m "not db and not external"
uv run coverage report
```

## 启动命令
```powershell
cd apps/quant_assistant
uv run streamlit run streamlit_app.py --server.headless true --browser.gatherUsageStats false
```

## 数据库
```powershell
docker compose up -d db
# DSN 通过 .env 中的 QA_POSTGRES_DSN 或分量配置
```
