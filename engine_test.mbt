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
