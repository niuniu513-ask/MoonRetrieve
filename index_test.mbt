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

///|
test "posting-ranked search preserves ranking and unique query terms" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add("first", "moonbit search search")
  idx.add("second", "moonbit search search")
  idx.add("third", "moonbit")
  idx.add("other", "banana")
  let hits = idx.search("moonbit search", top_k=3)
  assert_eq(hits.length(), 3)
  assert_eq(hits[0].doc_id, "first")
  assert_eq(hits[1].doc_id, "second")
  assert_eq(hits[2].doc_id, "third")
  assert_true(hits[0].score > hits[2].score)
  assert_true(hits[0].score > 1.13 && hits[0].score < 1.14)
  assert_true(hits[2].score > 0.44 && hits[2].score < 0.45)
  let repeated = idx.search("moonbit search search", top_k=3)
  for i = 0; i < hits.length(); i = i + 1 {
    assert_eq(repeated[i].doc_id, hits[i].doc_id)
    assert_eq(repeated[i].score, hits[i].score)
  }
  assert_true(idx.search("moonbit", top_k=0).is_empty())
  assert_true(idx.search("missing", top_k=10).is_empty())
}

///|
test "posting-ranked search survives deletion and JSON reload" {
  let idx = @MoonRetrieve.SearchIndex::new()
  idx.add("old", "raretarget")
  idx.add("keep", "raretarget moonbit")
  assert_true(idx.remove("old"))
  let loaded = @MoonRetrieve.SearchIndex::try_load(idx.save()).unwrap()
  let hits = loaded.search("raretarget", top_k=10)
  assert_eq(hits.length(), 1)
  assert_eq(hits[0].doc_id, "keep")
}

///|
test "posting-ranked search matches independent BM25 scoring path" {
  let idx = @MoonRetrieve.SearchIndex::new()
  for i = 0; i < 40; i = i + 1 {
    let text = if i % 3 == 0 {
      "moonbit retrieval retrieval"
    } else if i % 3 == 1 {
      "moonbit language"
    } else {
      "retrieval library"
    }
    idx.add("doc-" + i.to_string(), text)
  }
  let expected = idx.search_boolean("moonbit OR retrieval", top_k=40)
  let actual = idx.search("moonbit retrieval", top_k=40)
  assert_eq(actual.length(), expected.length())
  for i = 0; i < actual.length(); i = i + 1 {
    assert_eq(actual[i].doc_id, expected[i].doc_id)
    assert_eq(actual[i].score, expected[i].score)
  }
}
