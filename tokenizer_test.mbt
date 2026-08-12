///|
test "english tokens lowercased and filtered" {
  let t = @MoonSearch.Tokenizer::new()
  assert_true(
    t.tokenize("Hello, MoonBit World!") == ["hello", "moonbit", "world"],
  )
}

///|
test "min token length filter" {
  let t = @MoonSearch.Tokenizer::new(min_token_len=4)
  assert_true(t.tokenize("a to moon") == ["moon"])
}

///|
test "stopwords filter" {
  let t = @MoonSearch.Tokenizer::new(stopwords=["moonbit", "is"])
  assert_true(t.tokenize("MoonBit is great") == ["great"])
}

///|
test "english stemming" {
  let t = @MoonSearch.Tokenizer::new(stem_english=true)
  assert_true(
    t.tokenize("running jumped quickly tests") ==
    ["runn", "jump", "quick", "test"],
  )
}

///|
test "chinese unigrams and bigrams" {
  let t = @MoonSearch.Tokenizer::new()
  assert_true(
    t.tokenize("搜索月兔") ==
    ["搜", "索", "搜索", "月", "索月", "兔", "月兔"],
  )
}

///|
test "token estimation" {
  let t = @MoonSearch.Tokenizer::new()
  assert_true(t.estimate_tokens("hello world 月兔") == 5)
}
