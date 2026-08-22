# aero-web

Web 框架（Aero 语言实现），对标 Axum 核心概念：**Router / Extract / Middleware / Serve**。

## 安装

```bash
aero install aero-web
```

会自动一并安装其依赖 `aero-http`、`aero-tcp`。

## 概念映射

| Axum | aero-web |
|------|----------|
| Router | `web_router_new` / `web_route` / `web_route_index` / `web_dispatch` |
| Extract | `web_param`（路径参数 `{id}`）、`web_query`（查询参数 `?q=`） |
| Middleware | `web_mw` / `web_mws` / `web_mw_id`（before 链，可短路由） |
| Serve | `web_serve_conn`（处理一个已连接请求） |

## 用户钩子（必须在 `main.aero` 中定义）

框架通过**同名全局函数**调用你的逻辑，请照此签名实现：

```aero
// 处理器：返回响应 body
fn web_handle(r: &Router, idx: i64, path: str, body: str) -> str {
    // ...
    return "hello";
}

// 中间件：返回 0 继续，非 0 拦截（403）
fn web_middleware(id: i64, method: str, path: str) -> i32 {
    return 0;
}
```

## 用法

```aero
let mut router = web_router_new();
web_route(&mut router, "GET", "/", 0);
web_route(&mut router, "GET", "/users/{id}", 1);
web_mw(&mut router, 1);                       // 挂一个中间件

let server = tcp_socket();
tcp_bind(server, "127.0.0.1", 8080);
tcp_listen(server, 4);
// 每连接：let conn = tcp_accept(server); web_serve_conn(&router, conn);
```

## 备注

- 依赖 `aero-http`（解析/响应）与 `aero-tcp`（socket），三者一起合并链接。
- 未匹配路由返回 404，中间件拦截返回 403（`web_serve_conn` 返回状态码）。
