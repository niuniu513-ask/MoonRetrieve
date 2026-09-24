# MoonRetrieve 使用教程

## 安装

```bash
moon add niuniu513-ask/MoonRetrieve
```

环境要求：MoonBit 0.1.20260920+。

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

也可以直接通过引擎完成检索和上下文组装：

```moonbit
let prompt = engine.build_context("RAG 是什么", top_k=3, max_tokens=500)
```

多文档知识库可以按来源去重，避免同一文档的多个分块占满上下文：

```moonbit
let prompt = engine.build_diverse_context(
  "RAG 是什么",
  top_k=3,
  max_tokens=500,
)
```

应用需要单独记录引用时，可以读取仓库 `main` 分支新增的结构化结果：

```moonbit
let report = engine.build_diverse_context_report(
  "RAG 是什么", top_k=3, max_tokens=500,
)
println(report.prompt)
for citation in report.citations {
  println("[\{citation.number}] \{citation.doc_id}")
}
println("content tokens: \{report.used_content_tokens}")
println("skipped: \{report.skipped_results}")
```

`max_tokens` 限制检索片段的估算 token 数，不含问题和提示词模板。`estimated_prompt_tokens` 则估算完整提示词；两者都基于内置分词器，并非某个大模型的精确 token 数。放不下的片段会跳过，后续较短的结果仍可进入上下文。

## 5. 删除文档与统计

```moonbit
engine.remove_document("guide.md")   // 按原始文档 ID 删除其全部分块
let s = engine.stats()               // 分块数 / 词条数 / 总 token / 平均长度
println("\{s.doc_count} \{s.term_count}")
```

如果文档内容更新，可以用 `replace_document` 原子替换旧分块，避免同一个文档 ID 在索引中重复：

```moonbit
let removed = engine.replace_document("guide.md", "更新后的文档内容")
println("removed \{removed} old chunks")
```

## 5.1 短语检索

```moonbit
// 查询短语必须按原文顺序连续出现
let hits = engine.search_phrase("检索增强", top_k=3)
```

## 5.2 布尔检索与前缀检索

```moonbit
// AND：同时包含；OR：任一即可；-term：排除
let and_hits = engine.search_boolean("moonbit AND rag", top_k=5)
let or_hits = engine.search_boolean("moonbit OR rag", top_k=5)
let not_hits = engine.search_boolean("moonbit -old", top_k=5)

// 前缀检索：匹配以给定前缀开头的词条
let prefix_hits = engine.search_prefix("moon", top_k=5)
```

## 5.3 结果高亮

```moonbit
let text = "RAG 是检索增强生成"
println(@lib.highlight(text, "检索增强"))
// RAG 是**检索增强**生成
```

## 6. 持久化

```moonbit
let json = engine.save()
match @lib.Engine::try_load(json) {
  Ok(loaded) => println(loaded.count())
  Err(msg) => println("load failed: \{msg}")
}
```

## 7. 标注评测

评测按原始文档计数。同一文档命中的多个分块只保留最高分分块，标注 ID 要与 `add_document` 的 ID 一致，不带 `#0` 等分块后缀。

```moonbit
let cases = [@lib.EvaluationCase::new("RAG 是什么", ["faq.md"])]
let report = engine.evaluate_queries(cases, cutoff=3)
println(report.summary.mean_reciprocal_rank)
```

CLI 接收 JSON 数组，每项含 `query` 和 `relevant_doc_ids`。仓库的 `examples/evaluation-cases.json` 是三题冒烟样例，适合验证评测流程，不足以证明真实语料上的检索质量。长期对比应固定文档集、标注集、截断值和工具链版本。Precision@K 的分母固定为 K，结果不足 K 条时空缺位置计为未命中。

```bash
moon run cmd/main --target native -- evaluate index.json examples/evaluation-cases.json -k 3 --json
```

JSON 结果中的 `queries` 给出每题的文档排名和指标，`summary` 给出平均 Precision、Recall、F1、MRR、MAP 及命中率。

需要检查单次查询时，可用 `engine.trace("RAG", top_k=3)` 或 CLI `trace`。报告包含分词后的查询、分块排名、原始文档 ID、BM25 排序分数、命中与缺失词、原文及词项重叠度。`token_overlap` 是 Jaccard 重叠度，仅辅助诊断，不能当成 BM25 分数的逐词归因。

## 8. CLI

```bash
# 建索引（支持 .md / .txt 文件或目录）
moon run cmd/main --target native -- index examples/notes index.json

# 检索
moon run cmd/main --target native -- query index.json "MoonBit" -k 3

# 生成 LLM 上下文
moon run cmd/main --target native -- context index.json "黑客松" -k 3

# JSON 结果含 prompt、citations 和预算统计
moon run cmd/main --target native -- context index.json "MoonBit" -k 3 --tokens 2000 --diverse --json

# 文档级标注评测
moon run cmd/main --target native -- evaluate index.json examples/evaluation-cases.json -k 3 --json

# 查询诊断轨迹
moon run cmd/main --target native -- trace index.json "MoonBit RAG" -k 3 --json

# 索引统计
moon run cmd/main --target native -- stats index.json

# 短语检索（支持 --highlight）
moon run cmd/main --target native -- phrase index.json "检索增强" -k 3 --highlight

# 布尔检索 / 前缀检索
moon run cmd/main --target native -- boolean index.json "moonbit AND rag" -k 3
moon run cmd/main --target native -- prefix index.json "moon" -k 3

# 输出限定长度的命中片段 / 相关性解释
moon run cmd/main --target native -- snippet index.json "MoonBit" -k 3 --chars 160
moon run cmd/main --target native -- explain index.json "MoonBit" -k 3
```

## 9. 多后端构建

核心库零 FFI，同一套代码支持多目标：

```bash
moon check --target wasm-gc
moon build --target wasm-gc .
moon test --target native
```

CI 覆盖 native / wasm-gc / js 三个目标。

## 10. 基准测试

```bash
moon bench --target native
```
