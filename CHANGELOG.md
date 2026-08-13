# Changelog

## 0.2.0（2026-08-13）

- 新增 `SearchIndex::remove` / `remove_if`，支持按文档 ID 或条件删除并重建倒排索引；
- 新增 `IndexStats` 与 `SearchIndex::stats` / `Engine::stats`，提供分块数、词条数、总 token 与平均长度；
- 新增 `Engine::remove_document`，按原始文档 ID 删除其全部分块；
- CLI 新增 `stats` 命令；
- 新增使用教程（docs/usage.md）与示例说明（examples/README.md）；
- 新增删除/统计/序列化往返测试，测试总数 32 项；
- CI 覆盖 native / wasm-gc / js 三个目标。

## 0.1.0（2026-08-12）

MoonRetrieve 首个 MVP 版本，完成可运行的本地全文检索与 RAG 检索库：

- 分词器 `Tokenizer`：中/英/日文、N-gram、停用词、可选词干化
- 分块器 `Chunker`：段落切分、块间重叠、超长段落硬切
- BM25 倒排索引 `SearchIndex`：增量建索引、Top-K 检索、JSON 持久化
- 向量索引 `VectorIndex` 与 RRF 混合融合
- LLM 上下文组装 `ContextBuilder`：token 预算、来源编号
- 一站式引擎 `Engine` 与 CLI（index / query / context）
- 单元测试（19+ 项）、GitHub Actions（native / wasm-gc）、mooncakes 发布
