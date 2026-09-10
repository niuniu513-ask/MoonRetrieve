///|
test "engine indexes chunks and searches" {
  let e = @MoonRetrieve.Engine::new()
  e.add_document("guide", "MoonBit 是用于云边计算的编程语言。")
  e.add_document("recipe", "香蕉面包需要面粉和糖。")
  let results = e.search("MoonBit 编程", top_k=5)
  assert_true(results.length() >= 1)
  assert_true(results[0].doc_id.has_prefix("guide"))
  assert_true(e.count() >= 2)
}

///|
test "engine save and load roundtrip" {
  let e = @MoonRetrieve.Engine::new()
  e.add_document("guide", "MoonBit 是用于云边计算的编程语言。")
  let json = e.save()
  match @MoonRetrieve.Engine::try_load(json) {
    Ok(loaded) => {
      assert_true(loaded.count() == e.count())
      let results = loaded.search("编程", top_k=5)
      assert_true(results.length() >= 1)
    }
    Err(msg) => assert_true(false, msg~)
  }
}

///|
test "engine returns snippets and relevance explanations" {
  let e = @MoonRetrieve.Engine::new()
  e.add_document(
    "guide", "MoonBit 是面向云边计算的编程语言。它支持 WASM。",
  )
  e.add_document("faq", "RAG 是检索增强生成。")
  let snippets = e.search_snippets("MoonBit 编程", top_k=3, max_chars=12)
  assert_true(snippets.length() == 1)
  assert_true(snippets[0].text.length() <= 18)
  let explanations = e.search_explained("MoonBit 编程", top_k=3)
  assert_true(explanations.length() == 1)
}

///|
test "engine replaces all chunks for an existing document" {
  let e = @MoonRetrieve.Engine::new()
  e.add_document("guide", "旧版本内容。旧版本说明。")
  let old_count = e.count()
  let removed = e.replace_document("guide", "新版本内容。")
  assert_true(removed == old_count)
  assert_true(e.count() == 1)
  assert_true(e.search("旧", top_k=3).is_empty())
  assert_true(e.search("新", top_k=3).length() == 1)
}

///|
test "engine builds bounded RAG context" {
  let e = @MoonRetrieve.Engine::new()
  e.add_document("guide", "MoonBit 是面向云边计算的编程语言。")
  let context = e.build_context("MoonBit", top_k=1, max_tokens=100)
  assert_true(context.contains("MoonBit"))
  assert_true(context.contains("[1]"))
}

///|
test "engine builds context from distinct source documents" {
  let chunker = @MoonRetrieve.Chunker::new(max_chars=8, overlap=0)
  let e = @MoonRetrieve.Engine::new(chunker~)
  e.add_document(
    "guide", "MoonBit 文档第一段。MoonBit 文档第二段。",
  )
  e.add_document("faq", "MoonBit 常见问题。")
  let context = e.build_diverse_context("MoonBit", top_k=2, max_tokens=100)
  assert_true(context.contains("guide#"))
  assert_true(context.contains("faq#"))
}
