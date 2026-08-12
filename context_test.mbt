///|
test "context includes query and sources" {
  let cb = @MoonSearch.ContextBuilder::new(max_tokens=100)
  let results = [
    @MoonSearch.SearchResult::new(
      "guide.md", 1.0, "月兔是一种编程语言",
    ),
    @MoonSearch.SearchResult::new("faq.md", 0.5, "它面向云边计算"),
  ]
  let ctx = cb.build("月兔是什么", results)
  assert_true(ctx.split("问题：月兔是什么").count() == 2)
  assert_true(ctx.split("guide.md").count() == 2)
  assert_true(ctx.split("faq.md").count() == 2)
}

///|
test "context respects token budget" {
  let cb = @MoonSearch.ContextBuilder::new(max_tokens=4)
  let results = [
    @MoonSearch.SearchResult::new(
      "long.md", 1.0, "这是很长的一段资料内容",
    ),
    @MoonSearch.SearchResult::new("other.md", 0.5, "别的资料"),
  ]
  let ctx = cb.build("问题", results)
  assert_true(ctx.split("other.md").count() == 1)
}
