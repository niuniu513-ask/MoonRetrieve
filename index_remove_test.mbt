///|
test "remove document updates index and search" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add("a", "apple banana")
  idx.add("b", "banana cherry")
  idx.add("c", "cherry date")
  assert_true(idx.count() == 3)
  assert_true(idx.remove("b"))
  assert_true(idx.count() == 2)
  let r1 = idx.search("banana", top_k=10)
  assert_true(r1.length() == 1)
  assert_true(r1[0].doc_id == "a")
  let r2 = idx.search("cherry", top_k=10)
  assert_true(r2.length() == 1)
  assert_true(r2[0].doc_id == "c")
}

///|
test "remove missing id returns false" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add("a", "apple")
  assert_true(!idx.remove("nope"))
  assert_true(idx.count() == 1)
}

///|
test "remove all docs empties index" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add("a", "apple")
  idx.add("b", "banana")
  assert_true(idx.remove_if(fn(_) { true }) == 2)
  assert_true(idx.count() == 0)
  assert_true(idx.search("apple", top_k=5).is_empty())
  let s = idx.stats()
  assert_true(s.doc_count == 0)
  assert_true(s.term_count == 0)
  assert_true(s.total_tokens == 0)
}

///|
test "stats reflect index contents" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add("a", "hello world")
  idx.add("b", "hello moonbit")
  let s = idx.stats()
  assert_true(s.doc_count == 2)
  assert_true(s.term_count > 0)
  assert_true(s.total_tokens > 0)
  assert_true(s.avg_doc_len > 0.0)
}

///|
test "engine remove document removes its chunks" {
  let e = @MoonRetrieve.Engine::new(
    chunker=@MoonRetrieve.Chunker::new(max_chars=5),
  )
  e.add_document("d1", "第一段\n第二段")
  e.add_document("d2", "苹果 香蕉")
  assert_true(e.count() == 3)
  assert_true(e.remove_document("d1") == 2)
  assert_true(e.count() == 1)
  let s = e.stats()
  assert_true(s.doc_count == 1)
  assert_true(e.search("第一段", top_k=5).is_empty())
}

///|
test "save load roundtrip after removal" {
  let e = @MoonRetrieve.Engine::new()
  e.add_document("x", "月球 探索")
  e.add_document("y", "火星 探索")
  ignore(e.remove_document("x"))
  let json = e.save()
  match @MoonRetrieve.Engine::try_load(json) {
    Ok(loaded) => {
      assert_true(loaded.count() == 1)
      let hits = loaded.search("火星", top_k=5)
      assert_true(hits.length() == 1)
      assert_true(hits[0].doc_id == "y#0")
    }
    Err(msg) => abort(msg)
  }
}
