# 设计模式规则 (Design Patterns Rules)

## 适用范围

所有新创建的项目和模块。

## 分层架构规则

- **领域层** — 不依赖任何框架或外部库；纯业务逻辑
- **服务层** — 协调领域对象，实现用例
- **基础设施层** — 实现接口，处理数据库、网络、文件系统
- **API层** — 最薄层，仅做请求转换和路由

## API响应格式

### 成功响应
```json
{ "status": "ok", "data": {}, "meta": { "page": 1, "total": 100 } }
```

### 错误响应
```json
{ "status": "error", "error": { "code": "VALIDATION_ERROR", "message": "描述", "details": [] } }
```

## 命名约定

| 类型 | 约定 | 示例 |
|------|------|------|
| 文件 | kebab-case | user-service.ts |
| 类/接口 | PascalCase | UserService |
| 函数/方法 | camelCase | getUserById() |
| 变量 | camelCase | userEmail |
| 常量 | UPPER_SNAKE_CASE | MAX_RETRY_COUNT |
| REST端点 | kebab-case复数 | /api/user-profiles |

## 禁止模式

- 上帝类（一个类做所有事情）
- 循环依赖
- 静态可变状态
- 服务定位器模式
