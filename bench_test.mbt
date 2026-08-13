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
