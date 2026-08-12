///|
test "bm25 ranks matching doc first" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add(
    "doc-a", "MoonBit is a programming language for cloud and edge computing",
  )
  idx.add("doc-b", "Banana bread recipe with flour and sugar")
  let results = idx.search("MoonBit programming", top_k=5)
  assert_true(results.length() == 1)
  assert_true(results[0].doc_id == "doc-a")
  assert_true(results[0].score > 0.0)
}

///|
test "save and load roundtrip" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add("doc-a", "MoonBit programming language")
  idx.add("doc-b", "Banana bread recipe")
  let json = idx.save()
  let loaded = @MoonRetrieve.SearchIndex::try_load(json)
  match loaded {
    Ok(restored) => {
      assert_true(restored.count() == 2)
      let results = restored.search("MoonBit", top_k=5)
      assert_true(results.length() == 1)
      assert_true(results[0].doc_id == "doc-a")
    }
    Err(msg) => assert_true(false, msg~)
  }
}

///|
test "invalid json load returns error" {
  match @MoonRetrieve.SearchIndex::try_load("not json") {
    Err(_) => ()
    Ok(_) => assert_true(false)
  }
}
