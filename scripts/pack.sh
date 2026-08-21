#!/bin/bash
# Aero-packages 打包脚本
# 用法: ./scripts/pack.sh v1.2.0
#
# 三个已确认的决定:
#   1. description 来自脚本内硬编码映射表（初期最快，包多了再迁移 Aero.toml）
#   2. 打包时 cd 进 crate 目录，zip 顶层直接是 Aero.toml + src/（解压后不多一层）
#   3. 顺便计算每个 zip 的 SHA256 写入 packages.json（checksum 格式从开始就定好）
#
# 产物: dist/<name>.zip + dist/packages.json

set -euo pipefail

VERSION="${1:?用法: ./scripts/pack.sh v1.2.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
REPO="SereinCin/Aero-packages"

mkdir -p "$DIST"

# ---- 硬编码 description 映射表（初期最快方案）----
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
    aero-regex)     echo "正则表达式引擎" ;;
    aero-http)      echo "HTTP 客户端和服务端" ;;
    aero-toml)      echo "TOML 解析" ;;
    aero-dns)       echo "DNS 查询（UDP）" ;;
    aero-websocket) echo "WebSocket 协议" ;;
    aero-compress)  echo "压缩（zlib FFI）" ;;
    aero-zip)       echo "ZIP 归档" ;;
    aero-tar)       echo "TAR 归档" ;;
    aero-tls)       echo "TLS（OpenSSL FFI）" ;;
    *)              echo "" ;;
  esac
}

echo "==> 打包版本: $VERSION"

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

# ---- 生成 packages.json（含 SHA256 checksum + 硬编码 description）----
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
    cat <<EOF
    {
      "name": "$name",
      "version": "$ver",
      "description": "$descr",
      "author": "Aero Team",
      "download_url": "https://github.com/$REPO/releases/download/$VERSION/${name}.zip",
      "checksum": "$checksum"
    }
EOF
  done
  echo "  ]"
  echo "}"
} > "$JSON"

echo "==> 完成: $DIST/"
echo "    packages.json + $(ls "$DIST"/*.zip 2>/dev/null | wc -l) 个 zip"
