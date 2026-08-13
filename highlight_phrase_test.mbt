///|
test "highlight english term" {
  assert_true(
    @MoonRetrieve.highlight("hello world", "hello") == "**hello** world",
  )
}

///|
test "highlight chinese longest term first" {
  assert_true(
    @MoonRetrieve.highlight("搜索月兔", "搜索") == "**搜索**月兔",
  )
}

///|
test "highlight multiple non overlapping terms" {
  assert_true(
    @MoonRetrieve.highlight("moonbit rag search", "rag search") ==
    "moonbit **rag** **search**",
  )
}

///|
test "highlight no match returns original text" {
  assert_true(
    @MoonRetrieve.highlight("hello world", "missing") == "hello world",
  )
}

///|
test "phrase search requires consecutive tokens" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add("a", "quick brown fox")
  idx.add("b", "brown fox quick")
  let hits = idx.search_phrase("quick brown", top_k=10)
  assert_true(hits.length() == 1)
  assert_true(hits[0].doc_id == "a")
  let none = idx.search_phrase("quick fox", top_k=10)
  assert_true(none.is_empty())
}

///|
test "engine phrase search and highlight" {
  let e = @MoonRetrieve.Engine::new()
  e.add_document("d1", "MoonBit 是面向云边计算的编程语言")
  e.add_document("d2", "RAG 是检索增强生成")
  let hits = e.search_phrase("检索增强", top_k=5)
  assert_true(hits.length() == 1)
  assert_true(hits[0].doc_id == "d2#0")
  let hl = e.highlight("RAG 是检索增强生成", "检索增强")
  assert_true(hl == "RAG 是**检索增强**生成")
}
