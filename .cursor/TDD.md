# LLM Hub - 技术设计文档 (TDD)

## 1. 文档信息

- **文档版本**: v1.0
- **创建日期**: 2025-11-16
- **最后更新**: 2025-11-16
- **产品名称**: LLM Hub
- **版本**: MVP (v0.1)
- **技术负责人**: [待填写]
- **关联文档**: [PRD.md](./PRD.md)

## 2. 技术架构概述

### 2.1 架构设计原则

- **响应式架构**: 全链路异步非阻塞，基于 Spring WebFlux + R2DBC
- **微服务就绪**: 模块化设计，支持未来拆分
- **高可用性**: 无状态设计，支持水平扩展
- **可观测性**: 完整的监控、日志、追踪体系
- **安全性**: 多层安全防护，数据加密存储

### 2.2 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Layer                          │
│  (Web Console / API Clients / SDK)                          │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Rate Limit │  │  Auth Filter │  │  Logging     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Spring WebFlux (Reactive Controllers)              │   │
│  │  - ChatController                                    │   │
│  │  - ModelController                                   │   │
│  │  - ApiKeyController                                  │   │
│  │  - UsageController                                   │   │
│  │  - FileController                                    │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ ChatService  │  │ ModelService  │  │ AuthService  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │UsageService  │  │ FileService  │  │RouteService  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   Provider Adapter Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │OpenAIProvider│  │AnthropicProv │  │GoogleProvider│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐                         │
│  │CircuitBreaker│  │RetryHandler │                         │
│  └──────────────┘  └──────────────┘                         │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   R2DBC      │  │    Redis     │  │ Object Store │      │
│  │   (MySQL)    │  │   (Cache)    │  │  (S3/OSS)    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 技术栈选型

| 层级 | 技术选型 | 版本 | 说明 |
|------|---------|------|------|
| 语言 | Java | 17+ | LTS版本，支持响应式编程 |
| 框架 | Spring Boot | 3.1+ | 支持WebFlux和R2DBC |
| Web框架 | Spring WebFlux | 3.1+ | 响应式Web框架 |
| 数据库访问 | R2DBC | 1.0+ | 响应式数据库驱动 |
| 数据库 | MySQL | 8.0+ | 主数据库 |
| 缓存 | Redis | 7.0+ | 缓存和限流 |
| 对象存储 | AWS S3/阿里云OSS | - | 文件存储 |
| HTTP客户端 | WebClient | - | 响应式HTTP客户端 |
| 监控 | Micrometer + Prometheus | - | 指标采集 |
| 日志 | Logback + ELK | - | 日志收集 |
| 追踪 | OpenTelemetry | - | 分布式追踪 |
| 图像处理 | ImageMagick/Java ImageIO | - | 图像处理 |
| 视频处理 | FFmpeg | - | 视频处理（V1.0） |

## 3. 模块设计

### 3.1 模块划分

基于现有项目结构，结合响应式架构要求，模块划分如下：

```
llm-hub/
├── app/
│   ├── bootstrap/              # 启动模块
│   ├── biz/
│   │   ├── web/                # Web层（Controller）
│   │   ├── service-impl/       # 业务服务实现
│   │   └── shared/             # 业务共享代码
│   ├── core/
│   │   ├── service/            # 核心服务接口
│   │   └── model/              # 核心领域模型
│   └── common/
│       ├── dal/                # 数据访问层（R2DBC）
│       ├── service/
│       │   ├── facade/         # 服务门面
│       │   └── integration/    # 外部集成（LLM Provider）
│       └── util/               # 工具类
└── app/test/                   # 测试模块
```

### 3.2 核心模块详细设计

#### 3.2.1 Web层 (app/biz/web)

**职责**: 处理HTTP请求，参数验证，响应格式化

**关键类**:
- `ChatController`: 处理聊天完成请求
- `ModelController`: 模型列表和详情查询
- `ApiKeyController`: API Key管理
- `UsageController`: 用量统计查询
- `FileController`: 文件上传和管理

**设计要点**:
- 所有Controller使用`@RestController`和`Mono/Flux`返回类型
- 统一异常处理（`@ControllerAdvice`）
- 请求参数验证（`@Valid`）
- 响应格式统一封装

#### 3.2.2 Shared层 (app/biz/shared)

**职责**: 业务逻辑实现，编排调用

**关键类**:
- `ChatServiceImpl`: 聊天服务实现
- `ModelServiceImpl`: 模型服务实现
- `ApiKeyServiceImpl`: API Key服务实现
- `UsageServiceImpl`: 用量统计服务实现
- `FileServiceImpl`: 文件服务实现
- `RouteServiceImpl`: 智能路由服务（V1.0）

**设计要点**:
- 全链路异步，避免阻塞操作
- 使用`Mono`和`Flux`进行响应式编程
- 事务管理（R2DBC事务）
- 业务异常统一处理

#### 3.2.3 Integration层 (app/common/service/integration)

**职责**: LLM提供商适配器实现

**关键接口和类**:
- `LLMProvider`: 提供商接口
- `OpenAIProvider`: OpenAI适配器
- `AnthropicProvider`: Anthropic适配器
- `GoogleProvider`: Google适配器
- `ProviderFactory`: 提供商工厂
- `CircuitBreaker`: 熔断器实现
- `RetryHandler`: 重试处理器

**设计要点**:
- 统一适配器接口，便于扩展
- 实现重试、熔断、超时控制
- 统一错误映射
- 支持流式响应转发

#### 3.2.4 DAL层 (app/common/dal)

**职责**: 数据访问，使用R2DBC

**关键类**:
- `UserRepository`: 用户数据访问
- `ApiKeyRepository`: API Key数据访问
- `RequestLogRepository`: 请求日志数据访问
- `ModelConfigRepository`: 模型配置数据访问
- `UsageRepository`: 用量数据访问
- `FileStorageRepository`: 文件存储数据访问

**设计要点**:
- 使用R2DBC Repository模式
- 连接池配置（最小10，最大50）
- 读写分离支持
- 分页查询实现

#### 3.2.5 Core Model层 (app/core/model)

**职责**: 核心领域模型定义

**关键类**:
- `User`: 用户实体
- `ApiKey`: API Key实体
- `RequestLog`: 请求日志实体
- `ModelConfig`: 模型配置实体
- `UsageAggregation`: 用量聚合实体
- `FileStorage`: 文件存储实体
- `ChatCompletionRequest/Response`: 聊天请求/响应模型
- `ChatCompletionChunk`: 流式响应块模型

## 4. 详细技术设计

### 4.1 响应式架构实现

#### 4.1.1 WebFlux配置

```yaml
spring:
  webflux:
    base-path: /v1
  netty:
    threads:
      worker: 16
      selector: 2
```

#### 4.1.2 Controller示例

```java
@RestController
@RequestMapping("/v1/chat")
public class ChatController {
    
    private final ChatService chatService;
    
    @PostMapping("/completions")
    public Mono<ResponseEntity<ChatCompletionResponse>> createChatCompletion(
        @Valid @RequestBody ChatCompletionRequest request,
        @RequestHeader("Authorization") String authorization
    ) {
        return chatService.createChatCompletion(request, authorization)
            .map(ResponseEntity::ok)
            .onErrorResume(this::handleError);
    }
    
    @PostMapping(value = "/completions", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<ChatCompletionChunk>> createChatCompletionStream(
        @Valid @RequestBody ChatCompletionRequest request,
        @RequestHeader("Authorization") String authorization
    ) {
        return chatService.createChatCompletionStream(request, authorization)
            .map(chunk -> ServerSentEvent.<ChatCompletionChunk>builder()
                .data(chunk)
                .build());
    }
}
```

#### 4.1.3 Service层响应式实现

```java
@Service
public class ChatServiceImpl implements ChatService {
    
    private final ProviderFactory providerFactory;
    private final RequestLogService requestLogService;
    private final UsageService usageService;
    
    @Override
    public Mono<ChatCompletionResponse> createChatCompletion(
        ChatCompletionRequest request,
        String authorization
    ) {
        return Mono.fromCallable(() -> extractApiKey(authorization))
            .flatMap(apiKeyService::validateApiKey)
            .flatMap(apiKey -> checkRateLimit(apiKey))
            .flatMap(apiKey -> {
                LLMProvider provider = providerFactory.getProvider(request.getModel());
                return provider.createChatCompletion(request)
                    .doOnNext(response -> {
                        // 异步记录日志和用量
                        requestLogService.logRequest(request, response, apiKey)
                            .subscribe();
                        usageService.recordUsage(apiKey, response)
                            .subscribe();
                    });
            })
            .timeout(Duration.ofSeconds(30))
            .onErrorResume(this::handleError);
    }
}
```

### 4.2 LLM提供商适配器设计

#### 4.2.1 适配器接口

```java
public interface LLMProvider {
    
    /**
     * Get provider name
     */
    String getProviderName();
    
    /**
     * Get supported models
     */
    Mono<List<String>> getSupportedModels();
    
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
    
    /**
     * Check if model is supported
     */
    boolean supportsModel(String modelId);
}
```

#### 4.2.2 OpenAI适配器实现

```java
@Component
public class OpenAIProvider implements LLMProvider {
    
    private final WebClient webClient;
    private final CircuitBreaker circuitBreaker;
    private final RetryHandler retryHandler;
    
    @Override
    public Mono<ChatCompletionResponse> createChatCompletion(
        ChatCompletionRequest request
    ) {
        OpenAIRequest openAIRequest = convertRequest(request);
        
        return circuitBreaker.execute(() ->
            webClient.post()
                .uri("/v1/chat/completions")
                .bodyValue(openAIRequest)
                .retrieve()
                .bodyToMono(OpenAIResponse.class)
                .retryWhen(retryHandler.createRetrySpec())
                .timeout(Duration.ofSeconds(30))
        )
        .map(this::convertResponse);
    }
    
    @Override
    public Flux<ChatCompletionChunk> createChatCompletionStream(
        ChatCompletionRequest request
    ) {
        OpenAIRequest openAIRequest = convertRequest(request);
        openAIRequest.setStream(true);
        
        return circuitBreaker.execute(() ->
            webClient.post()
                .uri("/v1/chat/completions")
                .bodyValue(openAIRequest)
                .retrieve()
                .bodyToFlux(String.class)
                .retryWhen(retryHandler.createRetrySpec())
                .timeout(Duration.ofSeconds(60))
        )
        .filter(line -> line.startsWith("data: "))
        .map(line -> line.substring(6))
        .filter(line -> !line.equals("[DONE]"))
        .map(this::parseChunk);
    }
}
```

#### 4.2.3 熔断器实现

```java
@Component
public class CircuitBreaker {
    
    private final Map<String, io.github.resilience4j.circuitbreaker.CircuitBreaker> breakers;
    
    public <T> Mono<T> execute(Supplier<Mono<T>> supplier) {
        String providerName = getCurrentProvider();
        io.github.resilience4j.circuitbreaker.CircuitBreaker breaker = 
            breakers.computeIfAbsent(providerName, this::createCircuitBreaker);
        
        return Mono.fromCallable(() -> 
            breaker.executeSupplier(() -> supplier.get().block())
        )
        .flatMap(Function.identity());
    }
    
    private io.github.resilience4j.circuitbreaker.CircuitBreaker createCircuitBreaker(String name) {
        CircuitBreakerConfig config = CircuitBreakerConfig.custom()
            .failureRateThreshold(50)
            .waitDurationInOpenState(Duration.ofSeconds(30))
            .slidingWindowSize(10)
            .minimumNumberOfCalls(5)
            .build();
        
        return CircuitBreaker.of(name, config);
    }
}
```

#### 4.2.4 重试处理器

```java
@Component
public class RetryHandler {
    
    public RetryBackoffSpec createRetrySpec() {
        return Retry.backoff(3, Duration.ofSeconds(1))
            .filter(this::isRetryableError)
            .doBeforeRetry(retrySignal -> 
                log.warn("Retrying request, attempt: {}", retrySignal.totalRetries() + 1)
            );
    }
    
    private boolean isRetryableError(Throwable throwable) {
        if (throwable instanceof WebClientResponseException) {
            WebClientResponseException ex = (WebClientResponseException) throwable;
            int statusCode = ex.getStatusCode().value();
            // 5xx错误和429错误可重试
            return statusCode >= 500 || statusCode == 429;
        }
        if (throwable instanceof TimeoutException) {
            return true;
        }
        return false;
    }
}
```

### 4.3 数据访问层设计

#### 4.3.1 R2DBC配置

```yaml
spring:
  r2dbc:
    url: r2dbc:mysql://localhost:3306/llmhub
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    pool:
      initial-size: 10
      max-size: 50
      max-idle-time: 30m
```

#### 4.3.2 Repository示例

```java
@Repository
public interface ApiKeyRepository extends ReactiveCrudRepository<ApiKey, Long> {
    
    Mono<ApiKey> findByKeyHash(String keyHash);
    
    Flux<ApiKey> findByUserIdAndStatus(Long userId, String status);
    
    Mono<ApiKey> findByKeyPrefix(String keyPrefix);
}
```

#### 4.3.3 自定义Repository实现

```java
@Repository
public class RequestLogRepositoryImpl implements RequestLogRepository {
    
    private final R2dbcEntityTemplate template;
    
    @Override
    public Flux<RequestLog> findByUserIdAndDateRange(
        Long userId, 
        LocalDate startDate, 
        LocalDate endDate
    ) {
        return template.select(RequestLog.class)
            .matching(Query.query(
                Criteria.where("user_id").is(userId)
                    .and("created_at").between(startDate, endDate)
            ))
            .all();
    }
    
    @Override
    public Mono<Long> countByUserIdAndDateRange(
        Long userId,
        LocalDate startDate,
        LocalDate endDate
    ) {
        return template.select(RequestLog.class)
            .matching(Query.query(
                Criteria.where("user_id").is(userId)
                    .and("created_at").between(startDate, endDate)
            ))
            .count();
    }
}
```

### 4.4 认证与鉴权设计

#### 4.4.1 API Key验证过滤器

```java
@Component
public class ApiKeyAuthenticationFilter implements WebFilter {
    
    private final ApiKeyService apiKeyService;
    
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        String authHeader = exchange.getRequest()
            .getHeaders()
            .getFirst("Authorization");
        
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return handleUnauthorized(exchange);
        }
        
        String apiKey = authHeader.substring(7);
        
        return apiKeyService.validateApiKey(apiKey)
            .flatMap(apiKeyEntity -> {
                // 将API Key信息放入上下文
                exchange.getAttributes().put("api_key", apiKeyEntity);
                return chain.filter(exchange);
            })
            .onErrorResume(e -> handleUnauthorized(exchange));
    }
    
    private Mono<Void> handleUnauthorized(ServerWebExchange exchange) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(HttpStatus.UNAUTHORIZED);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        
        ErrorResponse error = new ErrorResponse(
            "invalid_api_key",
            "Invalid API key provided",
            "authentication_error"
        );
        
        DataBuffer buffer = response.bufferFactory()
            .wrap(JsonUtils.toJson(error).getBytes());
        return response.writeWith(Mono.just(buffer));
    }
}
```

#### 4.4.2 API Key服务实现

```java
@Service
public class ApiKeyServiceImpl implements ApiKeyService {
    
    private final ApiKeyRepository apiKeyRepository;
    private final RedisTemplate<String, String> redisTemplate;
    
    @Override
    public Mono<ApiKey> validateApiKey(String apiKey) {
        // 1. 从缓存查询
        String keyHash = hashApiKey(apiKey);
        return getFromCache(keyHash)
            .cast(ApiKey.class)
            .switchIfEmpty(
                // 2. 从数据库查询
                apiKeyRepository.findByKeyHash(keyHash)
                    .flatMap(key -> {
                        // 验证状态和过期时间
                        if (!isValid(key)) {
                            return Mono.error(new InvalidApiKeyException());
                        }
                        // 3. 写入缓存
                        return cacheApiKey(key)
                            .thenReturn(key);
                    })
            );
    }
    
    private boolean isValid(ApiKey apiKey) {
        if (apiKey.getStatus() != ApiKeyStatus.ACTIVE) {
            return false;
        }
        if (apiKey.getExpiresAt() != null && 
            apiKey.getExpiresAt().isBefore(Instant.now())) {
            return false;
        }
        return true;
    }
}
```

### 4.5 限流设计

#### 4.5.1 令牌桶限流实现

```java
@Component
public class RateLimitService {
    
    private final RedisTemplate<String, String> redisTemplate;
    private final StringRedisTemplate stringRedisTemplate;
    
    private static final String RATE_LIMIT_SCRIPT = 
        "local key = KEYS[1]\n" +
        "local limit = tonumber(ARGV[1])\n" +
        "local window = tonumber(ARGV[2])\n" +
        "local current = redis.call('INCR', key)\n" +
        "if current == 1 then\n" +
        "    redis.call('EXPIRE', key, window)\n" +
        "end\n" +
        "if current > limit then\n" +
        "    return {0, redis.call('TTL', key)}\n" +
        "else\n" +
        "    return {1, limit - current}\n" +
        "end";
    
    public Mono<RateLimitResult> checkRateLimit(String apiKeyId, RateLimitConfig config) {
        String key = "rate_limit:api_key:" + apiKeyId;
        
        return Mono.fromCallable(() -> {
            DefaultRedisScript<List> script = new DefaultRedisScript<>();
            script.setScriptText(RATE_LIMIT_SCRIPT);
            script.setResultType(List.class);
            
            List<Long> result = stringRedisTemplate.execute(
                script,
                Collections.singletonList(key),
                String.valueOf(config.getLimit()),
                String.valueOf(config.getWindowSeconds())
            );
            
            boolean allowed = result.get(0) == 1;
            long remaining = result.get(1);
            
            return new RateLimitResult(allowed, remaining);
        })
        .subscribeOn(Schedulers.boundedElastic());
    }
}
```

#### 4.5.2 限流过滤器

```java
@Component
public class RateLimitFilter implements WebFilter {
    
    private final RateLimitService rateLimitService;
    
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        ApiKey apiKey = (ApiKey) exchange.getAttributes().get("api_key");
        if (apiKey == null) {
            return chain.filter(exchange);
        }
        
        RateLimitConfig config = getRateLimitConfig(apiKey);
        
        return rateLimitService.checkRateLimit(apiKey.getId().toString(), config)
            .flatMap(result -> {
                if (!result.isAllowed()) {
                    return handleRateLimitExceeded(exchange, result);
                }
                
                // 添加限流头信息
                exchange.getResponse().getHeaders().add(
                    "X-RateLimit-Remaining",
                    String.valueOf(result.getRemaining())
                );
                
                return chain.filter(exchange);
            });
    }
}
```

### 4.6 文件存储和处理设计

#### 4.6.1 文件服务接口

```java
public interface FileService {
    
    /**
     * Upload file
     */
    Mono<FileMetadata> uploadFile(
        FilePart filePart,
        String purpose,
        Long userId
    );
    
    /**
     * Get file metadata
     */
    Mono<FileMetadata> getFileMetadata(String fileId);
    
    /**
     * Get file download URL
     */
    Mono<String> getFileUrl(String fileId, Duration expiration);
    
    /**
     * Delete file
     */
    Mono<Void> deleteFile(String fileId)