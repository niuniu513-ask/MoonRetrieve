///|
test "retrieval trace records ranking evidence" {
  let engine = @MoonRetrieve.Engine::new()
  engine.add_document("guide.md", "MoonBit retrieval runs locally.")
  engine.add_document("faq.md", "RAG retrieval uses local documents.")
  let trace = engine.trace("MoonBit RAG", top_k=2)
  assert_eq(trace.top_k, 2)
  assert_true(trace.query_terms.contains("moonbit"))
  assert_true(trace.query_terms.contains("rag"))
  assert_eq(trace.hits.length(), 2)
  assert_eq(trace.hits[0].rank, 1)
  assert_true(trace.hits[0].matched_terms.length() > 0)
  assert_true(trace.hits[0].text.length() > 0)
  assert_eq(trace.source_count, 2)
  let json = @json.to_json(trace).stringify()
  assert_true(json.contains("matched_terms"))
  assert_true(json.contains("guide.md#0") || json.contains("faq.md#0"))
}

///|
test "empty retrieval trace is stable" {
  let trace = @MoonRetrieve.Engine::new().trace("missing", top_k=0)
  assert_eq(trace.top_k, 0)
  assert_true(trace.hits.is_empty())
  assert_eq(trace.source_count, 0)
}

///|
test "trace source count differs from matching chunk count" {
  let index = @MoonRetrieve.SearchIndex::new()
  index.add("same.md#0", "MoonBit retrieval.")
  index.add("same.md#1", "MoonBit examples.")
  index.add("other.md#0", "Unrelated content.")
  let engine = @MoonRetrieve.Engine::new(index~)
  let trace = engine.trace("MoonBit", top_k=5)
  assert_eq(trace.hits.length(), 2)
  assert_eq(trace.source_count, 1)
  assert_eq(trace.hits[0].source_doc_id, "same.md")
  assert_eq(trace.hits[1].source_doc_id, "same.md")
}
