#!/usr/bin/env bash
# own-search 自检：验证技能脱离 pua-pro 后仍能独立工作
# 用法：bash scripts/selftest.sh
set -u
cd "$(dirname "$0")/.." || exit 4
SELF=$(pwd)
PASS=0
FAIL=0

ok()   { echo "  ok   $1"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL $1"; FAIL=$((FAIL+1)); }

t() {  # t <描述> <命令>
  if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi
}

echo "=== 1. 文件完整性 ==="
for f in SKILL.md README.md CHANGELOG.md LICENSE references/local-index.md \
         scripts/local_search.py scripts/setup_models.sh scripts/refresh.sh \
         scripts/bench_one.py scripts/qwen3_emb.py scripts/source_check.py; do
  [ -f "$SELF/$f" ] && ok "存在 $f" || bad "缺失 $f"
done

echo "=== 2. 语法 ==="
for f in scripts/*.py; do
  python3 -c "import ast,sys;ast.parse(open('$SELF/$f').read())" 2>/dev/null && ok "语法 $(basename $f)" || bad "语法 $(basename $f)"
done
for f in scripts/*.sh; do
  bash -n "$SELF/$f" && ok "语法 $(basename $f)" || bad "语法 $(basename $f)"
done

echo "=== 3. 独立性（不依赖 pua-pro 状态目录）==="
grep -q '\.pua' "$SELF/scripts/local_search.py" && bad "local_search.py 仍引用 .pua 路径" || ok "local_search.py 不引用 .pua"
t "数据目录可自定义" "grep -q OWN_SEARCH_DB '$SELF/scripts/local_search.py'"

echo "=== 4. 下载器（可移植性）==="
if [ -x "$SELF/scripts/aria2c" ]; then
  t "aria2c wrapper 可执行" "'$SELF/scripts/aria2c' --version"
else
  bad "aria2c wrapper 缺失"
fi
t "aria2-lib 库目录存在" "[ -d '$SELF/scripts/aria2-lib' ]"

echo "=== 5. 模型与索引（可选，缺了只提示不打失败）==="
MD="${PUA_GEMMA_DIR:-/sandbox/workspace/models/embeddinggemma300}"
if [ -f "$MD/onnx/model_q4.onnx" ]; then ok "语义模型已就绪"; else echo "  skip 语义模型未安装（bash scripts/setup_models.sh）"; fi
if [ -f "$HOME/.own-search/index.db" ]; then
  N=$(python3 -c "import sqlite3;print(sqlite3.connect('$HOME/.own-search/index.db').execute('select count(*) from docs').fetchone()[0])" 2>/dev/null || echo 0)
  [ "$N" -gt 0 ] && ok "索引有 $N 条文档" || bad "索引为空"
else
  echo "  skip 索引未建立（python3 scripts/local_search.py index）"
fi

echo "=== 6. CLI 接口 ==="
t "stats 子命令可用" "python3 '$SELF/scripts/local_search.py' stats"
t "未知子命令返回非零" "! python3 '$SELF/scripts/local_search.py' nosuchcmd"

echo "-----------------------------------"
echo "通过 $PASS / 失败 $FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
