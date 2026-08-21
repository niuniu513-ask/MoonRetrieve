///|
/// Human-readable relevance evidence for one search result.
pub struct ResultExplanation {
  doc_id : String
  score : Double
  matched_terms : Array[String]
  missing_terms : Array[String]
  matched_required : Int
  total_required : Int
  token_overlap : Double
} derive(Debug)

///|
fn unique_query_tokens(query : String, tokenizer : Tokenizer) -> Array[String] {
  let out : Array[String] = []
  for token in tokenizer.tokenize(query) {
    if !out.contains(token) {
      out.push(token)
    }
  }
  out
}

///|
pub fn explain_result(
  query : String,
  result : SearchResult,
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> ResultExplanation {
  let query_tokens = unique_query_tokens(query, tokenizer)
  let text_tokens = unique_query_tokens(result.text, tokenizer)
  let matched : Array[String] = []
  let missing : Array[String] = []
  for token in query_tokens {
    if text_tokens.contains(token) {
      matched.push(token)
    } else {
      missing.push(token)
    }
  }
  {
    doc_id: result.doc_id,
    score: result.score,
    matched_terms: matched,
    missing_terms: missing,
    matched_required: matched.length(),
    total_required: query_tokens.length(),
    token_overlap: token_jaccard(query, result.text, tokenizer~),
  }
}

///|
pub fn explain_results(
  query : String,
  results : Array[SearchResult],
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> Array[ResultExplanation] {
  let out : Array[ResultExplanation] = []
  for result in results {
    out.push(explain_result(query, result, tokenizer~))
  }
  out
}

///|
pub fn explanation_summary(explanation : ResultExplanation) -> String {
  let builder = StringBuilder::new()
  builder.write_string(explanation.doc_id)
  builder.write_string(": matched ")
  builder.write_string(explanation.matched_required.to_string())
  builder.write_string("/")
  builder.write_string(explanation.total_required.to_string())
  if !explanation.matched_terms.is_empty() {
    builder.write_string(" [")
    for i = 0; i < explanation.matched_terms.length(); i = i + 1 {
      if i > 0 {
        builder.write_string(", ")
      }
      builder.write_string(explanation.matched_terms[i])
    }
    builder.write_string("]")
  }
  builder.to_string()
}
