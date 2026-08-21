///|
fn sample_results() -> Array[@MoonRetrieve.SearchResult] {
  [
    @MoonRetrieve.SearchResult::new("guide#0", 3.0, "MoonBit search guide"),
    @MoonRetrieve.SearchResult::new("guide#1", 2.5, "MoonBit search tutorial"),
    @MoonRetrieve.SearchResult::new("faq#0", 2.0, "RAG retrieval FAQ"),
    @MoonRetrieve.SearchResult::new("api#0", 1.0, "API reference"),
  ]
}

///|
test "source document ID strips chunk suffix" {
  assert_eq(@MoonRetrieve.source_doc_id("guide#12"), "guide")
  assert_eq(@MoonRetrieve.source_doc_id("plain"), "plain")
  assert_eq(@MoonRetrieve.source_doc_id("#0"), "")
}

///|
test "sort results is deterministic" {
  let results = [
    @MoonRetrieve.SearchResult::new("b", 1.0, "b"),
    @MoonRetrieve.SearchResult::new("a", 1.0, "a"),
    @MoonRetrieve.SearchResult::new("top", 2.0, "top"),
  ]
  let sorted = @MoonRetrieve.sort_results(results)
  assert_eq(@MoonRetrieve.result_ids(sorted), ["top", "a", "b"])
  assert_eq(@MoonRetrieve.result_ids(results), ["b", "a", "top"])
}

///|
test "min-max score normalization" {
  let normalized = @MoonRetrieve.normalize_result_scores(sample_results())
  assert_eq(normalized[0].score, 1.0)
  assert_eq(normalized[3].score, 0.0)
  assert_true(normalized[1].score > normalized[2].score)
}

///|
test "equal scores normalize consistently" {
  let equal = [
    @MoonRetrieve.SearchResult::new("a", 2.0, "a"),
    @MoonRetrieve.SearchResult::new("b", 2.0, "b"),
  ]
  let normalized = @MoonRetrieve.normalize_result_scores(equal)
  assert_eq(normalized[0].score, 1.0)
  assert_eq(normalized[1].score, 1.0)
  let zeros = [@MoonRetrieve.SearchResult::new("a", 0.0, "a")]
  assert_eq(@MoonRetrieve.normalize_result_scores(zeros)[0].score, 0.0)
  assert_true(@MoonRetrieve.normalize_result_scores([]).is_empty())
}

///|
test "filter results applies score and limit" {
  let filtered = @MoonRetrieve.filter_results(
    sample_results(),
    min_score=2.0,
    max_results=2,
  )
  assert_eq(@MoonRetrieve.result_ids(filtered), ["guide#0", "guide#1"])
  assert_true(
    @MoonRetrieve.filter_results(sample_results(), max_results=0).is_empty(),
  )
}

///|
test "pagination handles boundaries" {
  let results = sample_results()
  assert_eq(
    @MoonRetrieve.result_ids(
      @MoonRetrieve.paginate_results(results, offset=1, limit=2),
    ),
    ["guide#1", "faq#0"],
  )
  assert_eq(
    @MoonRetrieve.result_ids(
      @MoonRetrieve.paginate_results(results, offset=-3, limit=1),
    ),
    ["guide#0"],
  )
  assert_true(
    @MoonRetrieve.paginate_results(results, offset=10, limit=2).is_empty(),
  )
}

///|
test "deduplicate keeps best chunk per source" {
  let deduplicated = @MoonRetrieve.deduplicate_by_source(sample_results())
  assert_eq(@MoonRetrieve.result_ids(deduplicated), [
    "guide#0", "faq#0", "api#0",
  ])
  assert_eq(
    @MoonRetrieve.deduplicate_by_source(sample_results(), limit=2).length(),
    2,
  )
}

///|
test "group chunks by source" {
  let groups = @MoonRetrieve.group_results_by_source(sample_results())
  assert_eq(groups.length(), 3)
  assert_eq(groups[0].doc_id, "guide")
  assert_eq(groups[0].chunk_count, 2)
  assert_eq(groups[0].best_score, 3.0)
  assert_eq(groups[0].total_score, 5.5)
  assert_eq(groups[0].chunks.length(), 2)
}

///|
test "weighted fusion combines overlapping IDs" {
  let lexical = [
    @MoonRetrieve.SearchResult::new("a", 1.0, "lexical a"),
    @MoonRetrieve.SearchResult::new("b", 0.5, "lexical b"),
  ]
  let vector = [
    @MoonRetrieve.SearchResult::new("b", 1.0, "vector b"),
    @MoonRetrieve.SearchResult::new("c", 0.8, "vector c"),
  ]
  let fused = @MoonRetrieve.weighted_fuse_results(
    lexical,
    vector,
    left_weight=0.6,
    right_weight=0.4,
  )
  assert_eq(fused.length(), 3)
  assert_eq(fused[0].doc_id, "b")
  assert_eq(fused[0].score, 0.7)
  assert_eq(fused[0].text, "vector b")
}

///|
test "weighted fusion obeys limit and handles empty input" {
  assert_eq(
    @MoonRetrieve.weighted_fuse_results(
      sample_results(),
      [],
      left_weight=1.0,
      limit=2,
    ).length(),
    2,
  )
  assert_true(@MoonRetrieve.weighted_fuse_results([], [], limit=0).is_empty())
}

///|
test "diversity removes nearly duplicate text" {
  let tokenizer = @MoonRetrieve.Tokenizer::new(bigram_cjk=false)
  let results = [
    @MoonRetrieve.SearchResult::new("a", 3.0, "moonbit search local rag"),
    @MoonRetrieve.SearchResult::new("b", 2.0, "moonbit search local rag"),
    @MoonRetrieve.SearchResult::new("c", 1.0, "banana bread recipe"),
  ]
  let diverse = @MoonRetrieve.diversify_results(
    results,
    similarity_threshold=0.8,
    tokenizer~,
  )
  assert_eq(@MoonRetrieve.result_ids(diverse), ["a", "c"])
}

///|
test "result score range" {
  assert_eq(
    @MoonRetrieve.result_score_range(sample_results()),
    Some((1.0, 3.0)),
  )
  assert_eq(@MoonRetrieve.result_score_range([]), None)
}
