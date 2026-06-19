# API 设计规范

## 1. RESTful 规范

### URL 设计

- 资源名使用名词**复数**：`/users`、`/orders`、`/products`
- 层级关系通过路径嵌套表达：`/users/{id}/orders`、`/orders/{id}/items`
- 使用短横线分隔多个单词：`/order-items`（非 `orderItems` 或 `order_items`）
- 避免深层嵌套，最多 3 层：`/resource/{id}/sub-resource/{id}/nested` → 拆分

### HTTP 方法

| 方法   | 语义     | 示例                              |
| ------ | -------- | --------------------------------- |
| GET    | 获取资源 | `GET /users`、`GET /users/{id}`   |
| POST   | 创建资源 | `POST /users`                     |
| PUT    | 全量更新 | `PUT /users/{id}`                 |
| PATCH  | 部分更新 | `PATCH /users/{id}`               |
| DELETE | 删除资源 | `DELETE /users/{id}`              |

### HTTP 状态码

| 状态码 | 场景                            |
| ------ | ------------------------------- |
| 200    | 请求成功（GET、PUT、PATCH）     |
| 201    | 创建成功（POST）                |
| 204    | 删除成功（DELETE，无响应体）    |
| 400    | 请求参数校验失败                |
| 401    | 未认证                          |
| 403    | 无权限                          |
| 404    | 资源不存在                      |
| 409    | 资源冲突（唯一约束冲突）        |
| 422    | 业务逻辑校验失败                |
| 429    | 速率限制                        |
| 500    | 服务器内部错误（不暴露详情）    |

## 2. 版本控制

- 推荐 URL 前缀版本：`/api/v1/users`、`/api/v2/users`
- 备选 Header 版本：`Accept: application/vnd.myapp.v2+json`
- 同一路径最多同时维护 2 个大版本（当前 + 前一版本）
- 旧版本废弃前必须发弃用通知（通过响应头 `Deprecation` 和 `Sunset`）

## 3. 统一响应格式

```json
{
  "status": "success",
  "data": { ... },
  "error": null,
  "meta": {
    "page": 1,
    "size": 20,
    "total": 156,
    "request_id": "req_abc123"
  }
}
```

```json
{
  "status": "error",
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "参数校验失败",
    "details": [
      { "field": "email", "reason": "邮箱格式不正确" }
    ]
  },
  "meta": { "request_id": "req_abc123" }
}
```

## 4. 分页规范

- 列表接口默认使用基于页码的分页：`?page=1&size=20`
- `size` 上限 100，超出返回 400
- 响应 `meta` 中返回 `page`、`size`、`total`、`total_pages`
- 实时性要求高的列表使用 cursor-based 分页：`?cursor=xxx&size=20`
- 允许指定排序：`?sort=-created_at`（`-` 表示降序）

## 5. 错误处理

- 业务错误码格式：`<模块>_<错误类型>`（如 `ORDER_PAYMENT_FAILED`）
- 错误码不可重复使用——新增错误场景使用新码
- 面向用户的 `message` 必须友好且可操作（非技术堆栈信息）
- 面向开发者的 `details` 可包含技术细节
- 500 错误绝不向客户端暴露堆栈信息——记录到日志并返回通用消息

## 6. 速率限制

- 所有公开 API 必须配置速率限制
- 超出限制返回 `429 Too Many Requests`
- 响应必须包含以下头：
  - `X-RateLimit-Limit`：窗口内最大请求数
  - `X-RateLimit-Remaining`：窗口内剩余请求数
  - `X-RateLimit-Reset`：窗口重置的 Unix 时间戳
  - `Retry-After`：建议重试等待秒数

## 7. OpenAPI 文档

- 所有 API 使用 OpenAPI 3.0+ 规范编写
- 文档与代码同仓，放入 `docs/api/` 目录
- CI 中集成文档校验步骤（结构完整性 + 示例有效性）
- 生成文档变更 diff 作为 PR 审查依据
- 使用 Swagger UI / Scalar 提供可交互文档页面
