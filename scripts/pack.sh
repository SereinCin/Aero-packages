#!/bin/bash
# Aero-packages 打包脚本
# 用法: ./scripts/pack.sh v1.2.0
#
# 三个已确认的决定:
#   1. description 来自脚本内硬编码映射表（初期最快，包多了再迁移 Aero.toml）
#   2. 打包时 cd 进 crate 目录，zip 顶层直接是 Aero.toml + src/（解压后不多一层）
#   3. 顺便计算每个 zip 的 SHA256 写入 packages.json（checksum 格式从开始就定好）
#   4. 每个条目按当前 tag 自动填入 requires_aero（如 tag v1.2.0 -> ">=1.2.0"），
#      `aero install` 会据此过滤掉与当前 Aero 版本不兼容的包
#
# 产物: dist/<name>.zip + dist/packages.json

set -euo pipefail

VERSION="${1:?用法: ./scripts/pack.sh v1.2.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
REPO="SereinCin/Aero-packages"

mkdir -p "$DIST"

echo "==> 打包版本: $VERSION"

# ---- 读取 Aero.toml 的 [link].libs（FFI 系统库声明；空 = 纯 Aero）----
# 防坑2: FFI 依赖的系统库必须在 Aero.toml 显式声明，并写入 packages.json 的 system_libs。
system_libs() {  # system_libs <crate_dir>
  local toml="$1/Aero.toml"
  [ -f "$toml" ] || { echo ""; return; }
  # 取 [link] 表下的 libs = [ "...", ... ]，提取逗号分隔的引号字符串
  awk '/^\[link\]/{inlink=1; next} /^\[/{if(inlink) exit} inlink && /libs *=/{print}' "$toml" \
    | sed -E 's/.*libs *= *\[(.*)\].*/\1/' | tr -d '"' | tr -d ' '
}

# ---- 校验: 每个 crate 的 description / requires_aero 不能漏 ----
desc() {
  case "$1" in
    aero-base64)    echo "Base64 编解码" ;;
    aero-hex)       echo "Hex 编解码" ;;
    aero-url)       echo "URL 解析/构建" ;;
    aero-unicode)   echo "Unicode 规范化/大小写" ;;
    aero-log)       echo "结构化日志" ;;
    aero-bench)     echo "微基准框架" ;;
    aero-cli)       echo "命令行解析（clap 风格）" ;;
    aero-config)    echo "多格式配置统一入口" ;;
    aero-yaml)      echo "YAML 子集解析" ;;
    aero-base32)    echo "Base32 编解码" ;;
    aero-base58)    echo "Base58 编解码" ;;
    aero-json)      echo "JSON 解析与生成" ;;
    aero-toml)      echo "TOML 解析与生成" ;;
    aero-csv)       echo "CSV 读写" ;;
    aero-xml)       echo "XML 解析（DOM/流式子集）" ;;
    aero-bson)      echo "BSON 序列化" ;;
    aero-regex)     echo "正则表达式引擎" ;;
    aero-glob)      echo "glob 通配符匹配" ;;
    aero-slug)      echo "字符串 slug 化" ;;
    aero-inflector) echo "命名转换（snake/camel/kebab）" ;;
    aero-levenshtein) echo "编辑距离/相似度" ;;
    aero-html-escape) echo "HTML 转义/反转义" ;;
    aero-html)      echo "轻量 HTML 解析器" ;;
    aero-punycode)  echo "Punycode 编解码" ;;
    aero-mime)      echo "MIME 类型映射" ;;
    aero-serde)     echo "通用序列化框架" ;;
    aero-serde-derive) echo "序列化派生辅助" ;;
    aero-serde-json) echo "serde + JSON 集成" ;;
    aero-serde-yaml) echo "serde + YAML 集成" ;;
    aero-serde-toml) echo "serde + TOML 集成" ;;
    aero-prost)     echo "Protobuf 序列化" ;;
    aero-flatbuffers) echo "FlatBuffers 序列化" ;;
    aero-msgpack)   echo "MessagePack 序列化" ;;
    aero-cbor)      echo "CBOR 序列化" ;;
    aero-ron)       echo "RON 序列化" ;;
    aero-bitvec)    echo "位向量" ;;
    aero-bitset)    echo "位集" ;;
    aero-lru)       echo "LRU 缓存" ;;
    aero-ring-buffer) echo "环形缓冲" ;;
    aero-priority-queue) echo "优先队列" ;;
    aero-trie)      echo "前缀树" ;;
    aero-rope)      echo "分段文本" ;;
    aero-skiplist)  echo "跳表" ;;
    aero-graph)     echo "图结构" ;;
    aero-union-find) echo "并查集" ;;
    aero-dns)       echo "DNS 查询（UDP）" ;;
    aero-websocket) echo "WebSocket 协议" ;;
    aero-compress)  echo "压缩（zlib FFI）" ;;
    aero-zip)       echo "ZIP 归档" ;;
    aero-tar)       echo "TAR 归档" ;;
    aero-tls)       echo "TLS（OpenSSL FFI）" ;;
    *)              echo "" ;;
  esac
}

# 打包前校验：description 不能漏（防坑1）
missing_desc=0
for crate in "$ROOT"/crates/*/; do
  [ -d "$crate" ] || continue
  name="$(basename "$crate")"
  if [ -z "$(desc "$name")" ]; then
    echo "ERROR: no description mapping for $name — add it to desc() in pack.sh" >&2
    missing_desc=1
  fi
  # 防坑2: FFI crate（Aero.toml 声明了 [link]）必须有 README.md 说明系统库
  if [ -n "$(system_libs "$crate")" ] && [ ! -f "$crate/README.md" ]; then
    echo "ERROR: $name declares [link] system libs but has no README.md documenting them" >&2
    missing_desc=1
  fi
done
if [ "$missing_desc" -ne 0 ]; then
  exit 1
fi

# 打包工具：优先用 `zip`（CI/ubuntu 自带）；开发机（Windows）没有 zip 时
# 用 python 的 zipfile 兜底，保证 ./scripts/pack.sh 在本地也能跑通。
make_zip() {  # make_zip <zip_path> <dir>
  if command -v zip >/dev/null 2>&1; then
    ( cd "$2" && zip -qr "$1" ./* )
  else
    python -c '
import sys, zipfile, os
out, root = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for base, dirs, files in os.walk(root):
        for f in files:
            p = os.path.join(base, f)
            z.write(p, os.path.relpath(p, root).replace(os.sep, "/"))
' "$1" "$2"
  fi
}

# ---- 打包所有 crate（进入目录打包，避免多一层 <name>/）----
CRATES=()
for crate in "$ROOT"/crates/*/; do
  [ -d "$crate" ] || continue
  name="$(basename "$crate")"
  CRATES+=("$name")
  make_zip "$DIST/${name}.zip" "$crate"
  echo "    OK ${name}.zip"
done

# ---- 生成 packages.json（SHA256 + description + requires_aero + system_libs）----
JSON="$DIST/packages.json"
{
  echo "{"
  echo '  "schema_version": "1.0",'
  echo '  "packages": ['
  first=true
  for name in "${CRATES[@]}"; do
    if [ "$first" = true ]; then
      first=false
    else
      echo "    ,"
    fi
    checksum="$(sha256sum "$DIST/${name}.zip" | awk '{print $1}')"
    descr="$(desc "$name")"
    ver="${VERSION#v}"
    # 防坑2: FFI 系统库写入 system_libs 字段（纯 Aero 为空）
    slibs="$(system_libs "$ROOT/crates/$name")"
    cat <<EOF
    {
      "name": "$name",
      "version": "$ver",
      "requires_aero": ">=$ver",
      "description": "$descr",
      "author": "Aero Team",
      "system_libs": "$slibs",
      "download_url": "https://github.com/$REPO/releases/download/$VERSION/${name}.zip",
      "checksum": "$checksum"
    }
EOF
  done
  echo "  ]"
  echo "}"
} > "$JSON"

# 防坑1: 校验 packages.json 里每个条目的 requires_aero / description 都不能漏
bad=0
while IFS= read -r name; do
  if ! grep -q "\"name\": \"$name\"" "$JSON"; then
    echo "ERROR: $name missing from packages.json" >&2
    bad=1
    continue
  fi
  if grep -A 20 "\"name\": \"$name\"" "$JSON" | grep -q '"requires_aero": ""'; then
    echo "ERROR: $name has empty requires_aero" >&2
    bad=1
  fi
  if grep -A 20 "\"name\": \"$name\"" "$JSON" | grep -q '"description": ""'; then
    echo "ERROR: $name has empty description" >&2
    bad=1
  fi
done < <(printf '%s\n' "${CRATES[@]}")
if [ "$bad" -ne 0 ]; then
  exit 1
fi

echo "==> 完成: $DIST/"
echo "    packages.json + $(ls "$DIST"/*.zip 2>/dev/null | wc -l) 个 zip"
