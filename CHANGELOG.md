# Changelog

## 0.5.0（2026-08-21）

- 新增 Precision、Recall、F1、MRR、MAP、R-Precision 与覆盖率等检索评估指标；
- 新增结构化查询解析、相关性解释、摘要与片段生成；
- 新增拼写纠错、前缀补全、结果归一化、过滤、分页、去重、融合与多样化工具；
- 补充身份关系说明与回归测试，测试总数达到 100 项。

## 0.4.0（2026-08-13）

- 新增布尔检索 `SearchIndex::search_boolean` / `Engine::search_boolean`，支持 AND / OR / `-term` 排除（中文词自动展开匹配）；
- 新增前缀检索 `SearchIndex::search_prefix` / `Engine::search_prefix`；
- CLI 新增 `boolean` / `prefix` 命令；
- 新增 3 项基准测试（分词 / 建索引 / 检索），`moon bench` 可运行；
- CI 新增 CLI 运行时冒烟测试与基准测试步骤；
- 测试总数 44 项。

## 0.3.0（2026-08-13）

- 新增短语检索 `SearchIndex::search_phrase` / `Engine::search_phrase`，查询短语按原文顺序连续匹配；
- 新增结果高亮 `highlight`（长词优先、相邻区间合并，输出 `**term**`）；
- CLI 新增 `phrase` 命令，`query` / `phrase` 支持 `--highlight`；
- 新增高亮与短语检索测试，测试总数 38 项。

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
