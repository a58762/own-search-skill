# own-search —— 自建语料 + 本地索引的检索技能

不依赖任何搜索 API 额度的检索能力。917 条语料 / 20 个地区 / SQLite FTS5 + 多语言向量 + RRF 混合检索。

## 为什么不直接用 API

| | 付费 API（如 Firecrawl / Tavily） | own-search |
|---|---|---|
| 额度 | 402 后停摆 | 无上限 |
| 数据归属 | 在对方服务器 | 本地 SQLite |
| 语义检索 | 有 | 有 |
| 语料可控 | 不可控 | 自己选源 |
| 弱项 | — | 全网覆盖窄、强反爬站过不去 |

## 安装

```bash
git clone https://github.com/a58762/pua-pro-skill.git
cp -r pua-pro-skill/own-search ~/.skills/own-search
cd ~/.skills/own-search
bash scripts/setup_models.sh     # 197MB 模型 + 75MB lightpanda
```

## 目录结构

```
own-search/
├── SKILL.md
├── references/
│   ├── local-index.md          本地索引全设计（FTS5/向量/渲染/crawl-map）
│   ├── community-channels.md   官方 API/RSS 通道 + 403 三分法
│   └── own-search.md           自建搜索的机制与边界
└── scripts/
    ├── local_search.py         主力：index/search/sem/hybrid/embed/crawl/map/stats
    ├── setup_models.sh         下载 EmbeddingGemma-300m + lightpanda
    ├── refresh.sh              语料定时更新（目录锁 + 有界抓取）
    ├── bench_one.py            单模型 self-retrieval 评测
    ├── source_check.py         逐源可用性自检
    ├── coverage_test.py        18 语种覆盖实测
    ├── mrl_test.py             MRL 截断损失测试
    ├── qwen3_emb.py            ONNX 推理器（支持 Gemma/Harrier/bge-m3/e5/Octen）
    ├── dl_chunks.py            分片下载（无 aria2c 时的回退）
    ├── aria2c + aria2-lib/     可移植下载器（含依赖库，沙箱重置后仍可用）
    ├── get_aria2.sh            在新机器上生成可移植 aria2c
    ├── selftest.sh             35 项自检（文件完整/语法/独立性/下载器/索引）
    ├── fetch_community.py      社区一手通道
    ├── own_search.py           零成本 Bing 搜索
    └── search2.py              搜索 v2（加权 RRF + 可解释打分）
```

## 实测数字

| 模型 | 体积 | R@1 | R@5 |
|---|---|---|---|
| **EmbeddingGemma-300m q4** | 197MB | **0.733** | **0.833** |
| e5-large int8 | 561MB | 0.600 | 0.700 |
| Harrier-OSS-V1-0.6B q4 | 399MB | 0.567 | 0.767 |
| bge-m3 int8（HF 赞数第一） | 542MB | 0.133 | 0.267 |

150 条语料 / 30 query / 标题做 query / doc 不含标题。

## 许可

MIT
