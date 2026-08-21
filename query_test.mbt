///|
test "parse plain clauses" {
  let plan = @MoonRetrieve.parse_query("moonbit local search").unwrap()
  assert_eq(plan.original, "moonbit local search")
  assert_eq(plan.clauses.length(), 3)
  assert_eq(plan.positive_values(), ["moonbit", "local", "search"])
  assert_true(plan.excluded_values().is_empty())
  assert_true(plan.required_values().is_empty())
  assert_eq(plan.search_text(), "moonbit local search")
}

///|
test "parse required excluded phrase and prefix" {
  let plan = @MoonRetrieve.parse_query(
    "+moonbit -python \"local search\" retriev*",
  ).unwrap()
  assert_eq(plan.clauses.length(), 4)
  assert_true(plan.clauses[0].required)
  assert_true(plan.clauses[1].excluded)
  assert_true(plan.clauses[2].phrase)
  assert_eq(plan.clauses[2].value, "local search")
  assert_true(plan.clauses[3].prefix)
  assert_eq(plan.required_values(), ["moonbit"])
  assert_eq(plan.excluded_values(), ["python"])
}

///|
test "parse field-qualified clauses" {
  let plan = @MoonRetrieve.parse_query("title:moonbit +body:retrieval tag:rag*").unwrap()
  assert_eq(plan.clauses[0].field, Some("title"))
  assert_eq(plan.clauses[0].value, "moonbit")
  assert_eq(plan.clauses[1].field, Some("body"))
  assert_true(plan.clauses[1].required)
  assert_eq(plan.clauses[2].field, Some("tag"))
  assert_true(plan.clauses[2].prefix)
  assert_true(plan.has_field("title"))
  assert_false(plan.has_field("author"))
}

///|
test "query parser rejects malformed syntax" {
  assert_true(@MoonRetrieve.parse_query("") is Err(_))
  assert_true(@MoonRetrieve.parse_query("   ") is Err(_))
  assert_true(@MoonRetrieve.parse_query("\"unterminated") is Err(_))
  assert_true(@MoonRetrieve.parse_query("+") is Err(_))
  assert_true(@MoonRetrieve.parse_query("-") is Err(_))
  assert_true(@MoonRetrieve.parse_query("*") is Err(_))
  assert_true(@MoonRetrieve.parse_query("mo*n") is Err(_))
  assert_true(@MoonRetrieve.parse_query("abc\"def") is Err(_))
}

///|
test "format query plan is stable" {
  let inputs = [
    "moonbit local", "+moonbit -python", "\"local search\" retriev*", "title:moonbit +body:retrieval",
  ]
  for input in inputs {
    let plan = @MoonRetrieve.parse_query(input).unwrap()
    assert_eq(@MoonRetrieve.format_query_plan(plan), input)
  }
}

///|
test "required clause filters text" {
  let plan = @MoonRetrieve.parse_query("+moonbit +retrieval").unwrap()
  assert_true(plan.matches("MoonBit retrieval library"))
  assert_false(plan.matches("MoonBit compiler"))
  assert_false(plan.matches("retrieval library"))
}

///|
test "excluded clause rejects text" {
  let plan = @MoonRetrieve.parse_query("moonbit -python").unwrap()
  assert_true(plan.matches("MoonBit native search"))
  assert_false(plan.matches("MoonBit Python binding"))
}

///|
test "phrase clause matches exact text when required" {
  let plan = @MoonRetrieve.parse_query("+\"local search\"").unwrap()
  assert_true(plan.matches("a local search library"))
  assert_false(plan.matches("search local documents"))
}

///|
test "prefix clause matches token prefix" {
  let plan = @MoonRetrieve.parse_query("+retriev*").unwrap()
  assert_true(plan.matches("retrieval and retrieving documents"))
  assert_false(plan.matches("search documents"))
}

///|
test "optional clauses do not filter" {
  let plan = @MoonRetrieve.parse_query("moonbit retrieval").unwrap()
  assert_true(plan.matches("unrelated text"))
}

///|
test "filter results with query plan" {
  let results = [
    @MoonRetrieve.SearchResult::new("a", 2.0, "MoonBit retrieval library"),
    @MoonRetrieve.SearchResult::new("b", 1.0, "Python retrieval library"),
    @MoonRetrieve.SearchResult::new("c", 0.5, "MoonBit compiler"),
  ]
  let plan = @MoonRetrieve.parse_query("+moonbit -compiler").unwrap()
  let filtered = @MoonRetrieve.filter_with_query_plan(results, plan)
  assert_eq(filtered.length(), 1)
  assert_eq(filtered[0].doc_id, "a")
}

///|
test "query values are unique in helper lists" {
  let plan = @MoonRetrieve.parse_query(
    "moonbit moonbit -python -python +required +required",
  ).unwrap()
  assert_eq(plan.positive_values(), ["moonbit", "required"])
  assert_eq(plan.excluded_values(), ["python"])
  assert_eq(plan.required_values(), ["required"])
}

///|
test "explain result reports matched and missing terms" {
  let result = @MoonRetrieve.SearchResult::new(
    "guide#0", 2.5, "MoonBit provides local full text search",
  )
  let explanation = @MoonRetrieve.explain_result("moonbit search rag", result)
  assert_eq(explanation.doc_id, "guide#0")
  assert_eq(explanation.score, 2.5)
  assert_true(explanation.matched_terms.contains("moonbit"))
  assert_true(explanation.matched_terms.contains("search"))
  assert_true(explanation.missing_terms.contains("rag"))
  assert_eq(explanation.matched_required, 2)
  assert_eq(explanation.total_required, 3)
}

///|
test "explain multiple results and summarize" {
  let results = [
    @MoonRetrieve.SearchResult::new("a", 2.0, "moonbit retrieval"),
    @MoonRetrieve.SearchResult::new("b", 1.0, "banana bread"),
  ]
  let explanations = @MoonRetrieve.explain_results("moonbit retrieval", results)
  assert_eq(explanations.length(), 2)
  assert_eq(explanations[0].matched_required, 2)
  assert_eq(explanations[1].matched_required, 0)
  assert_eq(
    @MoonRetrieve.explanation_summary(explanations[0]),
    "a: matched 2/2 [moonbit, retrieval]",
  )
  assert_eq(
    @MoonRetrieve.explanation_summary(explanations[1]),
    "b: matched 0/2",
  )
}
