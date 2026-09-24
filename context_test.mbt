///|
test "context includes query and sources" {
  let cb = @MoonRetrieve.ContextBuilder::new(max_tokens=100)
  let results = [
    @MoonRetrieve.SearchResult::new(
      "guide.md", 1.0, "月兔是一种编程语言",
    ),
    @MoonRetrieve.SearchResult::new("faq.md", 0.5, "它面向云边计算"),
  ]
  let ctx = cb.build("月兔是什么", results)
  assert_true(ctx.split("问题：月兔是什么").count() == 2)
  assert_true(ctx.split("guide.md").count() == 2)
  assert_true(ctx.split("faq.md").count() == 2)
}

///|
test "context respects token budget" {
  let cb = @MoonRetrieve.ContextBuilder::new(max_tokens=4)
  let results = [
    @MoonRetrieve.SearchResult::new(
      "long.md", 1.0, "这是很长的一段资料内容",
    ),
    @MoonRetrieve.SearchResult::new("other.md", 0.5, "别的资料"),
  ]
  let ctx = cb.build("问题", results)
  assert_true(ctx.split("other.md").count() == 1)
}

///|
test "diverse context keeps one chunk per source" {
  let cb = @MoonRetrieve.ContextBuilder::new(max_tokens=100)
  let results = [
    @MoonRetrieve.SearchResult::new("guide.md#0", 3.0, "MoonBit 基础"),
    @MoonRetrieve.SearchResult::new("guide.md#1", 2.0, "MoonBit 工具链"),
    @MoonRetrieve.SearchResult::new("faq.md#0", 1.0, "RAG 检索"),
  ]
  let context = cb.build_diverse("MoonBit RAG", results, max_sources=2)
  assert_true(context.contains("guide.md#0"))
  assert_false(context.contains("guide.md#1"))
  assert_true(context.contains("faq.md#0"))
}

///|
test "context report skips oversized chunk and cites later result" {
  let cb = @MoonRetrieve.ContextBuilder::new(max_tokens=1)
  let results = [
    @MoonRetrieve.SearchResult::new(
      "long.md", 2.0, "moonbit retrieval benchmark",
    ),
    @MoonRetrieve.SearchResult::new("short.md", 1.0, "rag"),
  ]
  let report = cb.build_report("rag", results)
  assert_eq(report.citations.length(), 1)
  assert_eq(report.citations[0].number, 1)
  assert_eq(report.citations[0].doc_id, "short.md")
  assert_eq(report.citations[0].score, 1.0)
  assert_eq(report.used_content_tokens, 1)
  assert_eq(report.skipped_results, 1)
  assert_true(report.estimated_prompt_tokens > report.used_content_tokens)
  assert_true(report.prompt.contains("[1]（来源：short.md）"))
  assert_false(report.prompt.contains("long.md"))
  assert_eq(cb.build("rag", results), report.prompt)
  let json = @json.to_json(report).stringify()
  assert_true(json.contains("short.md"))
  assert_true(json.contains("used_content_tokens"))
}

///|
test "diverse report cites one chunk per source" {
  let cb = @MoonRetrieve.ContextBuilder::new(max_tokens=10)
  let results = [
    @MoonRetrieve.SearchResult::new("guide.md#1", 2.0, "moonbit"),
    @MoonRetrieve.SearchResult::new("guide.md#2", 1.0, "language"),
    @MoonRetrieve.SearchResult::new("faq.md#0", 0.5, "retrieval"),
  ]
  let report = cb.build_diverse_report("moonbit", results, max_sources=2)
  assert_eq(report.citations.length(), 2)
  assert_eq(report.citations[0].doc_id, "guide.md#1")
  assert_eq(report.citations[1].doc_id, "faq.md#0")
  assert_eq(report.citations[1].number, 2)
  assert_false(report.prompt.contains("guide.md#2"))
  assert_eq(cb.build_diverse("moonbit", results, max_sources=2), report.prompt)
}

///|
test "zero content budget yields no citations" {
  let cb = @MoonRetrieve.ContextBuilder::new(max_tokens=0)
  let results = [@MoonRetrieve.SearchResult::new("guide.md", 1.0, "moonbit")]
  let report = cb.build_report("moonbit", results)
  assert_true(report.citations.is_empty())
  assert_eq(report.used_content_tokens, 0)
  assert_eq(report.skipped_results, 1)
}
