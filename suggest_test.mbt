///|
test "Levenshtein distance handles edits" {
  assert_eq(@MoonRetrieve.edit_distance("kitten", "sitting"), 3)
  assert_eq(@MoonRetrieve.edit_distance("moonbit", "moonbit"), 0)
  assert_eq(@MoonRetrieve.edit_distance("", "abc"), 3)
  assert_eq(@MoonRetrieve.edit_distance("abc", ""), 3)
  assert_eq(@MoonRetrieve.edit_distance("检索", "搜索"), 1)
}

///|
test "transposition distance catches typing swaps" {
  assert_eq(@MoonRetrieve.transposition_distance("serach", "search"), 1)
  assert_eq(@MoonRetrieve.transposition_distance("ab", "ba"), 1)
  assert_eq(@MoonRetrieve.transposition_distance("abc", "abc"), 0)
  assert_eq(@MoonRetrieve.transposition_distance("", "abc"), 3)
}

///|
test "edit similarity is normalized" {
  assert_eq(@MoonRetrieve.edit_similarity("", ""), 1.0)
  assert_eq(@MoonRetrieve.edit_similarity("abc", "abc"), 1.0)
  let similarity = @MoonRetrieve.edit_similarity("abc", "abx")
  assert_true(similarity > 0.66 && similarity < 0.67)
  assert_eq(@MoonRetrieve.edit_similarity("abc", "xyz"), 0.0)
}

///|
test "term suggestions rank nearest candidates" {
  let suggestions = @MoonRetrieve.suggest_terms(
    "serach",
    ["research", "search", "searching", "search", "batch"],
    max_distance=2,
    limit=3,
  )
  assert_true(suggestions.length() >= 1)
  assert_eq(suggestions[0].value, "search")
  assert_eq(suggestions[0].distance, 1)
  assert_true(suggestions[0].similarity > 0.8)
}

///|
test "term suggestions obey distance and limit" {
  assert_true(
    @MoonRetrieve.suggest_terms("moonbit", ["banana", "bread"], max_distance=1).is_empty(),
  )
  assert_true(
    @MoonRetrieve.suggest_terms("", ["moonbit"], max_distance=2).is_empty(),
  )
  assert_true(
    @MoonRetrieve.suggest_terms("moon", ["moons", "moonbit"], max_distance=-1).is_empty(),
  )
  assert_eq(
    @MoonRetrieve.suggest_terms(
      "moon",
      ["moons", "moonbit"],
      max_distance=4,
      limit=1,
    ).length(),
    1,
  )
}

///|
test "correct query replaces only close words" {
  let vocabulary = ["search", "engine", "moonbit", "retrieval"]
  assert_eq(
    @MoonRetrieve.correct_query(
      "serach engin moonbit",
      vocabulary,
      max_distance=2,
    ),
    "search engine moonbit",
  )
  assert_eq(
    @MoonRetrieve.correct_query("unknown moonbit", vocabulary, max_distance=1),
    "unknown moonbit",
  )
  assert_eq(@MoonRetrieve.correct_query("   ", vocabulary), "")
}

///|
test "prefix completion prefers shortest value" {
  let completions = @MoonRetrieve.complete_prefix(
    "moon",
    ["moonretrieve", "moon", "moonbit", "other", "moonbase"],
    limit=3,
  )
  assert_eq(completions, ["moon", "moonbit", "moonbase"])
  assert_true(@MoonRetrieve.complete_prefix("", ["moon"]).is_empty())
  assert_true(@MoonRetrieve.complete_prefix("x", ["moon"]).is_empty())
}

///|
test "token Jaccard measures overlap" {
  let tokenizer = @MoonRetrieve.Tokenizer::new(bigram_cjk=false)
  assert_eq(
    @MoonRetrieve.token_jaccard(
      "moonbit search",
      "moonbit retrieval",
      tokenizer~,
    ),
    1.0 / 3.0,
  )
  assert_eq(@MoonRetrieve.token_jaccard("", "", tokenizer~), 1.0)
  assert_eq(@MoonRetrieve.token_jaccard("alpha", "beta", tokenizer~), 0.0)
}

///|
test "shared prefix length is Unicode aware" {
  assert_eq(@MoonRetrieve.shared_prefix_length("moonbit", "moonbase"), 5)
  assert_eq(
    @MoonRetrieve.shared_prefix_length("检索增强", "检索系统"),
    2,
  )
  assert_eq(@MoonRetrieve.shared_prefix_length("abc", "xyz"), 0)
  assert_eq(@MoonRetrieve.shared_prefix_length("", "abc"), 0)
}
