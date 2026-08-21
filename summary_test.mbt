///|
test "split English and Chinese sentences" {
  assert_eq(
    @MoonRetrieve.split_sentences(
      "First sentence. Second one! 最后一段。Tail",
    ),
    ["First sentence.", "Second one!", "最后一段。", "Tail"],
  )
  assert_true(@MoonRetrieve.split_sentences("   ").is_empty())
}

///|
test "extract keywords ranks frequency then term" {
  let tokenizer = @MoonRetrieve.Tokenizer::new(
    min_token_len=2,
    bigram_cjk=false,
    stopwords=["and"],
  )
  let keywords = @MoonRetrieve.extract_keywords(
    "moonbit search and moonbit retrieval search moonbit",
    limit=3,
    tokenizer~,
  )
  assert_eq(keywords.length(), 3)
  assert_eq(keywords[0].term, "moonbit")
  assert_eq(keywords[0].count, 3)
  assert_eq(keywords[1].term, "search")
  assert_eq(keywords[1].count, 2)
  assert_true(keywords[0].frequency > keywords[1].frequency)
}

///|
test "keyword extraction handles boundaries" {
  assert_true(@MoonRetrieve.extract_keywords("").is_empty())
  assert_true(@MoonRetrieve.extract_keywords("moonbit", limit=0).is_empty())
}

///|
test "query-focused summary selects matching sentences" {
  let text = "Banana bread is food. MoonBit supports wasm. Retrieval finds documents. MoonBit retrieval runs locally."
  let summary = @MoonRetrieve.summarize_text(
    text,
    query="moonbit retrieval",
    max_sentences=2,
  )
  assert_eq(summary.original_sentences, 4)
  assert_eq(summary.selected_sentences, 2)
  assert_true(summary.text.contains("MoonBit"))
  assert_true(summary.text.contains("retrieval"))
  assert_false(summary.text.contains("Banana"))
  assert_true(summary.estimated_tokens > 0)
}

///|
test "summary restores document order" {
  let text = "Retrieval appears first. Noise sentence. MoonBit retrieval is strongest."
  let summary = @MoonRetrieve.summarize_text(
    text,
    query="moonbit retrieval",
    max_sentences=2,
  )
  assert_eq(
    summary.text,
    "Retrieval appears first. MoonBit retrieval is strongest.",
  )
}

///|
test "summary handles empty and zero limit" {
  assert_eq(@MoonRetrieve.summarize_text("").text, "")
  assert_eq(@MoonRetrieve.summarize_text("One. Two.", max_sentences=0).text, "")
}

///|
test "snippet centers around query match" {
  let text = "0123456789abcdefghij MOONBIT retrieval tail text"
  let snippet = @MoonRetrieve.result_snippet(text, "MOONBIT", max_chars=20)
  assert_true(snippet.contains("MOONBIT"))
  assert_true(snippet.has_prefix("..."))
  assert_true(snippet.has_suffix("..."))
}

///|
test "snippet handles short text and limits" {
  assert_eq(@MoonRetrieve.result_snippet("short text", "text"), "short text")
  assert_eq(@MoonRetrieve.result_snippet("long text", "text", max_chars=0), "")
  assert_eq(@MoonRetrieve.result_snippet("", "text"), "")
}

///|
test "snippets preserve result metadata" {
  let results = [
    @MoonRetrieve.SearchResult::new(
      "guide#0", 2.0, "A long introduction followed by MoonBit retrieval details.",
    ),
  ]
  let snippets = @MoonRetrieve.snippets_for_results(
    results,
    "MoonBit",
    max_chars=24,
  )
  assert_eq(snippets.length(), 1)
  assert_eq(snippets[0].doc_id, "guide#0")
  assert_eq(snippets[0].score, 2.0)
  assert_true(snippets[0].text.contains("MoonBit"))
}
