///|
test (it : @bench.T) {
  let t = @MoonRetrieve.Tokenizer::new()
  it.bench(fn() {
    ignore(
      t.tokenize(
        "MoonBit 是面向云边计算的编程语言，RAG 检索增强生成。",
      ),
    )
  })
}

///|
test (it : @bench.T) {
  let e = @MoonRetrieve.Engine::new()
  it.bench(fn() {
    e.add_document(
      "doc", "MoonBit 是面向云边计算的编程语言，RAG 检索增强生成。",
    )
  })
}

///|
test (it : @bench.T) {
  let e = @MoonRetrieve.Engine::new()
  for i = 0; i < 50; i = i + 1 {
    e.add_document(
      "doc" + i.to_string(),
      "MoonBit RAG 检索增强生成 第" + i.to_string() + "篇文档",
    )
  }
  it.bench(fn() { ignore(e.search("RAG 检索", top_k=10)) })
}

///|
test (it : @bench.T) {
  let index = @MoonRetrieve.SearchIndex::new()
  for i = 0; i < 2000; i = i + 1 {
    let text = if i == 1999 {
      "moonbit retrieval raretarget"
    } else {
      "moonbit retrieval document " + i.to_string()
    }
    index.add("doc-" + i.to_string(), text)
  }
  it.bench(fn() { ignore(index.search("raretarget", top_k=10)) })
}

///|
test (it : @bench.T) {
  let index = @MoonRetrieve.SearchIndex::new()
  for i = 0; i < 2000; i = i + 1 {
    index.add("doc-" + i.to_string(), "moonbit retrieval " + i.to_string())
  }
  it.bench(fn() { ignore(index.search("moonbit", top_k=10)) })
}
