# Changelog

## 0.1.0（2026-08-12）

MoonRetrieve 首个 MVP 版本，完成可运行的本地全文检索与 RAG 检索库：

- 分词器 `Tokenizer`：中/英/日文、N-gram、停用词、可选词干化
- 分块器 `Chunker`：段落切分、块间重叠、超长段落硬切
- BM25 倒排索引 `SearchIndex`：增量建索引、Top-K 检索、JSON 持久化
- 向量索引 `VectorIndex` 与 RRF 混合融合
- LLM 上下文组装 `ContextBuilder`：token 预算、来源编号
- 一站式引擎 `Engine` 与 CLI（index / query / context）
- 单元测试（19+ 项）、GitHub Actions（native / wasm-gc）、mooncakes 发布
