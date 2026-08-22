# aero-tcp

TCP 网络库（Aero 语言实现）。

## 依赖的系统库

| 平台 | 系统库 | 说明 |
|------|--------|------|
| Windows | `ws2_32` | Winsock2（Aero.toml `[link].libs = ["ws2_32"]`） |
| Linux / macOS | 无（libc 内置） | POSIX socket 直接可用，无需显式链接 |

## 安装

```bash
aero install aero-tcp
```

## 用法

```aero
let s = tcp_connect("127.0.0.1", 8080);
tcp_send(s, "hello");
let reply = tcp_recv_str(s, 1024);
tcp_close(s);
```

## 备注

- 仅 64 位；Windows 需 Win10+（自带 ws2_32）。
- FFI 声明位于 `src/lib.aero` 顶部，链接由 `[link]` 配置自动完成。
