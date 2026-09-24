///|
fn main {
  let engine = @search.Engine::new()
  engine.add_document(
    "guide", "MoonBit 是面向云边计算的编程语言。",
  )
  engine.add_document("faq", "RAG 是检索增强生成。")

  let results = engine.search("RAG 是什么", top_k=3)
  println("Top \{results.length()} results:")
  for r in results {
    println("  [\{r.doc_id}] score=\{r.score}")
  }

  let report = engine.build_diverse_context_report(
    "RAG 是什么",
    top_k=3,
    max_tokens=80,
  )
  println("")
  println("Context:")
  println(report.prompt)
  println("Citations: \{report.citations.length()}")
  for citation in report.citations {
    println("  [\{citation.number}] \{citation.doc_id}")
  }
}
