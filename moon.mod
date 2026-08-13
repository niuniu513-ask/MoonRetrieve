// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "niuniu513-ask/MoonRetrieve"

version = "0.3.0"

readme = "README.md"

repository = "https://github.com/niuniu513-ask/MoonRetrieve"

license = "Apache-2.0"

keywords = [
  "moonbit",
  "search",
  "bm25",
  "rag",
  "tokenizer",
  "wasm",
  "local-first",
  "hybrid",
  "rrf",
]

preferred_target = "wasm"

description = "纯 MoonBit 零 FFI 的本地全文检索与 RAG 检索库：中英日分词、BM25 倒排索引、向量索引、RRF 混合检索与 LLM 上下文组装，可编译为 wasm / wasm-gc / js / native 多后端。"

import {
  "moonbitlang/async@0.20.5",
}
