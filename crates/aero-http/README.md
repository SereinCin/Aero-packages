# aero-http

HTTP/1.1 基础库（Aero 语言实现），提供请求解析、响应构建、客户端 GET 与服务端组合所需工具。

## 安装

```bash
aero install aero-http
```

会自动一并安装其依赖 [aero-tcp](../aero-tcp)。

## 依赖

| 依赖 | 说明 |
|------|------|
| `aero-tcp` | socket 传输层（FFI，Windows 链接 `ws2_32`） |

## 用法

```aero
// 客户端
let code = http_get("example.com", 80, "/");
print("status=%d\n", code);

// 服务端：tcp accept 循环里解析请求 + 构建响应
let req = http_parse_request(raw);       // HttpRequest {method, path, ...}
let h = http_header(raw, "Content-Length");
let resp = http_response(200, "text/plain", "hello");
```

## API

| 函数 | 说明 |
|------|------|
| `http_parse_request(s) -> HttpRequest` | 解析请求行与头部 |
| `http_header(s, name) -> str` | 取指定请求头 |
| `http_response(status, content_type, body) -> String` | 构建 HTTP 响应（自动 Content-Length） |
| `http_parse_status(s) -> i32` | 从响应文本解析状态码 |
| `http_find_byte / http_find_sub` | 字节/子串查找（-1 = 未找到） |
| `http_get(host, port, path) -> i32` | 发起 GET 返回状态码 |
| `http_recv_str(fd, max) -> String` | 从 socket 读满一帧文本 |

## 备注

- 纯字符串解析，零 C 依赖；链接由 `aero-tcp` 的 `[link]` 自动完成。
- 服务端架构：用 `aero-tcp` 建 `listen/accept`，每连接解析 + 分发（参见 `aero-web`）。
