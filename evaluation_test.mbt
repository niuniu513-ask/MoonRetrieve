///|
test "precision recall and F1 at cutoff" {
  let ranked = ["a", "x", "b", "c"]
  let relevant = ["a", "b", "d"]
  assert_eq(@MoonRetrieve.precision_at(ranked, relevant, 3), 2.0 / 3.0)
  assert_eq(@MoonRetrieve.recall_at(ranked, relevant, 3), 2.0 / 3.0)
  assert_eq(
    @MoonRetrieve.f1_score(
      @MoonRetrieve.precision_at(ranked, relevant, 3),
      @MoonRetrieve.recall_at(ranked, relevant, 3),
    ),
    2.0 / 3.0,
  )
}

///|
test "metrics handle empty inputs and cutoffs" {
  assert_eq(@MoonRetrieve.precision_at([], ["a"], 10), 0.0)
  assert_eq(@MoonRetrieve.recall_at(["a"], [], 10), 0.0)
  assert_eq(@MoonRetrieve.precision_at(["a"], ["a"], 0), 0.0)
  assert_eq(@MoonRetrieve.reciprocal_rank_at(["a"], ["a"], -1), 0.0)
  assert_eq(@MoonRetrieve.f1_score(0.0, 1.0), 0.0)
}

///|
test "reciprocal rank finds first relevant result" {
  let ranked = ["noise-1", "noise-2", "answer", "later"]
  assert_eq(
    @MoonRetrieve.reciprocal_rank_at(ranked, ["answer", "later"], 10),
    1.0 / 3.0,
  )
  assert_eq(@MoonRetrieve.reciprocal_rank_at(ranked, ["missing"], 10), 0.0)
  assert_eq(@MoonRetrieve.reciprocal_rank_at(ranked, ["answer"], 2), 0.0)
}

///|
test "average precision rewards early relevant results" {
  let ranked = ["a", "x", "b", "c"]
  let relevant = ["a", "b"]
  assert_eq(
    @MoonRetrieve.average_precision_at(ranked, relevant, 4),
    (1.0 + 2.0 / 3.0) / 2.0,
  )
  assert_eq(@MoonRetrieve.average_precision_at(ranked, [], 4), 0.0)
}

///|
test "duplicate ranked IDs are counted once" {
  let ranked = ["a", "a", "b"]
  let relevant = ["a", "b", "b"]
  assert_eq(@MoonRetrieve.recall_at(ranked, relevant, 3), 1.0)
  assert_eq(
    @MoonRetrieve.average_precision_at(ranked, relevant, 3),
    (1.0 + 2.0 / 3.0) / 2.0,
  )
}

///|
test "evaluate ranking fills report" {
  let report = @MoonRetrieve.evaluate_ranking(
    ["a", "x", "b"],
    ["a", "b", "c"],
    cutoff=3,
  )
  assert_eq(report.cutoff, 3)
  assert_eq(report.retrieved, 3)
  assert_eq(report.relevant, 3)
  assert_eq(report.relevant_retrieved, 2)
  assert_eq(report.precision, 2.0 / 3.0)
  assert_eq(report.recall, 2.0 / 3.0)
  assert_eq(report.hit_rate, 1.0)
  assert_eq(report.reciprocal_rank, 1.0)
}

///|
test "evaluate SearchResult IDs" {
  let results = [
    @MoonRetrieve.SearchResult::new("doc-a", 2.0, "a"),
    @MoonRetrieve.SearchResult::new("doc-b", 1.0, "b"),
  ]
  assert_eq(@MoonRetrieve.result_ids(results), ["doc-a", "doc-b"])
  let report = @MoonRetrieve.evaluate_results(results, ["doc-b"], cutoff=2)
  assert_eq(report.precision, 0.5)
  assert_eq(report.recall, 1.0)
  assert_eq(report.reciprocal_rank, 0.5)
}

///|
test "R precision uses number of relevant documents" {
  assert_eq(@MoonRetrieve.r_precision(["a", "x", "b", "c"], ["a", "b"]), 0.5)
  assert_eq(@MoonRetrieve.r_precision(["a"], []), 0.0)
}

///|
test "summary averages query evaluations" {
  let first = @MoonRetrieve.evaluate_ranking(["a"], ["a"], cutoff=1)
  let second = @MoonRetrieve.evaluate_ranking(["x"], ["b"], cutoff=1)
  let summary = @MoonRetrieve.summarize_evaluations([first, second])
  assert_eq(summary.query_count, 2)
  assert_eq(summary.mean_precision, 0.5)
  assert_eq(summary.mean_recall, 0.5)
  assert_eq(summary.mean_f1, 0.5)
  assert_eq(summary.mean_reciprocal_rank, 0.5)
  assert_eq(summary.mean_average_precision, 0.5)
  assert_eq(summary.hit_rate, 0.5)
}

///|
test "empty evaluation summary is all zero" {
  let summary = @MoonRetrieve.summarize_evaluations([])
  assert_eq(summary.query_count, 0)
  assert_eq(summary.mean_precision, 0.0)
  assert_eq(summary.mean_reciprocal_rank, 0.0)
}

///|
test "multi-query MRR and MAP" {
  let rankings = [["a", "x"], ["x", "b"], ["z"]]
  let relevance = [["a"], ["b"], ["missing"]]
  assert_eq(
    @MoonRetrieve.mean_reciprocal_rank(rankings, relevance, cutoff=10),
    0.5,
  )
  assert_eq(
    @MoonRetrieve.mean_average_precision(rankings, relevance, cutoff=10),
    0.5,
  )
  assert_eq(@MoonRetrieve.mean_reciprocal_rank([], [], cutoff=10), 0.0)
  assert_eq(@MoonRetrieve.mean_average_precision([["a"]], [], cutoff=10), 0.0)
}

///|
test "corpus coverage counts unique retrieved documents" {
  let rankings = [["a", "b"], ["b", "c"], ["outside"]]
  assert_eq(
    @MoonRetrieve.corpus_coverage(rankings, ["a", "b", "c", "d"], cutoff=2),
    0.75,
  )
  assert_eq(@MoonRetrieve.corpus_coverage(rankings, [], cutoff=2), 0.0)
}
