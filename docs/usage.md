# MoonRetrieve 使用教程

## 安装

```bash
moon add niuniu513-ask/MoonRetrieve
```

环境要求：MoonBit 0.1.20260807+。

## 1. 分词与分块

```moonbit
let t = @lib.Tokenizer::new()
println(t.tokenize("搜索 月兔"))
// 中文按单字 + bigram 切分：["搜", "索", "搜索", "月", "索月", "兔", "月兔"]

let c = @lib.Chunker::new(max_chars=50, overlap=10)
let chunks = c.chunk("note.md", "第一段\n第二段")
println(chunks.length())
```

## 2. 建索引与检索

```moonbit
let engine = @lib.Engine::new()
engine.add_document("guide.md", "MoonBit 是面向云边计算的编程语言。")
engine.add_document("faq.md", "RAG 是检索增强生成。")

let results = engine.search("RAG 是什么", top_k=3)
for r in results {
  println("\{r.doc_id} \{r.score}")
}
```

## 3. 向量索引与混合检索

```moonbit
let vi = @lib.VectorIndex::new()
vi.add("guide", [1.0, 0.0, 0.0])
vi.add("faq", [0.0, 1.0, 0.0])
let vec_hits = vi.search([0.9, 0.1, 0.0], top_k=3)

// 与 BM25 结果做 RRF 融合
let fused = @lib.rrf_fuse(bm25_hits, vec_hits, top_k=5)
```

## 4. 生成 LLM 上下文

```moonbit
let results = engine.search("RAG 是什么", top_k=3)
let cb = @lib.ContextBuilder::new(max_tokens=500)
let prompt = cb.build("RAG 是什么", results)
println(prompt)
```

`ContextBuilder` 会按 token 预算拼接带来源编号的资料，并附上“仅根据资料回答”的提示。

## 5. 删除文档与统计

```moonbit
engine.remove_document("guide.md")   // 按原始文档 ID 删除其全部分块
let s = engine.stats()               // 分块数 / 词条数 / 总 token / 平均长度
println("\{s.doc_count} \{s.term_count}")
```

## 6. 持久化

```moonbit
let json = engine.save()
match @lib.Engine::try_load(json) {
  Ok(loaded) => println(loaded.count())
  Err(msg) => println("load failed: \{msg}")
}
```

## 7. CLI

```bash
# 建索引（支持 .md / .txt 文件或目录）
moon run cmd/main --target native -- index examples/notes index.json

# 检索
moon run cmd/main --target native -- query index.json "MoonBit" -k 3

# 生成 LLM 上下文
moon run cmd/main --target native -- context index.json "黑客松" -k 3

# 索引统计
moon run cmd/main --target native -- stats index.json
```

## 8. 多后端构建

核心库零 FFI，同一套代码支持多目标：

```bash
moon check --target wasm-gc
moon build --target wasm-gc .
moon test --target native
```

CI 覆盖 native / wasm-gc / js 三个目标。
