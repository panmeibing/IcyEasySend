# relayd

`relayd` 是 Icy Easy Send 的公网中转服务：当两台设备不在同一个局域网时，由它把两条 HTTPS 请求对接成一条字节流。

它做三件事：

1. **准入**——决定谁可以消耗这台服务器的带宽，以及谁可以声称自己是某个 `deviceId`。
2. **信令**——转发在线状态和设备之间的不透明消息（含配对、文件传输握手、剪切板会话等；服务器不解析内容）。
3. **撮合**——把发送方的 `POST` 和接收方的 `GET` 接成一条管道（文件块与较大剪切板内容共用）。

它**不做**的事同样重要：不解析文件/剪切板内容、不落盘、不缓存、不记录设备名。服务器内存里同时只存在每条流一个 32 KiB 的缓冲区。

---

## 快速开始

```bash
export RELAY_TOKEN="$(openssl rand -base64 48)"
go run ./cmd/relayd
```

服务默认监听 `:8443`，提供这些端点：

| 端点 | 方法 | 用途 |
|---|---|---|
| `/v1/signal` | WebSocket | 信令平面 |
| `/v1/stream/{streamId}` | `POST` / `GET` | 数据平面 |
| `/healthz` | `GET` | 存活探针 |
| `/metrics` | `GET` | Prometheus 指标（勿对公网暴露） |

### 用 Docker 部署

```bash
export RELAY_TOKEN="$(openssl rand -base64 48)"
# 修改 Caddyfile 里的域名后：
docker compose up -d
```

`docker-compose.yml` 里 relayd 只绑定在 `127.0.0.1`，由 Caddy 申请证书并对外暴露 443。**走 443 能穿过绝大多数企业防火墙和酒店网络**，这是推荐配置。

### 用 systemd 部署（裸机）

与 Docker 二选一即可。

```bash
# 1. 构建并安装二进制
CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=0.1.0" -o relayd ./cmd/relayd
sudo install -m 0755 relayd /usr/local/bin/relayd

# 2. 系统用户与配置
sudo useradd --system --home /nonexistent --shell /usr/sbin/nologin relayd
sudo install -d -m 0750 -o root -g relayd /etc/relayd
sudo install -m 0640 -o root -g relayd deploy/relayd.env.example /etc/relayd/relayd.env
# 编辑 /etc/relayd/relayd.env，至少填入 RELAY_TOKEN

# 3. 安装并启动单元
sudo install -m 0644 deploy/relayd.service /etc/systemd/system/relayd.service
sudo systemctl daemon-reload
sudo systemctl enable --now relayd
```

前面仍建议放 Caddy/Nginx 终止 TLS，并把 `RELAY_LISTEN` 设为 `127.0.0.1:8443`。

### 直接跑二进制

```bash
CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=0.1.0" -o relayd ./cmd/relayd
```

产物是静态二进制，无运行时依赖。若不想用反代，设置 `RELAY_TLS_CERT` 与 `RELAY_TLS_KEY` 让 relayd 自己终止 TLS。

---

## 配置

全部通过环境变量，没有配置文件。

| 变量 | 默认值 | 说明 |
|---|---|---|
| `RELAY_LISTEN` | `:8443` | 监听地址 |
| `RELAY_TOKEN` | 无，**必填** | 接入令牌，短于 32 字符直接拒绝启动 |
| `RELAY_TLS_CERT` | 空 | 留空表示在反代后面跑纯 HTTP |
| `RELAY_TLS_KEY` | 空 | 必须与 `RELAY_TLS_CERT` 同时设置 |
| `RELAY_MAX_CONCURRENT_STREAMS` | `8` | 每设备并发流上限 |
| `RELAY_MAX_STREAM_BYTES` | `0` | 单流字节上限，`0` 为不限 |
| `RELAY_RATE_LIMIT_BPS` | `0` | 每设备限速（该设备所有并发流共享），`0` 为不限 |
| `RELAY_STREAM_RENDEZVOUS_TIMEOUT` | `30s` | 一端到达后等待另一端的时间 |
| `RELAY_STREAM_IDLE_TIMEOUT` | `60s` | 无字节流动的空闲超时 |
| `RELAY_PAIR_RATE_PER_MIN` | `5` | 每设备每分钟可发起的配对请求数 |
| `RELAY_LOG_LEVEL` | `info` | `debug` / `info` / `warn` / `error` |

**空闲超时不是总时长超时。** 每搬运一个缓冲区就续一次读写 deadline，因此传 20 GB 的文件不会因为耗时过长被杀掉，只有真正卡住才会断。

### 配额调参建议

自用或少量设备时，保持默认（不限速）通常最好。把服务器借给朋友、或 VPS 上行很窄时再收紧：

| 场景 | 建议 |
|---|---|
| 家用 / 自己几台设备 | `RELAY_RATE_LIMIT_BPS=0`，并发保持 `8` |
| 1–5 人共用小 VPS（例如 50 Mbps 上行） | `RELAY_RATE_LIMIT_BPS` 设为上行字节数的 60%–80%（50 Mbps ≈ `5000000`），`RELAY_MAX_CONCURRENT_STREAMS=4` |
| 需要硬顶单文件体积 | 设 `RELAY_MAX_STREAM_BYTES`（字节）；`0` 表示不限 |
| 配对骚扰 | 下调 `RELAY_PAIR_RATE_PER_MIN`（默认 `5` 已较严） |

`RELAY_RATE_LIMIT_BPS` 按**发送方 deviceId** 共享：同一设备开多条流时，合计吞吐不超过该值，而不是每条流各拿一份。

---

## 指标（Prometheus）

`GET /metrics` 暴露进程指标。compose 只把 `8443` 绑在本机回环上，**公网反代不要转发 `/metrics`**。

常用系列：

| 指标 | 含义 |
|---|---|
| `relayd_build_info{version=...}` | 构建版本 |
| `relayd_signal_sessions` | 当前已认证信令会话数 |
| `relayd_streams_active` | 登记中的流数量 |
| `relayd_streams_created_total` | 累计创建流次数 |
| `relayd_bytes_relayed_total` | 成功搬运的字节数 |
| `relayd_auth_failures_total{reason=...}` | 准入失败（`token` / `identity`） |
| `relayd_errors_total{code=...}` | 协议错误码计数 |
| `relayd_pair_rate_limited_total` | 配对被限流次数 |

指标**不含** `deviceId` 或 IP 标签。

Prometheus scrape 示例：

```yaml
scrape_configs:
  - job_name: relayd
    static_configs:
      - targets: ["127.0.0.1:8443"]
    metrics_path: /metrics
```

---

## 准入：两层，缺一不可

```
客户端                              relayd
  │                                   │
  ├─ Upgrade + Bearer <RELAY_TOKEN> ─→│  第一层：令牌不对直接 401，WS 都不建立
  │←──────── challenge { nonce } ─────┤
  ├─ auth { deviceId, pk, sig } ─────→│  第二层：验签 + 校验 deviceId 是 pk 的指纹
  │←──── welcome { sessionId, ... } ──┤
```

- **只有令牌**：拿到令牌的人可以顶替任意 `deviceId` 上线，抢收别人的文件。
- **只有签名**：任何人都能白嫖这台服务器的带宽。

`deviceId` 定义为 `hex(SHA-256(ed25519_pubkey)[0..15])`，服务端与客户端必须算出完全一致的值，整个防冒充的性质都建立在这上面。

签名内容带域分隔前缀，两种用途的签名互不通用：

| 用途 | 签名内容 |
|---|---|
| 接入认证 | `"icy-relay-auth-v1"` ‖ nonce ‖ deviceId |
| 挂载数据流 | `"icy-relay-stream-v1"` ‖ streamId |

---

## 信令协议

WebSocket 端点 `/v1/signal`，JSON 报文，单条上限 64 KiB。

### 在线状态：双向订阅才可见

```json
→ { "v": 1, "type": "subscribe", "peers": ["a3f2...", "b71c..."] }
← { "v": 1, "type": "presence", "deviceId": "a3f2...", "online": true }
```

服务器**仅在双方互相订阅时**才推送在线状态。单向订阅什么都收不到——否则拿到令牌的人就能枚举探测任意设备是否在线。`presence` 不含设备名，客户端从本地配对记录反查显示名称。

### 不透明消息中继

```json
→ { "v": 1, "type": "relay", "to": "b71c...", "kind": "transfer", "payload": "<base64>" }
← { "v": 1, "type": "relay", "from": "a3f2...", "kind": "transfer", "payload": "<base64>" }
```

服务器只看 `to` / `from`，不解析 `payload`。对端不在线返回 `error { code: "peer_offline" }`，不做离线暂存。

**投递不要求双向订阅**——素未谋面的两台设备必须能完成首次配对。代价是 `kind: "pair"` 的消息单独限流（默认每设备每分钟 5 条，计入该设备发出的所有配对信令，不只 `pair.request`），这也是服务器唯一需要知道的一点分类信息，所以 `kind` 放在 `payload` 外面，不泄露任何内容。剪切板会话与文件传输一样使用 `kind: "transfer"`，共用传输限流桶。

完整客户端协议与配对/剪切板行为见仓库根目录 [`docs/relay-design.md`](../docs/relay-design.md)。

### 分配数据流

```json
→ { "v": 1, "type": "stream.create", "mid": "s-1", "peer": "b71c...", "role": "sender" }
← { "v": 1, "type": "stream.created", "mid": "s-1", "streamId": "<64 hex>", "expiresAt": 1770000030 }
```

`streamId` 绑定到 `(sender, receiver)` 二元组，只有这两个设备能挂载。对端不在线时直接拒绝，避免白占一个并发额度再在撮合阶段超时。

---

## 数据平面

```
POST /v1/stream/{streamId}     # 发送方，chunked body
GET  /v1/stream/{streamId}     # 接收方，chunked response
```

两个方向的请求头相同：

```
Authorization:  Bearer <RELAY_TOKEN>
X-Device-Id:    <deviceId>
X-Stream-Proof: <base64 Ed25519 签名>
```

先到的一方阻塞等待，最长 `RELAY_STREAM_RENDEZVOUS_TIMEOUT`；两端到齐后开始搬运。中间是一个 `io.Pipe`，接收方拉得慢，管道就写不进去，TCP 层反压自然传导回发送方，不需要任何显式流控。

上传成功返回 `{"ok": true, "bytes": N}`。下载中途出错时连接会被直接掐断而不是正常结束——**截断的响应绝不能让接收方看起来像传完了**。

### 反向代理注意事项

Caddy 配置里对 `reverse_proxy` 设置了 `flush_interval -1`，并关闭读写超时，以保证长传与背压。用 Nginx 必须设置：

```nginx
proxy_buffering off;
proxy_request_buffering off;
```

否则它会把整个文件先缓存到磁盘，既违背「服务器不落盘」的设计，也会在传大文件时撑爆磁盘。

---

## 错误码

信令与数据平面共用一套：

| code | HTTP | 含义 |
|---|---|---|
| `unauthorized` | 401 | 接入令牌错误 |
| `bad_identity` | 403 | deviceId 与公钥不匹配，或签名验证失败 |
| `bad_request` | 400 | 报文格式错误 |
| `peer_offline` | 404 | 目标设备不在线 |
| `stream_not_found` | 404 | streamId 不存在或已过期 |
| `stream_forbidden` | 403 | 该 deviceId 不是此流绑定的两端之一 |
| `peer_not_attached` | 504 | 撮合超时 |
| `too_many_streams` | 429 | 超过并发流上限 |
| `payload_too_large` | 413 | 信令消息或流字节超限 |
| `idle_timeout` | 408 | 流空闲超时 |
| `rate_limited` | 429 | 配对请求发送过于频繁 |

---

## 日志与隐私

`info` 级别只记录连接数、流数量、错误码，**不记录 deviceId、IP 或可关联的时间戳**。`debug` 级别才记录 deviceId 的前 8 位。Prometheus 标签同样保持低基数。

这是自建服务，但用户可能把服务器借给朋友用，默认不留可关联的痕迹是合理的。

---

## 发布

`relayd` 与客户端版本号独立，使用 `relay-vX.Y.Z` 标签触发 [`.github/workflows/relay-release.yml`](../.github/workflows/relay-release.yml)：

- Linux `amd64` / `arm64` 静态二进制 + SHA256
- GHCR 容器镜像
- GitHub draft Release

```bash
git tag relay-v0.1.0
git push origin relay-v0.1.0
```

也可在 Actions 里用 `workflow_dispatch` 手动指定版本号（不含 `relay-v` 前缀）。

---

## 开发

```bash
go test ./...           # 全部测试
go test -race ./...     # 竞态检测（CI 里跑的就是这个）
go vet ./...
gofmt -l .              # 应该没有输出
```

目录结构：

```
relay/
├── cmd/relayd/         # 组装与优雅关闭
├── deploy/             # systemd 单元与环境变量示例
├── Dockerfile
├── docker-compose.yml
├── Caddyfile
└── internal/
    ├── config/         # 环境变量解析与启动校验
    ├── protocol/       # 信封、消息类型、错误码
    ├── auth/           # 令牌比对与 Ed25519 挑战应答
    ├── signal/         # WSS hub、在线状态、消息路由
    ├── stream/         # streamId 分配与两端撮合
    ├── limit/          # 配对限流与每设备共享带宽
    └── metrics/        # Prometheus /metrics
```
