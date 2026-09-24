///|
/// One ranked hit and the terms supporting its retrieval score.
pub struct TraceHit {
  rank : Int
  doc_id : String
  source_doc_id : String
  score : Double
  matched_terms : Array[String]
  missing_terms : Array[String]
  token_overlap : Double
  text : String
} derive(ToJson)

///|
/// A JSON-serializable record of one retrieval run.
pub struct RetrievalTrace {
  query : String
  query_terms : Array[String]
  top_k : Int
  hits : Array[TraceHit]
  source_count : Int
} derive(ToJson)

///|
/// Record ranked chunks and their matching evidence.
pub fn Engine::trace(
  self : Engine,
  query : String,
  top_k? : Int = 10,
) -> RetrievalTrace {
  let limit = if top_k > 0 { top_k } else { 0 }
  let query_terms : Array[String] = []
  for token in self.index.tokenizer.tokenize(query) {
    if !query_terms.contains(token) {
      query_terms.push(token)
    }
  }
  let results = self.search(query, top_k=limit)
  let explanations = explain_results(
    query,
    results,
    tokenizer=self.index.tokenizer,
  )
  let hits : Array[TraceHit] = []
  let sources : Array[String] = []
  for i = 0; i < results.length(); i = i + 1 {
    let result = results[i]
    let explanation = explanations[i]
    let source = source_doc_id(result.doc_id)
    if !sources.contains(source) {
      sources.push(source)
    }
    hits.push({
      rank: i + 1,
      doc_id: result.doc_id,
      source_doc_id: source,
      score: result.score,
      matched_terms: explanation.matched_terms,
      missing_terms: explanation.missing_terms,
      token_overlap: explanation.token_overlap,
      text: result.text,
    })
  }
  { query, query_terms, top_k: limit, hits, source_count: sources.length(), }
}
