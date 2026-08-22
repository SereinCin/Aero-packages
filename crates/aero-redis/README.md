# aero-redis

Redis 客户端（纯 Aero 实现 RESP 协议），无 C 依赖。

## 安装

```bash
aero install aero-redis
```

会自动一并安装其依赖 `aero-http`、`aero-tcp`。

## 用法

```aero
let fd = redis_connect("127.0.0.1", 6379);
redis_set(fd, "name", "aero");
let v = redis_get(fd, "name");      // "aero"
let n = redis_del(fd, "name");      // 1
redis_incr(fd, "counter");          // 1
redis_close(fd);
```

## API

| 函数 | 说明 |
|------|------|
| `redis_connect(host, port) -> i64` | 连接，返回 fd（-1 失败） |
| `redis_close(fd)` | 关闭连接 |
| `redis_set(fd, key, value) -> i32` | SET，0 成功 |
| `redis_get(fd, key) -> str` | GET，返回 value（不存在为空串） |
| `redis_del(fd, key) -> i64` | DEL，返回删除数量 |
| `redis_incr(fd, key) -> i64` | INCR，返回新值 |
| `redis_cmd2 / redis_cmd3` | 通用两/三参数命令 |

## 备注

- RESP 协议（Simple String / Error / Integer / Bulk / Array）全部在 Aero 内解析。
- v1 限制：单次 `recv` 读取响应，适合小值；超大响应需后续增强。
