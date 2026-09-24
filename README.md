# MoonRetrieve

[![mooncakes.io](https://img.shields.io/badge/mooncakes.io-niuniu513--ask%2FMoonRetrieve-blue)](https://mooncakes.io/packages/niuniu513-ask/MoonRetrieve)
[![CI](https://github.com/niuniu513-ask/MoonRetrieve/actions/workflows/ci.yml/badge.svg)](https://github.com/niuniu513-ask/MoonRetrieve/actions/workflows/ci.yml)

纯 MoonBit 零 FFI 的本地全文检索与 RAG（检索增强生成）检索库。文档在本地完成分词、分块、索引、检索和 LLM 上下文组装，数据不出本地；核心库可编译到 wasm / wasm-gc / js / native 多后端，适合浏览器、边缘设备与隐私敏感场景。

## 与现有 MoonBit 检索项目的差异

- **不重复造“搜索引擎内核”**：区别于 [Lucius646/MoonSearch](https://github.com/Lucius646/MoonSearch)（嵌入式全文检索内核，多 Segment 持久化、Phrase/Boolean 查询），MoonRetrieve 聚焦轻量索引 + 混合检索 + RAG 上下文组装，提供 `Engine` 一站式 API 和开箱即用的 CLI。
- **纯库、零 FFI**：区别于 [houjie/rag-mbt](https://github.com/Mr-Houjie/rag.mbt)（RAG 管线，native 侧依赖 Python/bge 嵌入与 FFI），MoonRetrieve 核心库无任何 FFI，同一套代码跑 wasm-gc / js / native，适合浏览器与受限边缘环境。
- **内置多语言分词**：中/英/日文，中文单字 + bigram（单字查询也能命中），英文停用词与可选词干化，不依赖外部分词服务。
- **混合检索 + 上下文组装**：BM25 倒排索引与余弦向量索引双路检索，RRF 融合排序；`ContextBuilder` 按 token 预算把命中片段拼成带来源编号的 LLM 提示词。

## 功能

- 分词器 `Tokenizer`：英文/中文/日文、N-gram、停用词、词干化
- 分块器 `Chunker`：按段落切分、块间重叠、超长段落硬切
- BM25 索引 `SearchIndex`：增量建索引、Top-K 检索、JSON 持久化
- 倒排驱动 BM25：只为命中文档计分，适合本地较大文档集；[2,000 文档基准与复现方法](docs/performance.md)
- 短语检索 `search_phrase`：查询短语按原文顺序连续出现
- 布尔检索 `search_boolean`：AND / OR / `-term` 排除
- 前缀检索 `search_prefix`：按词条前缀匹配
- 向量索引 `VectorIndex`：余弦相似度检索
- 混合融合 `rrf_fuse`：Reciprocal Rank Fusion
- 上下文组装 `ContextBuilder`：来源去重、分块预算与带引用清单的 `ContextReport`
- 文档级检索评测：标注查询集、逐题排名与 Precision/Recall/MRR/MAP 汇总
- JSONL 批量导入：保留外部文档 ID 与标题，接入已有知识库语料
- 检索诊断轨迹 `Engine::trace`：输出排名、来源、分数、命中/缺失词和原始证据文本
- 结果高亮 `highlight`：查询词自动标记 `**term**`
- 文档删除与统计：`SearchIndex::remove` / `stats`、`Engine::remove_document` / `stats`
- 一站式引擎 `Engine`：文档 → 分块 → 索引 → 检索，支持文档替换和 RAG 上下文构建
- CLI：`index` / `query` / `context` / `evaluate` / `trace` / `stats` / `phrase` / `boolean` / `prefix`
- 结果诊断 CLI：`snippet` 输出限定长度命中片段，`explain` 输出匹配词和覆盖情况

完整的科研摘要检索场景与 300 题公开人工标注评测见 [SciFact 复现说明](docs/scifact.md)。它覆盖导入、查询、引用核对和错误分析；语料需从原始发布方下载，不随本仓库分发。

## 快速开始

环境要求：MoonBit 0.1.20260920+；native 目标需要 C 编译器（Windows 用 MSVC）。

```bash
# 添加依赖
moon add niuniu513-ask/MoonRetrieve
```

库用法：

```moonbit
let engine = @lib.Engine::new()
engine.add_document("guide", "MoonBit 是面向云边计算的编程语言。")
engine.add_document("faq", "RAG 是检索增强生成。")

let results = engine.search("RAG 是什么", top_k=3)
let cb = @lib.ContextBuilder::new(max_tokens=500)
println(cb.build("RAG 是什么", results))
```

CLI 用法（native 目标）：

```bash
# 建索引
moon run cmd/main --target native -- index examples/notes demo-index.json

# 导入带稳定 ID 的 JSONL（每行包含 id 或 _id、text，可选 title）
moon run cmd/main --target native -- index-jsonl documents.jsonl demo-index.json

# 检索
moon run cmd/main --target native -- query demo-index.json "MoonBit 黑客松" -k 3

# 生成 LLM 上下文
moon run cmd/main --target native -- context demo-index.json "黑客松奖励" -k 3

# 输出可供应用读取的提示词、引用清单与预算信息
moon run cmd/main --target native -- context demo-index.json "MoonBit" -k 3 --tokens 2000 --diverse --json

# 用标注查询集评测文档级检索，JSON 含每题排名与汇总指标
moon run cmd/main --target native -- evaluate demo-index.json examples/evaluation-cases.json -k 3 --json

# 检查一次查询的排名和词项匹配证据
moon run cmd/main --target native -- trace demo-index.json "MoonBit RAG" -k 3 --json

# 索引统计
moon run cmd/main --target native -- stats demo-index.json

# 短语检索（可加 --highlight）
moon run cmd/main --target native -- phrase demo-index.json "MoonBit 黑客松" -k 3

# 布尔检索 / 前缀检索
moon run cmd/main --target native -- boolean demo-index.json "MoonBit AND RAG" -k 3
moon run cmd/main --target native -- prefix demo-index.json "moon" -k 3
```

## 项目结构

```
MoonRetrieve.mbt      包说明
jsonl.mbt            带稳定 ID 的文档批量导入校验
tokenizer.mbt        分词器
chunker.mbt          分块器
index.mbt            BM25 倒排索引
vector.mbt           向量索引与 RRF 融合
context.mbt          LLM 上下文组装
engine.mbt           一站式引擎
evaluation.mbt       Precision/Recall/MRR/MAP 等检索评估指标
trace.mbt            可导出的检索诊断轨迹
suggest.mbt          Unicode 查询纠错、推荐与前缀补全
query.mbt            必选/排除/短语/前缀结构化查询
result_ops.mbt       融合、去重、分组与多样化
summary.mbt          关键词、摘要与命中片段
cmd/main/            CLI
examples/notes/      示例文档
examples/evaluation-cases.json  小型检索评测样例
docs/                使用教程、申报书、差异化说明与自查清单
```

## 测试与构建

```bash
moon test        # native / wasm-gc / js 由 CI 覆盖
moon check
moon build --target wasm-gc
moon bench       # 5 项基准（分词 / 建索引 / 小集合与 2,000 文档检索）
```

## 最小示例

```bash
moon run examples/quickstart --target wasm-gc
```

## 许可证

Apache-2.0

## 来源与合规

项目为原创 MoonBit 实现，未复制第三方搜索引擎、RAG 框架、分词器或向量数据库源码。实现参考的公开信息检索概念、示例数据和差异化说明见 [docs/SOURCES.md](docs/SOURCES.md) 与 [docs/differentiation.md](docs/differentiation.md)。

## 参赛与维护

OSC 2026 申请人、仓库账号及历史 Git 作者身份说明见 [docs/PARTICIPATION.md](docs/PARTICIPATION.md)。

### 本期实质新增工作

本期新增的检索评估、查询解析、相关性解释、纠错和结果处理代码分别位于 `evaluation.mbt`、`query.mbt`、`explain.mbt`、`suggest.mbt`、`result_ops.mbt`。文档更新时可直接替换旧分块；RAG 上下文可按原始文档去重，并返回实际使用的引用清单和预算用量，应用无需再从提示词中解析来源。

普通检索与前缀检索现按倒排表计分。在同一 wasm-gc 环境的 2,000 文档基准中，稀有词查询由约 62.8 µs 降至 0.45 µs，常见词由约 1.15 ms 降至 99 µs；负载和复现命令见 [性能记录](docs/performance.md)。本期再增加 SciFact 测试集的完整文档级评测，原来的三题样例仅保留作冒烟测试。JSONL 导入保留外部语料 ID，检索诊断和引用报告可以回溯到原文。CI 在 native、wasm-gc 和 js 上运行检查与测试，另设 SciFact 全量评测任务。mooncakes 的发布状态以包页面为准。

九月黑客松的规则、上一期晋级项目的可借鉴做法及尚未完成的工作见 [九月赛对照记录](docs/SEPTEMBER2026.md)。
