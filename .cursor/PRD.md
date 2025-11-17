# LLM Hub - 产品需求文档 (PRD)

## 1. 文档信息

- **文档版本**: v1.1
- **创建日期**: 2025-11-16
- **最后更新**: 2025-11-16
- **产品名称**: LLM Hub
- **版本**: MVP (v0.1)
- **产品负责人**: [待填写]
- **关联文档**: [MRD.md](./MRD.md)

## 2. 产品概述

### 2.1 产品简介

LLM Hub 是一个统一的大语言模型访问与管理平台，通过单一标准化的 API 接口，整合多个 LLM 服务提供商（OpenAI、Anthropic、Google、阿里云、百度等），为开发者提供便捷、可靠、高性能的 AI 模型调用体验。

### 2.2 产品目标

**MVP 阶段目标**:
- 实现统一的 LLM API 接口，兼容 OpenAI API 格式
- 接入 3-5 个主流 LLM 提供商
- 验证核心价值主张，获取 50+ 早期用户
- 达到基本的生产可用标准

**业务目标**:
- 降低开发者 LLM 集成成本 70%+
- 提供 99.9% 的服务可用性
- 实现单机 5000+ 并发处理能力

### 2.3 目标用户

#### 主要用户角色

1. **API 使用者 (Developer)**
   - 通过 API 调用 LLM 服务的开发者
   - 关注：API 稳定性、响应速度、价格透明

2. **管理员 (Admin)**
   - 管理组织、团队、API Key 的管理员
   - 关注：权限控制、用量监控、成本管理

3. **运维人员 (Operator)**
   - 负责系统部署和运维的技术人员
   - 关注：系统监控、日志查询、故障排查

## 3. MVP 核心功能需求

### 3.1 功能优先级矩阵

| 功能模块 | 优先级 | MVP | V1.0 | 复杂度 |
|---------|--------|-----|------|--------|
| 统一 API 接口 | P0 | ✓ | ✓ | 高 |
| 模型管理 | P0 | ✓ | ✓ | 中 |
| 认证鉴权 | P0 | ✓ | ✓ | 中 |
| 用量统计 | P0 | ✓ | ✓ | 中 |
| Web 控制台（基础） | P0 | ✓ | ✓ | 高 |
| 多模态支持 | P0 | ✓ | ✓ | 高 |
| 智能路由 | P1 | - | ✓ | 高 |
| 多租户管理 | P1 | - | ✓ | 高 |
| 成本控制 | P1 | - | ✓ | 中 |
| 监控告警 | P1 | 基础 | 完整 | 中 |

## 4. 详细功能规格

### 4.1 统一 API 接口

#### 4.1.1 功能描述

提供兼容 OpenAI API 格式的统一接口，允许用户通过标准化的请求格式调用不同的 LLM 提供商。

#### 4.1.2 用户故事

```
作为一个开发者
我想要使用统一的 API 格式调用不同的 LLM 模型
这样我就可以轻松切换模型而无需修改代码
```

#### 4.1.3 API 规格

**Chat Completion API**

```http
POST /v1/chat/completions
Content-Type: application/json
Authorization: Bearer {API_KEY}

{
  "model": "gpt-4",
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful assistant."
    },
    {
      "role": "user",
      "content": "Hello, how are you?"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 1000,
  "stream": false
}
```

**响应格式**

```json
{
  "id": "chatcmpl-123456",
  "object": "chat.completion",
  "created": 1699000000,
  "model": "gpt-4",
  "provider": "openai",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "I'm doing well, thank you for asking! How can I assist you today?"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 20,
    "completion_tokens": 15,
    "total_tokens": 35
  },
  "cost": {
    "input_cost": 0.0006,
    "output_cost": 0.00045,
    "total_cost": 0.00105,
    "currency": "USD"
  }
}
```

**流式响应 (SSE)**

```http
POST /v1/chat/completions
Content-Type: application/json
Authorization: Bearer {API_KEY}

{
  "model": "gpt-4",
  "messages": [...],
  "stream": true
}
```

响应示例：

```
data: {"id":"chatcmpl-123","object":"chat.completion.chunk","created":1699000000,"model":"gpt-4","choices":[{"index":0,"delta":{"role":"assistant","content":"Hello"},"finish_reason":null}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","created":1699000000,"model":"gpt-4","choices":[{"index":0,"delta":{"content":" there"},"finish_reason":null}]}

data: [DONE]
```

**多模态请求 (Vision)**

```http
POST /v1/chat/completions
Content-Type: application/json
Authorization: Bearer {API_KEY}

{
  "model": "gpt-4-vision-preview",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "What's in this image?"
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "https://example.com/image.jpg",
            "detail": "high"
          }
        }
      ]
    }
  ],
  "max_tokens": 1000
}
```

**多模态响应**

```json
{
  "id": "chatcmpl-123456",
  "object": "chat.completion",
  "created": 1699000000,
  "model": "gpt-4-vision-preview",
  "provider": "openai",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "The image shows a beautiful sunset over the ocean with vibrant orange and pink colors in the sky."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 285,
    "completion_tokens": 20,
    "total_tokens": 305,
    "image_tokens": 265
  },
  "cost": {
    "input_cost": 0.00855,
    "output_cost": 0.0006,
    "total_cost": 0.00915,
    "currency": "USD"
  }
}
```

**图像输入格式支持**

- URL 方式：`https://` 或 `http://` 开头的图片链接
- Base64 方式：`data:image/jpeg;base64,{base64_string}`
- 支持的图片格式：JPEG, PNG, GIF, WebP
- 图片大小限制：最大 20MB
- 分辨率限制：最大 4096x4096

#### 4.1.4 支持的模型列表 (MVP)

| 提供商 | 模型 ID | 用途 | 多模态支持 | 优先级 |
|--------|---------|------|-----------|--------|
| OpenAI | gpt-4, gpt-4-turbo | 高质量对话 | 否 | P0 |
| OpenAI | gpt-4-vision-preview | 视觉理解 | 图像 | P0 |
| OpenAI | gpt-3.5-turbo | 经济型对话 | 否 | P0 |
| Anthropic | claude-3-opus | 高质量对话 | 图像 | P0 |
| Anthropic | claude-3-sonnet | 平衡型对话 | 图像 | P0 |
| Anthropic | claude-3-haiku | 快速响应 | 图像 | P0 |
| Google | gemini-pro | 高质量对话 | 否 | P1 |
| Google | gemini-pro-vision | 多模态理解 | 图像+视频 | P1 |

#### 4.1.5 请求参数说明

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| model | string | 是 | - | 模型 ID |
| messages | array | 是 | - | 对话消息数组 |
| temperature | number | 否 | 0.7 | 随机性，范围 0-2 |
| max_tokens | integer | 否 | 2048 | 最大生成 token 数 |
| stream | boolean | 否 | false | 是否流式输出 |
| top_p | number | 否 | 1.0 | 核采样参数 |
| frequency_penalty | number | 否 | 0 | 频率惩罚 |
| presence_penalty | number | 否 | 0 | 存在惩罚 |
| stop | string/array | 否 | null | 停止序列 |

#### 4.1.6 错误处理

```json
{
  "error": {
    "code": "invalid_api_key",
    "message": "Invalid API key provided",
    "type": "authentication_error",
    "param": null
  }
}
```

**错误码定义**

| HTTP 状态码 | 错误码 | 说明 |
|------------|--------|------|
| 401 | invalid_api_key | API Key 无效 |
| 401 | api_key_expired | API Key 已过期 |
| 403 | insufficient_quota | 配额不足 |
| 429 | rate_limit_exceeded | 请求速率超限 |
| 400 | invalid_request | 请求参数错误 |
| 500 | internal_error | 服务器内部错误 |
| 503 | service_unavailable | 服务暂时不可用 |
| 504 | timeout | 上游服务超时 |

#### 4.1.7 验收标准

- [ ] API 完全兼容 OpenAI 格式，现有 OpenAI SDK 可直接使用
- [ ] 支持同步和流式两种响应模式
- [ ] P95 响应延迟 < 500ms（不含模型推理时间）
- [ ] 正确处理并返回所有错误场景
- [ ] 所有响应包含成本信息
- [ ] 流式响应支持 SSE 格式
- [ ] 支持图像 URL 和 Base64 两种输入方式
- [ ] 正确处理图像大小和格式验证
- [ ] 多模态请求的 token 计算准确（包括 image_tokens）
- [ ] 支持多张图片的批量处理

### 4.2 模型管理

#### 4.2.1 功能描述

提供模型列表查询、模型详情查询、模型状态监控等功能。

#### 4.2.2 API 规格

**获取模型列表**

```http
GET /v1/models
Authorization: Bearer {API_KEY}
```

响应：

```json
{
  "object": "list",
  "data": [
    {
      "id": "gpt-4",
      "object": "model",
      "created": 1699000000,
      "owned_by": "openai",
      "provider": "openai",
      "capabilities": {
        "chat": true,
        "completion": true,
        "embedding": false,
        "vision": false,
        "function_calling": true,
        "image_input": false,
        "video_input": false,
        "audio_input": false
      },
      "pricing": {
        "input": 0.03,
        "output": 0.06,
        "unit": "per_1k_tokens",
        "currency": "USD"
      },
      "context_window": 8192,
      "max_output_tokens": 4096,
      "status": "available",
      "latency_ms": 1200
    }
  ]
}
```

**获取模型详情**

```http
GET /v1/models/{model_id}
Authorization: Bearer {API_KEY}
```

#### 4.2.3 模型状态监控

- **available**: 模型可用
- **degraded**: 模型性能下降
- **unavailable**: 模型不可用
- **maintenance**: 维护中

#### 4.2.4 验收标准

- [ ] 返回所有已接入的模型信息
- [ ] 包含实时的模型状态和延迟信息
- [ ] 提供详细的定价信息
- [ ] 响应时间 < 100ms

### 4.3 认证与鉴权

#### 4.3.1 功能描述

基于 API Key 的认证机制，支持 API Key 的创建、管理、撤销等操作。

#### 4.3.2 用户故事

```
作为一个开发者
我想要创建和管理 API Key
这样我就可以安全地调用 LLM 服务
```

#### 4.3.3 API Key 规格

**格式**: `llmhub-{32位随机字符串}`

示例: `llmhub-sk_1234567890abcdefghijklmnopqrstuv`

**认证方式**:

```http
Authorization: Bearer llmhub-sk_1234567890abcdefghijklmnopqrstuv
```

#### 4.3.4 API Key 管理接口

**创建 API Key**

```http
POST /v1/api-keys
Authorization: Bearer {USER_TOKEN}

{
  "name": "Production Key",
  "expires_at": "2024-12-31T23:59:59Z",
  "permissions": ["chat", "models"],
  "rate_limit": 100
}
```

响应：

```json
{
  "id": "key_123456",
  "name": "Production Key",
  "api_key": "llmhub-sk_1234567890abcdefghijklmnopqrstuv",
  "created_at": "2025-11-16T10:00:00Z",
  "expires_at": "2024-12-31T23:59:59Z",
  "last_used_at": null,
  "status": "active"
}
```

**列出 API Keys**

```http
GET /v1/api-keys
Authorization: Bearer {USER_TOKEN}
```

**撤销 API Key**

```http
DELETE /v1/api-keys/{key_id}
Authorization: Bearer {USER_TOKEN}
```

#### 4.3.5 权限模型

MVP 阶段实现基础的功能权限：

- **chat**: 调用聊天接口
- **models**: 查询模型列表
- **usage**: 查看用量统计

#### 4.3.6 验收标准

- [ ] API Key 创建后立即可用
- [ ] 支持设置过期时间
- [ ] 支持主动撤销
- [ ] 认证失败返回明确的错误信息
- [ ] API Key 前缀脱敏显示（前 8 位）
- [ ] 记录最后使用时间

### 4.4 用量统计

#### 4.4.1 功能描述

实时记录和统计 API 调用量、Token 消费量、成本等信息。

#### 4.4.2 用户故事

```
作为一个开发者
我想要查看我的 API 使用情况和成本
这样我就可以了解资源消耗并控制预算
```

#### 4.4.3 API 规格

**获取用量统计**

```http
GET /v1/usage?start_date=2025-11-01&end_date=2025-11-16&group_by=day
Authorization: Bearer {USER_TOKEN}
```

响应：

```json
{
  "object": "usage.summary",
  "start_date": "2025-11-01",
  "end_date": "2025-11-16",
  "data": [
    {
      "date": "2025-11-16",
      "requests": 1250,
      "tokens": {
        "prompt": 125000,
        "completion": 87500,
        "total": 212500
      },
      "cost": {
        "amount": 6.375,
        "currency": "USD"
      },
      "by_model": {
        "gpt-4": {
          "requests": 450,
          "tokens": 95000,
          "cost": 4.75
        },
        "gpt-3.5-turbo": {
          "requests": 800,
          "tokens": 117500,
          "cost": 1.625
        }
      }
    }
  ],
  "totals": {
    "requests": 18750,
    "tokens": 3187500,
    "cost": 95.625
  }
}
```

**实时用量查询**

```http
GET /v1/usage/current
Authorization: Bearer {USER_TOKEN}
```

响应：

```json
{
  "period": "2025-11",
  "requests_used": 18750,
  "tokens_used": 3187500,
  "cost_incurred": 95.625,
  "quota": {
    "requests_limit": 100000,
    "tokens_limit": 10000000,
    "budget_limit": 500
  },
  "usage_percentage": {
    "requests": 18.75,
    "tokens": 31.875,
    "budget": 19.125
  }
}
```

#### 4.4.4 统计维度

- 按时间（小时/天/月）
- 按模型
- 按 API Key
- 按请求状态（成功/失败）

#### 4.4.5 数据保留

- 详细记录保留 90 天
- 聚合数据永久保留

#### 4.4.6 验收标准

- [ ] 实时更新用量数据（延迟 < 5 秒）
- [ ] 支持多维度查询和聚合
- [ ] 成本计算准确（与上游账单一致）
- [ ] 支持导出 CSV 格式
- [ ] 查询性能 < 500ms

### 4.5 Web 控制台（基础版）

#### 4.5.1 功能描述

提供基础的 Web 管理界面，用于管理 API Key、查看用量统计、测试 API 调用。

#### 4.5.2 核心页面

**4.5.2.1 仪表盘 (Dashboard)**

显示内容：
- 今日请求数、Token 消耗、成本概览
- 最近 7 天趋势图表
- 模型使用分布饼图
- 系统状态指示器

**4.5.2.2 API Keys 管理**

功能：
- 创建新的 API Key
- 查看 API Key 列表
- 查看单个 Key 的详细信息和使用记录
- 撤销 API Key
- 重命名 API Key

**4.5.2.3 用量统计**

功能：
- 选择日期范围查看用量
- 按模型、时间维度筛选
- 数据可视化（图表）
- 导出 CSV 报表

**4.5.2.4 模型列表**

功能：
- 查看所有可用模型
- 查看模型定价和能力
- 查看模型实时状态
- 模型性能指标（延迟、成功率）

**4.5.2.5 API Playground**

功能：
- 在线测试 API 调用
- 选择模型和参数
- 查看请求和响应
- 查看 Token 消耗和成本
- 复制为 cURL/Python/JavaScript 代码

**4.5.2.6 设置**

功能：
- 查看和更新账户信息
- 配置通知设置
- 查看 API 文档链接

#### 4.5.3 UI/UX 要求

**设计原则**：
- 简洁现代的界面设计
- 响应式布局（支持移动端）
- 深色/浅色主题切换
- 快速加载（< 2 秒）

**技术栈建议**：
- 前端框架: React 18+ / Vue 3+
- UI 组件库: Ant Design / Material-UI
- 图表: ECharts / Chart.js
- 状态管理: Zustand / Pinia

#### 4.5.4 验收标准

- [ ] 所有核心页面实现并可正常访问
- [ ] 移动端适配良好
- [ ] 页面加载时间 < 2 秒
- [ ] 所有交互有明确的反馈
- [ ] 错误提示友好且可操作
- [ ] 支持深色模式

### 4.6 多模态支持

#### 4.6.1 功能描述

提供统一的多模态输入接口，支持图像、音频、视频等多种模态数据的处理，让用户能够通过一个 API 接口实现跨模态的智能交互。

#### 4.6.2 用户故事

```
作为一个开发者
我想要在对话中发送图片、音频或视频
这样我就可以构建更丰富的 AI 应用场景
```

#### 4.6.3 支持的模态类型

**4.6.3.1 图像输入 (Image Input)**

功能：
- 图片理解和分析
- OCR 文字识别
- 物体检测和识别
- 场景描述
- 图表数据提取

支持的模型：
- OpenAI: gpt-4-vision-preview
- Anthropic: claude-3-opus, claude-3-sonnet, claude-3-haiku
- Google: gemini-pro-vision

**4.6.3.2 视频输入 (Video Input) - V1.0**

功能：
- 视频内容理解
- 关键帧提取和分析
- 视频摘要生成
- 动作识别

支持的模型：
- Google: gemini-pro-vision

**4.6.3.3 音频输入 (Audio Input) - V1.0**

功能：
- 语音转文字 (STT)
- 音频内容理解
- 情感分析

支持的模型：
- OpenAI: whisper-1

#### 4.6.4 API 规格扩展

**文件上传接口**

```http
POST /v1/files
Content-Type: multipart/form-data
Authorization: Bearer {API_KEY}

file: [binary data]
purpose: "vision" | "audio" | "video"
```

响应：

```json
{
  "id": "file-abc123",
  "object": "file",
  "bytes": 1024000,
  "created_at": 1699000000,
  "filename": "image.jpg",
  "purpose": "vision",
  "status": "uploaded",
  "url": "https://cdn.llmhub.com/files/file-abc123",
  "expires_at": 1699086400
}
```

**使用上传的文件**

```http
POST /v1/chat/completions
Content-Type: application/json
Authorization: Bearer {API_KEY}

{
  "model": "gpt-4-vision-preview",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "What's in this image?"
        },
        {
          "type": "image_file",
          "image_file": {
            "file_id": "file-abc123"
          }
        }
      ]
    }
  ]
}
```

**视频输入示例 (V1.0)**

```http
POST /v1/chat/completions
Content-Type: application/json
Authorization: Bearer {API_KEY}

{
  "model": "gemini-pro-vision",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Summarize what happens in this video"
        },
        {
          "type": "video_url",
          "video_url": {
            "url": "https://example.com/video.mp4"
          }
        }
      ]
    }
  ],
  "max_tokens": 2000
}
```

#### 4.6.5 多模态内容限制

| 模态类型 | 格式支持 | 大小限制 | 时长限制 | 分辨率限制 |
|---------|---------|---------|---------|-----------|
| 图像 | JPEG, PNG, GIF, WebP | 20MB | - | 4096x4096 |
| 视频 | MP4, MOV, AVI | 100MB | 10 分钟 | 1920x1080 |
| 音频 | MP3, WAV, M4A | 25MB | 30 分钟 | - |

#### 4.6.6 成本计算

多模态请求的成本计算包含以下部分：

- **文本 Token**: 按标准价格计算
- **图像 Token**: 根据图像分辨率计算
  - 低分辨率 (512x512以下): 85 tokens
  - 高分辨率: 按 512x512 切块，每块 170 tokens
- **视频 Token**: 按帧数计算，通常为关键帧提取
- **音频 Token**: 按时长计算，约 1 分钟 = 200 tokens

#### 4.6.7 错误处理

新增错误码：

| HTTP 状态码 | 错误码 | 说明 |
|------------|--------|------|
| 400 | invalid_image_format | 不支持的图像格式 |
| 400 | image_too_large | 图像文件过大 |
| 400 | invalid_image_url | 无法访问的图像 URL |
| 400 | video_too_long | 视频时长超限 |
| 400 | unsupported_modality | 模型不支持该模态 |
| 413 | file_too_large | 文件大小超过限制 |

#### 4.6.8 验收标准

- [ ] 支持 URL 和 Base64 两种图像输入方式
- [ ] 支持文件上传接口
- [ ] 正确处理多种图像格式 (JPEG/PNG/GIF/WebP)
- [ ] 图像大小和分辨率验证
- [ ] 多模态 Token 计算准确
- [ ] 单次请求支持多张图片 (最多 10 张)
- [ ] 文件临时存储和自动清理 (24 小时过期)
- [ ] CDN 加速文件访问
- [ ] 详细的错误提示和处理
- [ ] Web 控制台支持多模态测试

## 5. 数据模型设计

### 5.1 核心实体

#### 5.1.1 用户 (User)

```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(100),
  password_hash VARCHAR(255) NOT NULL,
  status ENUM('active', 'suspended', 'deleted') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  INDEX idx_status (status)
);
```

#### 5.1.2 API Key

```sql
CREATE TABLE api_keys (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  key_hash VARCHAR(64) UNIQUE NOT NULL,
  key_prefix VARCHAR(16) NOT NULL,
  name VARCHAR(100),
  permissions JSON,
  rate_limit INT DEFAULT 100,
  status ENUM('active', 'revoked', 'expired') DEFAULT 'active',
  expires_at TIMESTAMP NULL,
  last_used_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user (user_id),
  INDEX idx_key_hash (key_hash),
  INDEX idx_status (status),
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 5.1.3 请求日志 (Request Log)

```sql
CREATE TABLE request_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  request_id VARCHAR(64) UNIQUE NOT NULL,
  user_id BIGINT NOT NULL,
  api_key_id BIGINT NOT NULL,
  model VARCHAR(50) NOT NULL,
  provider VARCHAR(50) NOT NULL,
  prompt_tokens INT NOT NULL,
  completion_tokens INT NOT NULL,
  total_tokens INT NOT NULL,
  input_cost DECIMAL(10, 6) NOT NULL,
  output_cost DECIMAL(10, 6) NOT NULL,
  total_cost DECIMAL(10, 6) NOT NULL,
  latency_ms INT NOT NULL,
  status ENUM('success', 'error', 'timeout') NOT NULL,
  error_code VARCHAR(50),
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user (user_id),
  INDEX idx_api_key (api_key_id),
  INDEX idx_model (model),
  INDEX idx_created (created_at),
  INDEX idx_status (status)
) PARTITION BY RANGE (UNIX_TIMESTAMP(created_at)) (
  PARTITION p202511 VALUES LESS THAN (UNIX_TIMESTAMP('2025-12-01')),
  PARTITION p202512 VALUES LESS THAN (UNIX_TIMESTAMP('2026-01-01')),
  PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

#### 5.1.4 模型配置 (Model Config)

```sql
CREATE TABLE model_configs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  model_id VARCHAR(50) UNIQUE NOT NULL,
  provider VARCHAR(50) NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  capabilities JSON NOT NULL,
  pricing JSON NOT NULL,
  context_window INT NOT NULL,
  max_output_tokens INT NOT NULL,
  status ENUM('available', 'degraded', 'unavailable', 'maintenance') DEFAULT 'available',
  priority INT DEFAULT 100,
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_provider (provider),
  INDEX idx_status (status),
  INDEX idx_enabled (enabled)
);
```

#### 5.1.5 用量聚合 (Usage Aggregation)

```sql
CREATE TABLE usage_daily (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  date DATE NOT NULL,
  model VARCHAR(50) NOT NULL,
  requests INT NOT NULL DEFAULT 0,
  prompt_tokens BIGINT NOT NULL DEFAULT 0,
  completion_tokens BIGINT NOT NULL DEFAULT 0,
  total_tokens BIGINT NOT NULL DEFAULT 0,
  total_cost DECIMAL(12, 6) NOT NULL DEFAULT 0,
  success_count INT NOT NULL DEFAULT 0,
  error_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_date_model (user_id, date, model),
  INDEX idx_user_date (user_id, date),
  INDEX idx_date (date)
);
```

#### 5.1.6 文件存储 (File Storage)

```sql
CREATE TABLE file_storage (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  file_id VARCHAR(64) UNIQUE NOT NULL,
  user_id BIGINT NOT NULL,
  filename VARCHAR(255) NOT NULL,
  content_type VARCHAR(100) NOT NULL,
  file_size BIGINT NOT NULL,
  purpose ENUM('vision', 'audio', 'video', 'document') NOT NULL,
  storage_path VARCHAR(512) NOT NULL,
  cdn_url VARCHAR(512),
  status ENUM('uploading', 'uploaded', 'processing', 'ready', 'expired', 'deleted') DEFAULT 'uploading',
  metadata JSON,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user (user_id),
  INDEX idx_file_id (file_id),
  INDEX idx_status (status),
  INDEX idx_expires (expires_at),
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 5.1.7 请求内容 (Request Content) - 可选

```sql
CREATE TABLE request_contents (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  request_id VARCHAR(64) NOT NULL,
  content_type ENUM('text', 'image', 'video', 'audio') NOT NULL,
  content_data JSON NOT NULL,
  file_id VARCHAR(64),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_request (request_id),
  INDEX idx_file (file_id),
  FOREIGN KEY (request_id) REFERENCES request_logs(request_id)
) PARTITION BY RANGE (UNIX_TIMESTAMP(created_at)) (
  PARTITION p202511 VALUES LESS THAN (UNIX_TIMESTAMP('2025-12-01')),
  PARTITION p202512 VALUES LESS THAN (UNIX_TIMESTAMP('2026-01-01')),
  PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

### 5.2 数据访问层要求

- 使用 R2DBC 实现响应式数据库访问
- 实现连接池管理（最小 10，最大 50）
- 实现读写分离（主库写，从库读）
- 关键查询添加索引优化
- 实现分页查询（默认 20 条/页，最大 100 条/页）

## 6. 技术实现要求

### 6.1 响应式架构实现

#### 6.1.1 WebFlux 配置

```yaml
spring:
  webflux:
    base-path: /v1
  netty:
    threads:
      worker: 16
      selector: 2
```

#### 6.1.2 关键组件

- **Controller**: 使用 `@RestController` 和 `Mono/Flux` 返回类型
- **Service**: 全链路异步，避免阻塞操作
- **HTTP Client**: 使用 `WebClient` 调用上游 LLM API
- **Database**: 使用 R2DBC 驱动实现响应式数据访问

#### 6.1.3 示例代码结构

```java
@RestController
@RequestMapping("/v1")
public class ChatController {
    
    private final ChatService chatService;
    
    @PostMapping("/chat/completions")
    public Mono<ChatCompletionResponse> createChatCompletion(
        @RequestBody ChatCompletionRequest request,
        @RequestHeader("Authorization") String authorization
    ) {
        return chatService.createChatCompletion(request, authorization);
    }
    
    @GetMapping(value = "/chat/completions/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<ChatCompletionChunk>> createChatCompletionStream(
        @RequestBody ChatCompletionRequest request,
        @RequestHeader("Authorization") String authorization
    ) {
        return chatService.createChatCompletionStream(request, authorization);
    }
}
```

### 6.2 LLM 提供商适配器

#### 6.2.1 适配器接口

```java
public interface LLMProvider {
    
    /**
     * Get provider name
     */
    String getProviderName();
    
    /**
     * Get supported models
     */
    List<String> getSupportedModels();
    
    /**
     * Create chat completion
     */
    Mono<ChatCompletionResponse> createChatCompletion(
        ChatCompletionRequest request
    );
    
    /**
     * Create chat completion stream
     */
    Flux<ChatCompletionChunk> createChatCompletionStream(
        ChatCompletionRequest request
    );
    
    /**
     * Check health status
     */
    Mono<HealthStatus> checkHealth();
}
```

#### 6.2.2 需要实现的适配器 (MVP)

1. **OpenAIProvider** - OpenAI API 适配器
2. **AnthropicProvider** - Anthropic Claude 适配器
3. **GoogleProvider** - Google Gemini 适配器

#### 6.2.3 适配器要求

- 统一异常处理和错误映射
- 实现请求重试机制（最多 3 次）
- 实现超时控制（默认 30 秒）
- 记录详细的调用日志
- 实现熔断机制（连续失败 5 次触发）

### 6.3 限流和配额控制

#### 6.3.1 限流策略

使用 Redis + Lua 脚本实现令牌桶算法：

- **API Key 级别**: 默认 100 请求/分钟
- **用户级别**: 默认 500 请求/分钟
- **全局级别**: 5000 请求/分钟

#### 6.3.2 配额控制

- 每月 Token 配额
- 每月费用预算
- 超额后的处理策略（阻止/告警/降级）

### 6.4 监控和日志

#### 6.4.1 监控指标

使用 Micrometer + Prometheus 采集：

- **请求指标**: QPS、延迟分布（P50/P95/P99）、错误率
- **业务指标**: Token 消耗速率、成本/小时、模型使用分布
- **系统指标**: CPU、内存、线程池、连接池
- **上游指标**: 各提供商的可用性、延迟、错误率

#### 6.4.2 日志规范

使用 Logback + ELK Stack：

```json
{
  "timestamp": "2025-11-16T10:00:00.000Z",
  "level": "INFO",
  "trace_id": "abc123",
  "span_id": "def456",
  "service": "llm-hub",
  "logger": "com.llmhub.service.ChatService",
  "message": "Chat completion request",
  "context": {
    "user_id": 12345,
    "api_key_id": 67890,
    "model": "gpt-4",
    "provider": "openai",
    "prompt_tokens": 100,
    "latency_ms": 1200
  }
}
```

#### 6.4.3 分布式追踪

使用 OpenTelemetry 实现：

- 端到端请求追踪
- 跨服务调用追踪
- 性能瓶颈分析

### 6.5 安全要求

#### 6.5.1 传输安全

- 强制 HTTPS（TLS 1.3）
- API Key 不允许在 URL 中传递
- 实现 CORS 配置

#### 6.5.2 数据安全

- API Key 使用 SHA-256 哈希存储
- 用户密码使用 bcrypt 加密
- 敏感日志字段脱敏
- 请求/响应内容不记录到日志（可选开启）

#### 6.5.3 访问控制

- API Key 与用户绑定
- 基于权限的功能访问控制
- IP 白名单（可选）

### 6.6 文件存储和处理

#### 6.6.1 文件存储方案

**存储架构**：
- 本地存储：开发环境使用
- 对象存储：生产环境使用 AWS S3/阿里云 OSS/腾讯云 COS
- CDN 加速：文件访问通过 CDN 分发

**存储策略**：
- 临时文件：24 小时自动过期
- 用户文件：按用户隔离存储
- 分桶存储：按文件类型和日期分桶
- 生命周期管理：自动清理过期文件

#### 6.6.2 文件处理流程

```java
public interface FileProcessor {
    
    /**
     * Upload file
     */
    Mono<FileMetadata> uploadFile(
        FilePart filePart,
        String purpose,
        Long userId
    );
    
    /**
     * Process image (resize, compress, format conversion)
     */
    Mono<ProcessedImage> processImage(
        String fileId,
        ImageProcessOptions options
    );
    
    /**
     * Extract video frames
     */
    Flux<VideoFrame> extractVideoFrames(
        String fileId,
        int frameCount
    );
    
    /**
     * Transcribe audio
     */
    Mono<AudioTranscription> transcribeAudio(
        String fileId
    );
    
    /**
     * Delete expired files
     */
    Mono<Void> cleanupExpiredFiles();
}
```

#### 6.6.3 图像处理

使用 ImageMagick 或 Java ImageIO：

- **格式转换**: 统一转换为 JPEG/PNG
- **尺寸调整**: 超大图片自动缩放到 4096x4096
- **压缩优化**: 保持质量的前提下减小文件大小
- **元数据提取**: EXIF 信息提取

#### 6.6.4 视频处理 (V1.0)

使用 FFmpeg：

- **关键帧提取**: 自动提取关键帧
- **格式转换**: 统一转换为 MP4 格式
- **时长检查**: 验证视频时长
- **缩略图生成**: 生成视频预览图

#### 6.6.5 音频处理 (V1.0)

使用 FFmpeg：

- **格式转换**: 统一转换为 MP3/WAV
- **时长检查**: 验证音频时长
- **比特率调整**: 优化音频质量

#### 6.6.6 CDN 配置

- 回源配置：CDN 回源到对象存储
- 缓存策略：静态文件缓存 7 天
- 访问控制：签名 URL，防止盗链
- HTTPS 支持：强制 HTTPS 访问

#### 6.6.7 安全要求

- 文件类型验证：检查文件 MIME 类型和魔数
- 病毒扫描：上传文件进行安全扫描
- 访问控制：文件访问需要鉴权
- 签名 URL：临时访问链接，限时有效

## 7. 非功能需求

### 7.1 性能要求

| 指标 | 目标值 | 测量方法 |
|------|--------|----------|
| API 响应延迟 (P95) | < 500ms | Prometheus |
| 吞吐量 (单节点) | > 1000 QPS | 压力测试 |
| 并发连接数 | > 5000 | 压力测试 |
| 数据库查询延迟 (P95) | < 50ms | Prometheus |
| 缓存命中率 | > 80% | Redis Monitor |
| 文件上传延迟 (P95) | < 2s (10MB) | Prometheus |
| 图像处理延迟 (P95) | < 1s | Prometheus |
| CDN 命中率 | > 90% | CDN Monitor |

### 7.2 可用性要求

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 系统可用性 | 99.9% | 每月停机时间 < 43 分钟 |
| 故障恢复时间 (MTTR) | < 15 分钟 | 从检测到恢复 |
| 数据备份频率 | 每 6 小时 | 自动备份 |
| 备份保留期 | 30 天 | 可恢复任意时间点 |

### 7.3 扩展性要求

- 支持水平扩展（无状态设计）
- 支持多区域部署
- 支持动态添加新的 LLM 提供商
- 数据库支持分库分表扩展

### 7.4 可维护性要求

- 完整的 API 文档（OpenAPI 3.0 格式）
- 代码覆盖率 > 70%
- 关键路径单元测试覆盖率 > 90%
- 完整的部署和运维文档

## 8. 测试要求

### 8.1 单元测试

- 覆盖所有 Service 层逻辑
- 覆盖所有工具类和帮助类
- Mock 外部依赖
- 使用 JUnit 5 + Mockito

### 8.2 集成测试

- API 接口测试（所有端点）
- 数据库访问测试
- Redis 缓存测试
- 使用 TestContainers

### 8.3 端到端测试

- 完整的用户流程测试
- 真实 LLM 提供商调用测试（使用测试账号）
- 流式响应测试
- 多模态请求端到端测试
- 文件上传和处理流程测试

### 8.4 性能测试

- 使用 JMeter 或 Gatling
- 模拟 1000+ QPS 并发
- 持续 30 分钟以上
- 验证内存泄漏

### 8.5 安全测试

- SQL 注入测试
- XSS 攻击测试
- API Key 安全性测试
- 限流和配额测试

## 9. 发布计划

### 9.1 MVP 里程碑

| 里程碑 | 时间 | 交付内容 |
|--------|------|----------|
| M1: 核心 API | Week 1-4 | Chat Completion API + 模型管理 |
| M2: 认证鉴权 | Week 5-6 | API Key 管理 + 权限控制 |
| M3: 多模态支持 | Week 7-9 | 图像输入 + 文件上传 + 处理 |
| M4: 用量统计 | Week 10-11 | 用量记录 + 统计查询 |
| M5: Web 控制台 | Week 12-14 | 基础管理界面 + 多模态测试 |
| M6: 测试和优化 | Week 15 | 完整测试 + 性能优化 |

### 9.2 发布检查清单

**功能完整性**
- [ ] 所有 P0 功能已实现
- [ ] API 文档已完成
- [ ] 用户手册已完成

**质量保证**
- [ ] 所有测试通过（单元/集成/E2E）
- [ ] 代码审查完成
- [ ] 性能测试达标
- [ ] 安全扫描通过

**运维准备**
- [ ] 部署文档已完成
- [ ] 监控和告警已配置
- [ ] 备份和恢复流程已验证
- [ ] 应急预案已准备

**上线准备**
- [ ] 生产环境已部署
- [ ] 域名和证书已配置
- [ ] CDN 已配置（如需要）
- [ ] 灰度发布计划已制定

## 10. 验收标准

### 10.1 功能验收

- [ ] 所有 MVP 核心功能正常工作
- [ ] API 兼容 OpenAI SDK
- [ ] 支持至少 3 个 LLM 提供商
- [ ] 支持至少 3 个多模态模型
- [ ] 文件上传功能正常工作
- [ ] 图像输入（URL 和 Base64）正常工作
- [ ] 多模态 Token 计算准确
- [ ] Web 控制台所有页面可访问

### 10.2 性能验收

- [ ] 单机 QPS > 1000
- [ ] P95 延迟 < 500ms
- [ ] 并发连接数 > 5000
- [ ] 系统可用性 > 99.9%

### 10.3 安全验收

- [ ] 通过安全扫描（无高危漏洞）
- [ ] API Key 安全存储
- [ ] 传输加密（HTTPS）
- [ ] 限流和配额正常工作

### 10.4 用户体验验收

- [ ] API 调用成功率 > 99%
- [ ] 错误信息清晰易懂
- [ ] Web 界面响应流畅
- [ ] 文档完整准确

## 11. 风险和依赖

### 11.1 技术风险

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 上游 API 不稳定 | 高 | 实现重试和故障转移 |
| 响应式编程学习曲线 | 中 | 团队培训，代码审查 |
| 性能达不到预期 | 中 | 提前进行压力测试 |
| 数据库性能瓶颈 | 中 | 使用 Redis 缓存 |
| 文件存储成本超预期 | 中 | 实施文件生命周期管理，自动清理 |
| 图像处理性能瓶颈 | 中 | 使用异步处理，引入消息队列 |
| 多模态 API 兼容性问题 | 中 | 充分测试各提供商差异，做好适配 |

### 11.2 外部依赖

| 依赖 | 提供方 | 风险等级 | 备选方案 |
|------|--------|---------|----------|
| OpenAI API | OpenAI | 低 | Anthropic |
| Anthropic API | Anthropic | 低 | OpenAI |
| MySQL 数据库 | 自建 | 低 | PostgreSQL |
| Redis 缓存 | 自建 | 低 | Memcached |
| 对象存储 | AWS S3/阿里云 OSS | 低 | 本地存储/其他云存储 |
| CDN 服务 | CloudFlare/阿里云 CDN | 低 | 直连对象存储 |
| FFmpeg | 开源 | 低 | 云端视频处理服务 |

### 11.3 进度风险

- 响应式编程实现复杂度超预期：预留 2 周 buffer
- 多提供商适配工作量大：并行开发，优先 P0 提供商
- 多模态功能开发复杂度高：分阶段实现，MVP 先支持图像
- 文件存储和处理技术栈不熟悉：提前技术预研和 POC
- 前端开发进度落后：考虑使用现成模板

## 12. 术语表

| 术语 | 说明 |
|------|------|
| LLM | Large Language Model，大语言模型 |
| API Key | 用于身份验证的密钥 |
| Token | LLM 处理的最小文本单位 |
| Prompt | 发送给 LLM 的输入文本 |
| Completion | LLM 生成的输出文本 |
| Temperature | 控制生成随机性的参数 (0-2) |
| Top-p | 核采样参数，控制生成多样性 |
| Streaming | 流式输出，逐步返回结果 |
| SSE | Server-Sent Events，服务器推送事件 |
| Rate Limit | 速率限制，限制请求频率 |
| Quota | 配额，限制使用量 |
| WebFlux | Spring 的响应式 Web 框架 |
| R2DBC | 响应式关系型数据库连接 |
| Multimodal | 多模态，支持多种输入形式（文本、图像、音频、视频） |
| Vision | 视觉能力，模型可以理解和分析图像 |
| OCR | Optical Character Recognition，光学字符识别 |
| Base64 | 一种编码方式，用于在文本中嵌入二进制数据 |
| CDN | Content Delivery Network，内容分发网络 |
| Object Storage | 对象存储，用于存储大量非结构化数据 |
| FFmpeg | 开源的音视频处理工具 |
| Image Token | 图像 Token，用于计算图像处理的成本 |

## 13. 附录

### 13.1 参考文档

- [MRD.md](./MRD.md) - 市场需求文档
- [TDD.md](./TDD.md) - 技术设计文档
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [Anthropic API Reference](https://docs.anthropic.com/claude/reference)
- [Spring WebFlux Documentation](https://docs.spring.io/spring-framework/reference/web/webflux.html)

### 13.2 变更记录

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| v1.0 | 2025-11-16 | 初始版本 | - |
| v1.1 | 2025-11-16 | 增加多模态支持（图像、视频、音频输入） | - |

---

**文档状态**: 待审批
**下一步**: 技术设计文档 (TDD)
**审批人**: [待填写]
