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

name = "niuniu513-ask/MoonSearch"

version = "0.1.0"

readme = "README.md"

repository = "https://github.com/niuniu513-ask/MoonSearch"

license = "Apache-2.0"

keywords = [ "moonbit", "search", "bm25", "rag", "tokenizer", "wasm" ]

preferred_target = "wasm"

description = "纯 MoonBit 实现的本地全文检索与 RAG 检索库：中英文分词、BM25 倒排索引、分块、混合检索（RRF）与 LLM 上下文组装，可编译为 WASM 在浏览器/边缘运行。"

import {
  "moonbitlang/async@0.20.5",
}
