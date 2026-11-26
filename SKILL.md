---
name: own-search
description: "自建语料 + 本地索引的检索技能，不依赖任何搜索 API 额度。当需要查技术资料、找各国社区一手内容、抓网页正文、建本地检索库、或遇到 403/402 想绕开付费 API 时使用。含 SQLite FTS5(trigram) 全文检索、多语言向量语义检索（EmbeddingGemma-300m）、RRF 混合检索、Trafilatura 正文抽取、lightpanda JS 渲染、crawl/map 整站抓取、20 个地区语种源。中文触发：自己搜/不依赖API搜/建索引/抓正文/查国外社区/找各国资料/本地检索/离线搜索。"
---

# own-search —— 不借任何人额度的检索

**核心命题**：检索能力的上限不该由某个 API 的额度决定。

三条铁律：
1. **不依赖付费 API**。所有能力都在本地（SQLite + ONNX 模型 + 自家抓取）。
2. **只取一手来源**。不做二手转述站，不收营销号聚合。
3. **数字成对给**。说"更快/更准"必须给出对比基准与设置，不给相对值就等于没说。

---

## 快速开始

```bash
# 0) 首次部署：模型 + JS 渲染器（约 272MB，支持 aria2c 加速）
bash scripts/setup_models.sh

# 1) 建库（抓源 + 补正文 + 生成向量）
python3 scripts/local_search.py index --fetch-body --body-limit 10 --workers 12
python3 scripts/local_search.py embed

# 2) 三种检索
python3 scripts/local_search.py search "关键词"      # BM25，词面精确
python3 scripts/local_search.py sem "自然语言描述"    # 纯语义，跨语言
python3 scripts/local_search.py hybrid "词"          # BM25 + 向量 RRF，**默认推荐**

# 3) 整站抓取
python3 scripts/local_search.py map https://example.com --limit 50
python3 scripts/local_search.py crawl https://example.com --limit 5 --depth 1

# 4) 定时更新（cron 可直接调用）
bash scripts/refresh.sh
```

**为什么默认用 `hybrid`**：纯 `sem` 会被高相似度的英文大站占满（实测 18 语种查询，Top5 里 54/90 是 arXiv），`hybrid` 引入词面匹配后各地本地内容才浮上来（韩文查询能命中土耳其、印度、越南）。

---

## 当前能力（实测数字，不是宣传）

**语料**：917 条 / 20 个地区 / 21+ 源

| 地区 | 源 |
|---|---|
| 日本 | 技術評論社 / Qiita / Zenn（含 AI 专项） |
| 美国 | HN / Phoronix / OSNews / LWN |
| 法国 | Next.ink / LinuxFr |
| 德国 | Golem / Born's Tech |
| 俄罗斯 | Habr（ru/en） |
| 英国 | The Register / Simon Willison |
| 韩国 | Viblo |
| 意大利 | Leganerd |
| 印尼 | detikInet |
| 印度 | Analytics India Mag |
| 土耳其 | Webrazzi |
| 巴西 | TabNews |
| 荷兰 | Bright.nl |
| 西班牙 | Hipertextual |
| 瑞典 | IDG |
| 阿联酋 | AITnews |
| 匈牙利 | Bitport |
| 乌克兰 | DOU |
| 国际 | arXiv cs.AI |

**语义模型选型**（150 条语料 / 30 query / 标题做 query / doc 不含标题）：

| 模型 | 体积 | 维度 | R@1 | R@5 |
|---|---|---|---|---|
| **EmbeddingGemma-300m q4（现用）** | **197MB** | 768 | **0.733** | **0.833** |
| e5-large int8 | 561MB | 1024 | 0.600 | 0.700 |
| Harrier-OSS-V1-0.6B q4 | 399MB | 1024 | 0.567 | 0.767 |
| MiniLM-multilingual | 450MB | 384 | 0.400 | 0.433 |
| bge-m3 int8（HF 赞数第一 4041） | 542MB | 1024 | 0.133 | 0.267 |

**社区赞数与实测强弱不一致**——bge-m3 有 4041 赞，R@1 却只有 0.133（CLS pooling 对长文档稀释严重）。选型一律以 `bench_one.py` 的同条件实测为准。

**MRL 截断**（Gemma 原生支持）：512 维零损失（R@1 与 768 相同），省 1/3 存储；256 维 -3.3pt。语料上万条后再考虑截断。

---

## 按需加载

| 场景 | 读 / 做 |
|---|---|
| 想搞清整体设计与边界 | `references/local-index.md` |
| 检索遇 403 / 站点被封 | `references/community-channels.md`（403 vs DNS 污染 vs IP 阻断三分法 + 检索 API 代抓） |
| 想理解自建搜索与通用搜索引擎的差别 | `references/own-search.md` |
| 换模型 / 加模型前先测 | `python3 scripts/bench_one.py <name>` |
| 验证某个源是否真生效 | `python3 scripts/source_check.py`（每源抽 2 条标题查回自己） |
| 测多语种覆盖 | `python3 scripts/coverage_test.py`（18 语种 × Top5） |
| 测 MRL 截断损失 | `python3 scripts/mrl_test.py` |
| 装模型 / 渲染器 | `bash scripts/setup_models.sh`（有 aria2c 用 aria2c，实测 17MB/s） |
| 下载大文件 | `bash scripts/aria2c -x16 -s16 -k4M <url>`（持久化包装器，沙箱重置后仍可用） |
| 换机器后 aria2 不可用 | `bash scripts/get_aria2.sh`（从本机 aria2c 生成可移植包） |
| 定时更新语料 | `bash scripts/refresh.sh`（目录锁 + 有界抓取） |

---

## 模型推理的坑（换模型必看）

| 模型 | pooling | padding | 前缀 |
|---|---|---|---|
| EmbeddingGemma | mean（mask 加权） | **必须关闭 padding**（ONNX 图对变长 batch 不兼容） | query: `task: search result \| query: `；doc: `title: none \| text: ` |
| Harrier / Qwen3 | last-token | **必须左填充**（右填充会取到 pad 的隐状态） | `Instruct: ...\nQuery: ` |
| bge-m3 / XLM-R | **CLS**（不是 mean） | 右填充 | 无 |
| e5 系列 | mean | 右填充 | `query: ` / `passage: ` |
| Octen | last-token | 左填充 | 无（批维硬编码为 1） |

**评测设计的四个陷阱**（都踩过，改了三次才出正确数字）：
1. `gold` 用数据库 id 而 `topk` 是行号 → 全错
2. query 取自长正文中段，doc 只取前 1200 字 → 那句话不在被检索文本里
3. 取到的"句子"是图注碎片（`図2 images/fig02...`）→ 改用标题做 query
4. doc 含标题 → R@1 假性 1.0（泄漏）

---

## 边界（诚实说）

- **能力上限 = 语料上限**。没抓的源搜不到，这是设计取舍不是缺陷。
- **语义检索的语种均衡度受主题分布限制**：18 语种查询里只有 8 个命中本国内容，因为各国源当期鲜有同一主题。
- **强反爬站点**（Cloudflare 挑战页）过不去，也不打算做。
- **JS 渲染是兜底不是默认**：trafilatura 快得多，只有正文 <300 字才走 lightpanda。
- **无实时性**：语料要 `refresh.sh` 或 cron 更新，默认是上次抓取的快照。

---

## 与其它通道的分工

```
已知源的最新动态      → local_search.py（本地索引，毫秒级，零网络）
任意主题的全网检索     → own_search.py（零成本，但受 Bing 质量限制）
需要语义理解的复杂查询  → sem / hybrid（本地向量）
目标站点被封          → fetch_community.py --source X（检索 API 代抓）
必须绝对时效          → 外部 API（Tavily 等，付费）
```

**顺序**：先查本地（免费且快），没有再往外走。
