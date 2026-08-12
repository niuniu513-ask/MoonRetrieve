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
  ids : Array[String]
  texts : Array[String]
  lens : Array[Int]
  postings : Map[String, Array[Posting]]
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
  let unique : Array[String] = []
  for t in q_tokens {
    if !unique.contains(t) {
      unique.push(t)
    }
  }
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
