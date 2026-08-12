# MoonRetrieve 与现有 MoonBit 检索项目对比

本文档用于说明 MoonRetrieve 与 mooncakes / GitHub 上已有检索类项目的差异。

| 项目 | 定位 | 目标与 FFI | 检索能力 | 上下文组装 |
|------|------|-----------|----------|-----------|
| **MoonRetrieve**（本项目） | 轻量本地检索 + RAG 上下文组装库 | 纯 MoonBit，零 FFI，wasm-gc / js / native | BM25 + 余弦向量 + RRF，JSON 持久化，内置中英日分词 | 内置 `ContextBuilder`，token 预算 + 来源编号 |
| [Lucius646/MoonSearch](https://github.com/Lucius646/MoonSearch) | 嵌入式全文检索内核 | MoonBit 实现，多 Segment 不可变存储 | Schema、BM25、Boolean/Phrase、中文分析、高亮 | 无（面向搜索引擎场景） |
| [houjie/rag-mbt](https://github.com/Mr-Houjie/rag.mbt) | 完整 RAG 管线 | 核心库纯 MoonBit；native 侧 C FFI + Python（bge 嵌入、OpenAI） | BM25 / TF-IDF / IVF / Hybrid RRF、FileStore | 通过 Generator 直接调用 LLM |

MoonRetrieve 不复制搜索引擎内核（Schema / 多 Segment / Phrase 查询等），也不做依赖 Python 与 FFI 的完整 RAG 管线；它提供的是：

- 一套零 FFI、可在浏览器 / 边缘设备运行的混合检索 API；
- 内置中英日分词，中文单字查询可命中；
- 为 LLM 提示词设计的 token 预算上下文组装，而不是 LLM 客户端；
- 开箱即用的 CLI 与 JSON 持久化，方便本地知识库快速接入。
