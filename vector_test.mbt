///|
test "cosine similarity" {
  let v1 = [1.0, 0.0]
  let v2 = [0.0, 1.0]
  let v3 = [2.0, 0.0]
  assert_true(@MoonSearch.cosine(v1, v2) == 0.0)
  let s = @MoonSearch.cosine(v1, v3)
  assert_true(s > 0.999 && s < 1.001)
  assert_true(@MoonSearch.cosine([1.0], [1.0, 2.0]) == 0.0)
}

///|
test "vector search top k" {
  let vi = @MoonSearch.VectorIndex::new()
  vi.add("cat", [1.0, 0.0, 0.0])
  vi.add("dog", [0.0, 1.0, 0.0])
  let results = vi.search([0.9, 0.1, 0.0], top_k=1)
  assert_true(results.length() == 1)
  assert_true(results[0].id == "cat")
  assert_true(vi.count() == 2)
}

///|
test "rrf fusion" {
  let a = [
    @MoonSearch.ScoredDoc::new("x", 0.9),
    @MoonSearch.ScoredDoc::new("y", 0.8),
  ]
  let b = [
    @MoonSearch.ScoredDoc::new("y", 0.7),
    @MoonSearch.ScoredDoc::new("z", 0.6),
  ]
  let fused = @MoonSearch.rrf_fuse(a, b, top_k=3)
  assert_true(fused.length() == 3)
  assert_true(fused[0].id == "y")
  assert_true(fused[1].id == "x")
  assert_true(fused[2].id == "z")
}
