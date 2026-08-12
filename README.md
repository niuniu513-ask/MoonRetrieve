# MoonSearch

纯 MoonBit 实现的本地全文检索与 RAG 检索库。文档在本地完成分词、分块、索引和检索，不需要把数据上传到云端，可编译为 WASM 在浏览器或边缘设备上运行。

## 创新点

- **本地优先的 RAG**：索引和检索全链路在本地/边缘执行，隐私友好，适合企业知识库和个人笔记。
- **中英文混合分词**：中文按单字 + bigram 切分（单字查询也能命中），英文支持小写化、停用词与可选词干化。
- **BM25 + 向量混合检索**：内置倒排索引与余弦向量索引，并提供 RRF 融合排序。
- **为 LLM 而生的上下文组装**：按 token 预算把命中片段拼成带来源编号的提示词。
- **纯 MoonBit / WASM**：核心库零 FFI，可编译到 wasm、wasm-gc、js、native 多后端。

## 功能

- 分词器 `Tokenizer`：英文/中文/日文、N-gram、停用词、词干化
- 分块器 `Chunker`：按段落切分、块间重叠、超长段落硬切
- BM25 索引 `SearchIndex`：增量建索引、Top-K 检索、JSON 持久化
- 向量索引 `VectorIndex`：余弦相似度检索
- 混合融合 `rrf_fuse`：Reciprocal Rank Fusion
- 上下文组装 `ContextBuilder`：token 预算控制、来源标注
- 一站式引擎 `Engine`：文档 → 分块 → 索引 → 检索
- CLI：`index` / `query` / `context`

## 快速开始

环境要求：MoonBit 0.1.20260807+；native 目标需要 C 编译器（Windows 用 MSVC）。

```bash
# 添加依赖
moon add niuniu513-ask/MoonSearch
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
```

## 项目结构

```
MoonSearch.mbt        包说明
tokenizer.mbt        分词器
chunker.mbt          分块器
index.mbt            BM25 倒排索引
vector.mbt           向量索引与 RRF 融合
context.mbt          LLM 上下文组装
engine.mbt           一站式引擎
cmd/main/            CLI
examples/notes/      示例文档
docs/申报书.md       比赛项目申报书
```

## 测试与构建

```bash
moon test        # 19 个测试
moon check
moon build --target wasm-gc
```

## 许可证

Apache-2.0
