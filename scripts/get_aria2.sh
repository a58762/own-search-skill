#!/usr/bin/env bash
# get_aria2.sh —— 在本机生成可移植的 aria2c（二进制 + 依赖库），供沙箱/容器重置后仍可用
#
# 背景：apt 装的 /usr/bin/aria2c 在容器重置后会消失，但它依赖的系统库（/lib/x86_64-linux-gnu/）
#       属于基础镜像，不会消失。所以只需把二进制和「非 libc 类」的依赖库复制到本技能目录。
# 依据：英/德/日社区一致推荐 bundle .so + wrapper 设 LD_LIBRARY_PATH（而非静态链接，aria2 无官方 Linux 静态版）
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$DIR/aria2-lib"

if [ -x "$DIR/aria2c-real" ] && [ -d "$LIB" ] && [ "$(ls -1 "$LIB" | wc -l)" -gt 5 ]; then
  echo "已存在，跳过。测试：$DIR/aria2c --version"; exit 0
fi

SRC=""
for c in /usr/bin/aria2c /usr/local/bin/aria2c "$(command -v aria2c 2>/dev/null || true)"; do
  [ -x "$c" ] && SRC="$c" && break
done
if [ -z "$SRC" ]; then
  echo "本机没有 aria2c。请先安装（Debian/Ubuntu: apt-get install -y aria2；macOS: brew install aria2），再重跑本脚本。"
  exit 1
fi

echo "源二进制: $SRC"
cp -f "$SRC" "$DIR/aria2c-real"
mkdir -p "$LIB"
n=0
for lib in $(ldd "$SRC" 2>/dev/null | awk '{print $3}' | grep -v '^\s*$'); do
  b=$(basename "$lib")
  case "$b" in libc.so.*|libm.so.*|ld-linux*) continue ;; esac
  cp -f "$lib" "$LIB/" 2>/dev/null && n=$((n+1))
done
echo "已复制 $n 个依赖库到 $LIB"
"$DIR/aria2c" --version 2>&1 | head -1
echo "可用：scripts/aria2c -x16 -s16 -k4M -o out.bin <url>"
