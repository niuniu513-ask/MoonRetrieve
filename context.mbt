///|
/// LLM 上下文组装器：把检索结果按 token 预算拼成可直接喂给大模型的提示词。
pub struct ContextBuilder {
  max_tokens : Int
  tokenizer : Tokenizer
} derive(ToJson, FromJson)

///|
pub fn ContextBuilder::new(
  max_tokens? : Int = 800,
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> ContextBuilder {
  { max_tokens, tokenizer }
}

///|
/// 组装上下文：先放问题，再按相关性放入带编号的片段，超出预算即停止。
pub fn ContextBuilder::build(
  self : ContextBuilder,
  query : String,
  results : Array[SearchResult],
) -> String {
  let sb = StringBuilder::new()
  sb.write_string(
    "请仅根据以下资料回答问题，不要编造资料中没有的内容。\n\n",
  )
  sb.write_string("问题：")
  sb.write_string(query)
  sb.write_string("\n\n资料：\n")
  let mut used = 0
  for i = 0; i < results.length(); i = i + 1 {
    let r = results[i]
    let est = self.tokenizer.estimate_tokens(r.text)
    if used + est > self.max_tokens {
      break
    }
    sb.write_string("\n[")
    sb.write_string((i + 1).to_string())
    sb.write_string("]（来源：")
    sb.write_string(r.doc_id)
    sb.write_string("）\n")
    sb.write_string(r.text)
    sb.write_string("\n")
    used = used + est
  }
  sb.to_string()
}
