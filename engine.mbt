///|
/// 一站式本地检索引擎：文档 -> 分块 -> BM25 索引 -> Top-K 检索。
pub struct Engine {
  chunker : Chunker
  index : SearchIndex
} derive(ToJson, FromJson)

///|
pub fn Engine::new(
  chunker? : Chunker = Chunker::new(),
  index? : SearchIndex = SearchIndex::new(),
) -> Engine {
  { chunker, index, }
}

///|
/// 添加一篇文档（自动分块后逐块建索引），返回更新后的引擎。
pub fn Engine::add_document(
  self : Engine,
  doc_id : String,
  text : String,
) -> Unit {
  let chunks = self.chunker.chunk(doc_id, text)
  for chunk in chunks {
    self.index.add(chunk.doc_id + "#" + chunk.index.to_string(), chunk.text)
  }
}

///|
/// 替换同一原始文档 ID 的全部旧分块，并写入新内容。
/// 返回被删除的旧分块数量。
pub fn Engine::replace_document(
  self : Engine,
  doc_id : String,
  text : String,
) -> Int {
  let removed = self.remove_document(doc_id)
  self.add_document(doc_id, text)
  removed
}

///|
/// 批量添加文档。
pub fn Engine::add_documents(
  self : Engine,
  docs : Array[(String, String)],
) -> Unit {
  for pair in docs {
    let (id, text) = pair
    self.add_document(id, text)
  }
}

///|
/// 检索 Top-K 分块。
pub fn Engine::search(
  self : Engine,
  query : String,
  top_k? : Int = 10,
) -> Array[SearchResult] {
  self.index.search(query, top_k~)
}

///|
/// Return the best matching chunk from each original document.
pub fn Engine::search_sources(
  self : Engine,
  query : String,
  top_k? : Int = 10,
) -> Array[SearchResult] {
  if top_k <= 0 {
    return []
  }
  deduplicate_by_source(self.search(query, top_k=self.count()), limit=top_k)
}

///|
/// Evaluate ranked original documents against a labeled query set.
pub fn Engine::evaluate_queries(
  self : Engine,
  cases : Array[EvaluationCase],
  cutoff? : Int = 10,
) -> EvaluationReport {
  let queries : Array[EvaluatedQuery] = []
  let metrics : Array[RetrievalMetrics] = []
  for case in cases {
    let ranked_doc_ids : Array[String] = []
    for result in self.search_sources(case.query, top_k=cutoff) {
      ranked_doc_ids.push(source_doc_id(result.doc_id))
    }
    let measurement = evaluate_ranking(
      ranked_doc_ids,
      case.relevant_doc_ids,
      cutoff~,
    )
    queries.push({ query: case.query, ranked_doc_ids, metrics: measurement, })
    metrics.push(measurement)
  }
  { cutoff, queries, summary: summarize_evaluations(metrics), }
}

///|
/// 短语检索 Top-K 分块。
pub fn Engine::search_phrase(
  self : Engine,
  query : String,
  top_k? : Int = 10,
) -> Array[SearchResult] {
  self.index.search_phrase(query, top_k~)
}

///|
/// 布尔检索 Top-K 分块（AND / OR / -term）。
pub fn Engine::search_boolean(
  self : Engine,
  query : String,
  top_k? : Int = 10,
) -> Array[SearchResult] {
  self.index.search_boolean(query, top_k~)
}

///|
/// 前缀检索 Top-K 分块。
pub fn Engine::search_prefix(
  self : Engine,
  prefix : String,
  top_k? : Int = 10,
) -> Array[SearchResult] {
  self.index.search_prefix(prefix, top_k~)
}

///|
/// 检索并返回限定长度的命中片段，适合列表或终端展示。
pub fn Engine::search_snippets(
  self : Engine,
  query : String,
  top_k? : Int = 10,
  max_chars? : Int = 160,
) -> Array[SearchResult] {
  let results = self.search(query, top_k~)
  snippets_for_results(
    results,
    query,
    max_chars~,
    tokenizer=self.index.tokenizer,
  )
}

///|
/// 检索并返回每条结果的相关性解释。
pub fn Engine::search_explained(
  self : Engine,
  query : String,
  top_k? : Int = 10,
) -> Array[ResultExplanation] {
  let results = self.search(query, top_k~)
  explain_results(query, results, tokenizer=self.index.tokenizer)
}

///|
/// 检索并按 token 预算生成可直接交给 LLM 的上下文。
pub fn Engine::build_context(
  self : Engine,
  query : String,
  top_k? : Int = 10,
  max_tokens? : Int = 800,
) -> String {
  self.build_context_report(query, top_k~, max_tokens~).prompt
}

///|
/// Return the prompt and the exact chunks selected for citation.
pub fn Engine::build_context_report(
  self : Engine,
  query : String,
  top_k? : Int = 10,
  max_tokens? : Int = 800,
) -> ContextReport {
  let results = self.search(query, top_k~)
  let builder = ContextBuilder::new(max_tokens~)
  builder.build_report(query, results)
}

///|
/// 检索后按来源去重，生成覆盖更多文档的 RAG 上下文。
pub fn Engine::build_diverse_context(
  self : Engine,
  query : String,
  top_k? : Int = 10,
  max_tokens? : Int = 800,
) -> String {
  self.build_diverse_context_report(query, top_k~, max_tokens~).prompt
}

///|
/// Build a citation report with at most one chunk from each source document.
pub fn Engine::build_diverse_context_report(
  self : Engine,
  query : String,
  top_k? : Int = 10,
  max_tokens? : Int = 800,
) -> ContextReport {
  let results = self.search_sources(query, top_k~)
  let builder = ContextBuilder::new(max_tokens~)
  builder.build_diverse_report(query, results, max_sources=top_k)
}

///|
/// 对文本执行查询词高亮。
pub fn Engine::highlight(
  self : Engine,
  text : String,
  query : String,
) -> String {
  highlight(text, query, tokenizer=self.index.tokenizer)
}

///|
/// 索引中的分块总数。
pub fn Engine::count(self : Engine) -> Int {
  self.index.count()
}

///|
/// 按原始文档 ID 删除一篇文档及其全部分块，返回删除的分块数。
pub fn Engine::remove_document(self : Engine, doc_id : String) -> Int {
  self.index.remove_if(fn(id) { id == doc_id || id.has_prefix(doc_id + "#") })
}

///|
/// 返回索引统计信息。
pub fn Engine::stats(self : Engine) -> IndexStats {
  self.index.stats()
}

///|
/// 序列化为 JSON 字符串。
pub fn Engine::save(self : Engine) -> String {
  @json.to_json(self).stringify()
}

///|
/// 从 JSON 字符串恢复引擎。
pub fn Engine::try_load(json : String) -> Result[Engine, String] {
  try {
    let j = @json.parse(json)
    Ok(@json.from_json(j))
  } catch {
    err => Err(err.to_string())
  }
}
