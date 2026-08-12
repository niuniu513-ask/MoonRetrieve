///|
test "engine indexes chunks and searches" {
  let e = @MoonSearch.Engine::new()
  e.add_document("guide", "MoonBit 是用于云边计算的编程语言。")
  e.add_document("recipe", "香蕉面包需要面粉和糖。")
  let results = e.search("MoonBit 编程", top_k=5)
  assert_true(results.length() >= 1)
  assert_true(results[0].doc_id.has_prefix("guide"))
  assert_true(e.count() >= 2)
}

///|
test "engine save and load roundtrip" {
  let e = @MoonSearch.Engine::new()
  e.add_document("guide", "MoonBit 是用于云边计算的编程语言。")
  let json = e.save()
  match @MoonSearch.Engine::try_load(json) {
    Ok(loaded) => {
      assert_true(loaded.count() == e.count())
      let results = loaded.search("编程", top_k=5)
      assert_true(results.length() >= 1)
    }
    Err(msg) => assert_true(false, msg~)
  }
}
