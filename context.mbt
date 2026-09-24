///|
/// LLM 上下文组装器：把检索结果按 token 预算拼成可直接喂给大模型的提示词。
pub struct ContextBuilder {
  max_tokens : Int
  tokenizer : Tokenizer
} derive(ToJson, FromJson)

///|
/// A selected chunk and its citation number in the generated prompt.
pub struct ContextCitation {
  number : Int
  doc_id : String
  score : Double
  text : String
  estimated_tokens : Int
} derive(ToJson)

///|
/// Prompt plus the exact chunks used to construct it.
pub struct ContextReport {
  prompt : String
  citations : Array[ContextCitation]
  used_content_tokens : Int
  estimated_prompt_tokens : Int
  skipped_results : Int
} derive(ToJson)

///|
pub fn ContextBuilder::new(
  max_tokens? : Int = 800,
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> ContextBuilder {
  { max_tokens, tokenizer, }
}

///|
/// 组装上下文：按输入顺序选取预算内的片段，并跳过放不下的结果。
pub fn ContextBuilder::build(
  self : ContextBuilder,
  query : String,
  results : Array[SearchResult],
) -> String {
  self.build_report(query, results).prompt
}

///|
/// Select chunks under the retrieved-content budget and retain citation data.
pub fn ContextBuilder::build_report(
  self : ContextBuilder,
  query : String,
  results : Array[SearchResult],
) -> ContextReport {
  let citations : Array[ContextCitation] = []
  let budget = if self.max_tokens > 0 { self.max_tokens } else { 0 }
  let mut used = 0
  let mut skipped = 0
  for result in results {
    let estimated_tokens = self.tokenizer.estimate_tokens(result.text)
    if budget == 0 || estimated_tokens > budget - used {
      skipped = skipped + 1
      continue
    }
    citations.push({
      number: citations.length() + 1,
      doc_id: result.doc_id,
      score: result.score,
      text: result.text,
      estimated_tokens,
    })
    used = used + estimated_tokens
  }
  let sb = StringBuilder()
  sb.write_string(
    "请仅根据以下资料回答问题，不要编造资料中没有的内容。\n\n",
  )
  sb.write_string("问题：")
  sb.write_string(query)
  sb.write_string("\n\n资料：\n")
  for citation in citations {
    sb.write_string("\n[")
    sb.write_string(citation.number.to_string())
    sb.write_string("]（来源：")
    sb.write_string(citation.doc_id)
    sb.write_string("）\n")
    sb.write_string(citation.text)
    sb.write_string("\n")
  }
  let prompt = sb.to_string()
  {
    prompt,
    citations,
    used_content_tokens: used,
    estimated_prompt_tokens: self.tokenizer.estimate_tokens(prompt),
    skipped_results: skipped,
  }
}

///|
/// 每个原始文档只保留最高分分块，再按 token 预算组装上下文。
pub fn ContextBuilder::build_diverse(
  self : ContextBuilder,
  query : String,
  results : Array[SearchResult],
  max_sources? : Int = 10,
) -> String {
  self.build_diverse_report(query, results, max_sources~).prompt
}

///|
/// Keep the strongest chunk per source and return its citation report.
pub fn ContextBuilder::build_diverse_report(
  self : ContextBuilder,
  query : String,
  results : Array[SearchResult],
  max_sources? : Int = 10,
) -> ContextReport {
  let selected = deduplicate_by_source(results, limit=max_sources)
  self.build_report(query, selected)
}
