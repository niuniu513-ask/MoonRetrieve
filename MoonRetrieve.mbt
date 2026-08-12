// MoonRetrieve: 纯 MoonBit 零 FFI 的本地全文检索与 RAG 检索库。
//
// 核心 API 分布在以下文件中：
// - tokenizer.mbt  分词（中英文、N-gram、停用词、可选词干化）
// - chunker.mbt    文档分块（带重叠）
// - index.mbt      BM25 倒排索引（增删查、JSON 序列化）
// - vector.mbt     稠密向量索引 + 余弦相似度 + RRF 混合融合
// - context.mbt    LLM 上下文组装器
// - engine.mbt     一站式引擎：文档 -> 分块 -> 索引 -> 检索
