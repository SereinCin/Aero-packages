# aero-sqlite

SQLite FFI 驱动（Aero 语言 + C shim），支持打开数据库、执行 DDL/DML、SELECT 查询。

## 安装

```bash
aero install aero-sqlite
```

本包**自包含**：包内已预编译并静态链接好 Windows x64 的全部依赖（C shim +
完整 SQLite），无需安装 sqlite3、无需 C 工具链，装完即可 `aero run`。

## 依赖

| 依赖 | 来源 | 说明 |
|------|------|------|
| `libaero_sqlite_shim.a` | 包内 `shim/` | Aero 友好封装（源码 `shim/aero_sqlite_shim.c`） |
| `libsqlite3.a` | 包内 `shim/` | SQLite 完整实现，静态链接、零外部符号 |

`Aero.toml` 的 `[link]` 使用相对路径（`lib_paths = ["shim"]`），工具链会相对本包根
自动解析，用户无需手工改任何路径。

> 当前仅发布 Windows x64 预编译库；其它平台请自行编译 `shim/aero_sqlite_shim.c`
> 并按平台重链接 sqlite3。

## 用法

```aero
let db = sqlite_open(":memory:");
sqlite_exec(db, "CREATE TABLE t(x INTEGER)");
sqlite_exec(db, "INSERT INTO t VALUES (42)");
let rows = sqlite_query(db, "SELECT x FROM t");
print(rows);   // "42"
sqlite_close(db);
```

## API

| 函数 | 说明 |
|------|------|
| `sqlite_open(path: str) -> i64` | 打开/创建数据库，`":memory:"` 为内存库；失败返回 `-1` |
| `sqlite_exec(db: i64, sql: str) -> i32` | 执行 DDL/DML；`0` 成功，`-1` 失败 |
| `sqlite_query(db: i64, sql: str) -> str` | 执行 SELECT，返回 `"a,b;c,d"`（行 `;` 列 `,`） |
| `sqlite_close(db: i64) -> i32` | 关闭数据库 |

## 备注

- 仅 64 位 Windows。
- 底层经 `sqlite3_open/exec/prepare/step`，查询结果以文本 CSV 风格返回（v1 约定）。
