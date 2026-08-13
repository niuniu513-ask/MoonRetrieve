///|
/// 倒排索引中的一条 posting：文档编号 + 词频。
pub struct Posting {
  doc_id : Int
  tf : Int
} derive(ToJson, FromJson, Eq, Debug)

///|
/// BM25 倒排索引。
///
/// 支持增量添加文档、Top-K 检索，以及 JSON 序列化/反序列化。
/// 设计为不可变更新风格：`add` 返回添加后的新索引。
pub struct SearchIndex {
  mut ids : Array[String]
  mut texts : Array[String]
  mut lens : Array[Int]
  mut postings : Map[String, Array[Posting]]
  mut total_docs : Int
  mut sum_len : Int
  mut avg_dl : Double
  k1 : Double
  b : Double
  tokenizer : Tokenizer
} derive(ToJson, FromJson)

///|
pub fn SearchIndex::new(
  k1? : Double = 1.2,
  b? : Double = 0.75,
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> SearchIndex {
  {
    ids: [],
    texts: [],
    lens: [],
    postings: Map([]),
    total_docs: 0,
    sum_len: 0,
    avg_dl: 0.0,
    k1,
    b,
    tokenizer,
  }
}

///|
/// 向索引添加一篇文档，返回新索引。`id` 可以是文档路径或分块 ID。
pub fn SearchIndex::add(self : SearchIndex, id : String, text : String) -> Unit {
  let tokens = self.tokenizer.tokenize(text)
  let doc_id = self.total_docs
  self.ids.push(id)
  self.texts.push(text)
  self.lens.push(tokens.length())
  let tf : Map[String, Int] = Map([])
  for t in tokens {
    tf[t] = tf.get_or_default(t, 0) + 1
  }
  for kv in tf.iter() {
    let (term, count) = kv
    let postings = self.postings.get_or_default(term, [])
    postings.push({ doc_id, tf: count })
    self.postings[term] = postings
  }
  self.total_docs = self.total_docs + 1
  self.sum_len = self.sum_len + tokens.length()
  self.avg_dl = self.sum_len.to_double() / self.total_docs.to_double()
}

///|
/// 对查询执行 BM25 检索，返回按分数降序排列的 Top-K 结果。
pub fn SearchIndex::search(
  self : SearchIndex,
  query : String,
  top_k? : Int = 10,
) -> Array[SearchResult] {
  let q_tokens = self.tokenizer.tokenize(query)
  let unique = unique_tokens(q_tokens)
  if unique.is_empty() || self.total_docs == 0 {
    return []
  }
  let scores : Array[(Int, Double)] = []
  for i = 0; i < self.total_docs; i = i + 1 {
    scores.push((i, self.score_doc(unique, i)))
  }
  scores.sort_by(fn(a, b) {
    let cmp = b.1.compare(a.1)
    if cmp != 0 {
      cmp
    } else {
      a.0.compare(b.0)
    }
  })
  let out : Array[SearchResult] = []
  for i = 0; i < scores.length() && i < top_k; i = i + 1 {
    let (doc, score) = scores[i]
    if score > 0.0 {
      out.push({ doc_id: self.ids[doc], score, text: self.texts[doc] })
    }
  }
  out
}

///|
/// 短语检索：查询短语必须按原文顺序连续出现，结果仍按 BM25 分数排序。
pub fn SearchIndex::search_phrase(
  self : SearchIndex,
  query : String,
  top_k? : Int = 10,
) -> Array[SearchResult] {
  let q_tokens = self.tokenizer.tokenize(query)
  if q_tokens.is_empty() || self.total_docs == 0 {
    return []
  }
  let unique = unique_tokens(q_tokens)
  let scored : Array[(Int, Double)] = []
  for i = 0; i < self.total_docs; i = i + 1 {
    if self.texts[i].contains(query) {
      scored.push((i, self.score_doc(unique, i)))
    }
  }
  scored.sort_by(fn(a, b) {
    let cmp = b.1.compare(a.1)
    if cmp != 0 {
      cmp
    } else {
      a.0.compare(b.0)
    }
  })
  let out : Array[SearchResult] = []
  for i = 0; i < scored.length() && i < top_k; i = i + 1 {
    let (doc, score) = scored[i]
    out.push({ doc_id: self.ids[doc], score, text: self.texts[doc] })
  }
  out
}

///|
/// 布尔检索：支持 `AND` / `OR` 连接词与 `-term` 排除。
///
/// 示例：
/// - `"moonbit AND rag"`：同时包含 moonbit 与 rag
/// - `"moonbit OR rag"`：包含任一即可
/// - `"moonbit -old"`：包含 moonbit 且不含 old
pub fn SearchIndex::search_boolean(
  self : SearchIndex,
  query : String,
  top_k? : Int = 10,
) -> Array[SearchResult] {
  let parts : Array[String] = []
  for p in query.split(" ") {
    let s = p.trim().to_owned()
    if !s.is_empty() {
      parts.push(s)
    }
  }
  let must : Array[String] = []
  let any : Array[String] = []
  let not : Array[String] = []
  let has_and = parts.contains("AND")
  let has_or = parts.contains("OR")
  for p in parts {
    if p == "AND" || p == "OR" {
      continue
    }
    if p.has_prefix("-") {
      let t = p.sub(start=1, end=p.length()).to_owned()
      if !t.is_empty() {
        not.push(t)
      }
    } else if has_and {
      must.push(p)
    } else if has_or {
      any.push(p)
    } else {
      any.push(p)
    }
  }
  let must_tokens = self.expand_terms(must)
  let any_tokens = self.expand_terms(any)
  let not_tokens = self.expand_terms(not)
  if must_tokens.is_empty() && any_tokens.is_empty() {
    return []
  }
  let positive = unique_tokens(must_tokens + any_tokens)
  let scored : Array[(Int, Double)] = []
  for i = 0; i < self.total_docs; i = i + 1 {
    if self.match_boolean(i, must_tokens, any_tokens, not_tokens) {
      scored.push((i, self.score_doc(positive, i)))
    }
  }
  scored.sort_by(fn(a, b) {
    let cmp = b.1.compare(a.1)
    if cmp != 0 {
      cmp
    } else {
      a.0.compare(b.0)
    }
  })
  let out : Array[SearchResult] = []
  for i = 0; i < scored.length() && i < top_k; i = i + 1 {
    let (doc, score) = scored[i]
    out.push({ doc_id: self.ids[doc], score, text: self.texts[doc] })
  }
  out
}

///|
/// 前缀检索：匹配以给定前缀开头的词条，结果按 BM25 分数排序。
pub fn SearchIndex::search_prefix(
  self : SearchIndex,
  prefix : String,
  top_k? : Int = 10,
) -> Array[SearchResult] {
  if prefix.is_empty() || self.total_docs == 0 {
    return []
  }
  let terms : Array[String] = []
  for kv in self.postings.iter() {
    let (term, _) = kv
    if term.has_prefix(prefix) {
      terms.push(term)
    }
  }
  if terms.is_empty() {
    return []
  }
  let scored : Array[(Int, Double)] = []
  for i = 0; i < self.total_docs; i = i + 1 {
    let score = self.score_doc(terms, i)
    if score > 0.0 {
      scored.push((i, score))
    }
  }
  scored.sort_by(fn(a, b) {
    let cmp = b.1.compare(a.1)
    if cmp != 0 {
      cmp
    } else {
      a.0.compare(b.0)
    }
  })
  let out : Array[SearchResult] = []
  for i = 0; i < scored.length() && i < top_k; i = i + 1 {
    let (doc, score) = scored[i]
    out.push({ doc_id: self.ids[doc], score, text: self.texts[doc] })
  }
  out
}

///|
/// 序列化为 JSON 字符串。
pub fn SearchIndex::save(self : SearchIndex) -> String {
  @json.to_json(self).stringify()
}

///|
/// 从 JSON 字符串恢复索引。
pub fn SearchIndex::try_load(json : String) -> Result[SearchIndex, String] {
  try {
    let j = @json.parse(json)
    Ok(@json.from_json(j))
  } catch {
    err => Err(err.to_string())
  }
}

///|
/// 当前索引中的文档/分块数量。
pub fn SearchIndex::count(self : SearchIndex) -> Int {
  self.total_docs
}

///|
/// 按文档 ID 删除一篇文档，返回是否删除成功。
pub fn SearchIndex::remove(self : SearchIndex, id : String) -> Bool {
  self.remove_if(fn(x) { x == id }) > 0
}

///|
/// 按条件删除文档，返回删除数量。删除后内部编号重建，复杂度 O(N)。
pub fn SearchIndex::remove_if(
  self : SearchIndex,
  pred : (String) -> Bool,
) -> Int {
  let positions : Array[Int] = []
  for i = 0; i < self.ids.length(); i = i + 1 {
    if pred(self.ids[i]) {
      positions.push(i)
    }
  }
  if positions.is_empty() {
    return 0
  }
  let new_ids : Array[String] = []
  let new_texts : Array[String] = []
  let new_lens : Array[Int] = []
  let mut new_sum = 0
  for i = 0; i < self.ids.length(); i = i + 1 {
    if !positions.contains(i) {
      new_ids.push(self.ids[i])
      new_texts.push(self.texts[i])
      new_lens.push(self.lens[i])
      new_sum = new_sum + self.lens[i]
    }
  }
  self.ids = new_ids
  self.texts = new_texts
  self.lens = new_lens
  self.total_docs = self.ids.length()
  self.sum_len = new_sum
  self.avg_dl = if self.total_docs > 0 {
    new_sum.to_double() / self.total_docs.to_double()
  } else {
    0.0
  }
  self.rebuild_postings()
  positions.length()
}

///|
/// 返回索引统计信息。
pub fn SearchIndex::stats(self : SearchIndex) -> IndexStats {
  {
    doc_count: self.total_docs,
    term_count: self.postings.length(),
    total_tokens: self.sum_len,
    avg_doc_len: self.avg_dl,
  }
}

///|
fn SearchIndex::rebuild_postings(self : SearchIndex) -> Unit {
  self.postings = Map([])
  for i = 0; i < self.texts.length(); i = i + 1 {
    let tokens = self.tokenizer.tokenize(self.texts[i])
    let tf : Map[String, Int] = Map([])
    for t in tokens {
      tf[t] = tf.get_or_default(t, 0) + 1
    }
    for kv in tf.iter() {
      let (term, count) = kv
      let postings = self.postings.get_or_default(term, [])
      postings.push({ doc_id: i, tf: count })
      self.postings[term] = postings
    }
  }
}

///|
fn unique_tokens(tokens : Array[String]) -> Array[String] {
  let out : Array[String] = []
  for t in tokens {
    if !out.contains(t) {
      out.push(t)
    }
  }
  out
}

///|
fn SearchIndex::expand_terms(
  self : SearchIndex,
  terms : Array[String],
) -> Array[String] {
  let out : Array[String] = []
  for t in terms {
    for tok in self.tokenizer.tokenize(t) {
      out.push(tok)
    }
  }
  out
}

///|
fn SearchIndex::doc_has_term(
  self : SearchIndex,
  doc : Int,
  term : String,
) -> Bool {
  match self.postings.get(term) {
    None => false
    Some(postings) => {
      for p in postings {
        if p.doc_id == doc {
          return true
        }
      }
      false
    }
  }
}

///|
fn SearchIndex::match_boolean(
  self : SearchIndex,
  doc : Int,
  must : Array[String],
  any : Array[String],
  not : Array[String],
) -> Bool {
  for t in must {
    if !self.doc_has_term(doc, t) {
      return false
    }
  }
  if !any.is_empty() {
    let mut ok = false
    for t in any {
      if self.doc_has_term(doc, t) {
        ok = true
        break
      }
    }
    if !ok {
      return false
    }
  }
  for t in not {
    if self.doc_has_term(doc, t) {
      return false
    }
  }
  true
}

///|
fn SearchIndex::score_doc(
  self : SearchIndex,
  query_tokens : Array[String],
  doc : Int,
) -> Double {
  let mut score = 0.0
  let dl = self.lens[doc]
  for t in query_tokens {
    match self.postings.get(t) {
      None => continue
      Some(postings) => {
        let mut tf = 0
        for p in postings {
          if p.doc_id == doc {
            tf = p.tf
            break
          }
        }
        if tf == 0 {
          continue
        }
        let n = self.total_docs
        let df = postings.length()
        let idf = @math.ln(
          1.0 + (n.to_double() - df.to_double() + 0.5) / (df.to_double() + 0.5),
        )
        let avg = if self.avg_dl > 0.0 { self.avg_dl } else { 1.0 }
        let denom = tf.to_double() +
          self.k1 * (1.0 - self.b + self.b * dl.to_double() / avg)
        score = score + idf * (tf.to_double() * (self.k1 + 1.0)) / denom
      }
    }
  }
  score
}
