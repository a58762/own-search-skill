# CHANGELOG —— own-search

本技能自 pua-pro v5.12 拆分而来（2026-11-26）。以下是检索能力的完整演进史。

## v1.0（2026-11-26）拆分独立

**从 pua-pro 抽出检索部分，成为独立技能**
- 主文件 `SKILL.md` 面向「检索」而非「工作法」，三条铁律换成：不依赖付费 API / 只取一手来源 / 数字成对给
- 依赖收敛：不再需要 pua-pro 的状态目录，开箱即用
- 新增 `scripts/aria2c` + `aria2-lib/`：可移植下载器（二进制 + 依赖库放技能目录，沙箱重置后仍可用）

## 2026-11-26 下载器持久化

- 沙箱重置会清 `/usr/bin/aria2c`（apt 装的），但 `/lib/x86_64-linux-gnu/` 系统库不会消失
- 做法（英/德/日社区一致）：把二进制 + 20 个依赖 .so 放进持久层，wrapper 设 `LD_LIBRARY_PATH`
- libc/libm/ld-linux 不打包（属于基础镜像，硬带会冲突）
- 实测：删掉 `/usr/bin/aria2c` 后 wrapper 仍可用

## 2026-11-25 模型两次换代

**换 EmbeddingGemma-300m（第二次）**
- 先查 HF 一手数据（下载量/点赞=社区用脚投票）：bge-m3 3533万下载/4041赞、embeddinggemma-2 trending 榜首、Harrier 仅 20万/347
- 全部下载实测：Gemma-300m R@1=0.733 > e5-large 0.600 > Harrier 0.567 > MiniLM 0.400 > bge-m3 0.133
- **结论：点赞数和榜单排名都不能直接采信**——bge-m3 赞数第一但实测最差（CLS pooling 对长文档稀释）

**MRL 截断实测**：512 维零损失（省 1/3 存储）、256 维 -3.3pt、64 维 -13.3pt

**换 Harrier（第一次）**
- 2026 Q4 MTEB Multilingual v2 榜首是微软 harrier-oss-v1-27b（27B 放不下），1B 以下最优是 harrier-oss-v1-0.6b（MIT，69.0）

## 2026-11-25 扩源到 20 个地区

- 新增 12 国本地一手社区（韩/意/土/乌克兰/荷/印尼/印度/阿联酋/瑞典/芬兰/匈牙利/挪威），全部实测 200
- 语料 618 → 917 条
- 新增 `source_check.py`（逐源自检）、`coverage_test.py`（18 语种覆盖）

## 2026-11-25 JS 渲染补齐

- 引入 lightpanda 1.0.5（Zig 写的 headless 浏览器，75MB vs Chromium 2GB，快 9–16 倍，CDP 协议）
- 选型依据：fastCRW 的渲染器自动档 `chrome → lightpanda → http`
- `extract_body` 三级：trafilatura → 正文<300字则 lightpanda → 空
- 实测 `react.dev/learn`：trafilatura 0 字 → lightpanda 7,967 字

## 更早（在 pua-pro 时代）

- 语义检索（bge-small-en → MiniLM multilingual，跨语言 0.488 → 0.980）
- 语料扩容（AI 一手源：arXiv / Zenn AI / Qiita AI / Simon Willison / HN-LLM）
- crawl / map（sitemap 优先 + BFS + 静态资源过滤）
- 并发抓取（12 线程，120 篇正文 6 分钟 → 1 分钟）
- SQLite FTS5 + trigram 分词（中/日/英通吃）
- Trafilatura 正文抽取（OSTI 评测 F1 0.937）
