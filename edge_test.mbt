///|
test "empty input yields no tokens" {
  let t = @MoonRetrieve.Tokenizer::new()
  assert_true(t.tokenize("").is_empty())
}

///|
test "japanese kana unigrams and bigrams" {
  let t = @MoonRetrieve.Tokenizer::new()
  assert_true(
    t.tokenize("こんにちは") ==
    ["こ", "ん", "こん", "に", "んに", "ち", "にち", "は", "ちは"],
  )
}

///|
test "mixed ascii and chinese" {
  let t = @MoonRetrieve.Tokenizer::new()
  assert_true(
    t.tokenize("RAG 是什么") ==
    ["rag", "是", "什", "是什", "么", "什么"],
  )
}

///|
test "chinese stopwords filter unigrams only" {
  let t = @MoonRetrieve.Tokenizer::new(stopwords=["的"])
  assert_true(
    t.tokenize("我的世界") ==
    ["我", "我的", "世", "的世", "界", "世界"],
  )
}

///|
test "empty document produces no chunks" {
  let c = @MoonRetrieve.Chunker::new()
  assert_true(c.chunk("empty", "").is_empty())
}

///|
test "overlap larger than max chars is clamped" {
  let c = @MoonRetrieve.Chunker::new(max_chars=10, overlap=100)
  assert_true(
    c
    .chunk(
      "doc4", "一二三四五六七八九十一二三四五六七八九十",
    )
    .length() ==
    2,
  )
}

///|
test "context numbers sources in rank order" {
  let cb = @MoonRetrieve.ContextBuilder::new(max_tokens=100)
  let results = [
    @MoonRetrieve.SearchResult::new("first.md", 1.0, "第一条资料"),
    @MoonRetrieve.SearchResult::new("second.md", 0.5, "第二条资料"),
  ]
  let ctx = cb.build("排序", results)
  assert_true(ctx.split("[1]（来源：first.md）").count() == 2)
  assert_true(ctx.split("[2]（来源：second.md）").count() == 2)
}
