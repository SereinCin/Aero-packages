# aero-postgres

PostgreSQL v3 wire 协议客户端（纯 Aero 实现，走 `aero-tcp`）。

## 安装

```bash
aero install aero-postgres
```

会自动一并安装其依赖 `aero-http`、`aero-tcp`。

## 用法

```aero
let fd = pg_connect("127.0.0.1", 5432);
pg_send_startup(fd, "postgres", "mydb");
pg_send_query(fd, "SELECT id, name FROM users ORDER BY id");
let r = pg_read_result(fd);      // PgResult { nrows, text, err }
print("rows=%lld text=%s err=%s\n", r.nrows, r.text, r.err);
pg_close(fd);
```

## API

| 函数 | 说明 |
|------|------|
| `pg_connect(host, port) -> i64` | 连接，返回 fd（-1 失败） |
| `pg_send_startup(fd, user, db) -> i32` | 发送启动消息（协议 3.0） |
| `pg_send_query(fd, sql) -> i32` | 发送简单查询 `Q` 消息 |
| `pg_read_result(fd) -> PgResult` | 读取并解析响应 |
| `pg_close(fd)` | 关闭连接 |

`PgResult`：`nrows` 行数、`text`（`"a,b;c,d"`，行 `;` 列 `,`）、`err` 错误信息。

## 备注

- 纯 Aero 协议实现：StartupMessage / Query / RowDescription / DataRow / CommandComplete / ErrorResponse / ReadyForQuery。
- 协议整数为大端网络字节序，手工打包/解析；数据列按文本协议返回。
- v1 限制：仅 `trust` 认证（无 md5/scram 密码认证）；单次 `recv` 读响应。
