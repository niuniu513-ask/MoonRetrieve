///|
test "boolean AND requires all terms" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add("a", "moonbit rag")
  idx.add("b", "moonbit search")
  idx.add("c", "rag search")
  let hits = idx.search_boolean("moonbit AND rag", top_k=10)
  assert_true(hits.length() == 1)
  assert_true(hits[0].doc_id == "a")
}

///|
test "boolean OR matches any term" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add("a", "moonbit rag")
  idx.add("b", "moonbit search")
  idx.add("c", "rag search")
  let hits = idx.search_boolean("moonbit OR rag", top_k=10)
  assert_true(hits.length() == 3)
}

///|
test "boolean NOT excludes documents" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add("a", "moonbit rag")
  idx.add("b", "moonbit search")
  let hits = idx.search_boolean("moonbit -rag", top_k=10)
  assert_true(hits.length() == 1)
  assert_true(hits[0].doc_id == "b")
}

///|
test "boolean works with chinese terms" {
  let e = @MoonRetrieve.Engine::new()
  e.add_document("d1", "MoonBit 是面向云边计算的编程语言")
  e.add_document("d2", "RAG 是检索增强生成")
  let hits = e.search_boolean("检索增强 AND RAG", top_k=10)
  assert_true(hits.length() == 1)
  assert_true(hits[0].doc_id == "d2#0")
  let none = e.search_boolean("检索增强 -RAG", top_k=10)
  assert_true(none.is_empty())
}

///|
test "prefix search matches terms with prefix" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add("a", "moonbit moonlang")
  idx.add("b", "mooncakes search")
  let hits = idx.search_prefix("moon", top_k=10)
  assert_true(hits.length() == 2)
  let none = idx.search_prefix("xyz", top_k=10)
  assert_true(none.is_empty())
}

///|
test "engine prefix search" {
  let e = @MoonRetrieve.Engine::new()
  e.add_document("d1", "MoonBit 检索")
  e.add_document("d2", "RAG 上下文")
  let hits = e.search_prefix("检索", top_k=10)
  assert_true(hits.length() == 1)
  assert_true(hits[0].doc_id == "d1#0")
}
