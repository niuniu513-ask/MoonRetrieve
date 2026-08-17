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
- 短语检索 `search_phrase`：查询短语按原文顺序连续出现
- 布尔检索 `search_boolean`：AND / OR / `-term` 排除
- 前缀检索 `search_prefix`：按词条前缀匹配
- 向量索引 `VectorIndex`：余弦相似度检索
- 混合融合 `rrf_fuse`：Reciprocal Rank Fusion
- 上下文组装 `ContextBuilder`：token 预算控制、来源标注
- 结果高亮 `highlight`：查询词自动标记 `**term**`
- 文档删除与统计：`SearchIndex::remove` / `stats`、`Engine::remove_document` / `stats`
- 一站式引擎 `Engine`：文档 → 分块 → 索引 → 检索
- CLI：`index` / `query` / `context` / `stats` / `phrase` / `boolean` / `prefix`

## 快速开始

环境要求：MoonBit 0.1.20260807+；native 目标需要 C 编译器（Windows 用 MSVC）。

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

# 检索
moon run cmd/main --target native -- query demo-index.json "MoonBit 黑客松" -k 3

# 生成 LLM 上下文
moon run cmd/main --target native -- context demo-index.json "黑客松奖励" -k 3

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
tokenizer.mbt        分词器
chunker.mbt          分块器
index.mbt            BM25 倒排索引
vector.mbt           向量索引与 RRF 融合
context.mbt          LLM 上下文组装
engine.mbt           一站式引擎
cmd/main/            CLI
examples/notes/      示例文档
docs/                使用教程、申报书、差异化说明与自查清单
```

## 测试与构建

```bash
moon test        # 44 个测试（native / wasm-gc / js 由 CI 覆盖）
moon check
moon build --target wasm-gc
moon bench       # 3 项基准（分词 / 建索引 / 检索）
```

## 许可证

Apache-2.0

## 来源与合规

项目为原创 MoonBit 实现，未复制第三方搜索引擎、RAG 框架、分词器或向量数据库源码。实现参考的公开信息检索概念、示例数据和差异化说明见 [docs/SOURCES.md](docs/SOURCES.md) 与 [docs/differentiation.md](docs/differentiation.md)。
