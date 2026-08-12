///|
/// 稠密向量索引（暴力检索，适合中小规模本地 RAG）。
pub struct VectorIndex {
  items : Array[ScoredDoc]
  vectors : Array[Array[Double]]
} derive(ToJson, FromJson)

///|
pub fn VectorIndex::new() -> VectorIndex {
  { items: [], vectors: [] }
}

///|
/// 添加一个带向量的文档/分块，返回更新后的索引。
pub fn VectorIndex::add(
  self : VectorIndex,
  id : String,
  vector : Array[Double],
) -> Unit {
  self.items.push({ id, score: 0.0 })
  self.vectors.push(vector)
}

///|
/// 按余弦相似度检索 Top-K。
pub fn VectorIndex::search(
  self : VectorIndex,
  query : Array[Double],
  top_k? : Int = 10,
) -> Array[ScoredDoc] {
  let scored : Array[(String, Double)] = []
  for i = 0; i < self.items.length(); i = i + 1 {
    scored.push((self.items[i].id, cosine(query, self.vectors[i])))
  }
  scored.sort_by(fn(a, b) {
    let cmp = b.1.compare(a.1)
    if cmp != 0 {
      cmp
    } else {
      a.0.compare(b.0)
    }
  })
  let out : Array[ScoredDoc] = []
  for i = 0; i < scored.length() && i < top_k; i = i + 1 {
    let (id, score) = scored[i]
    if score > 0.0 {
      out.push({ id, score })
    }
  }
  out
}

///|
/// 向量数量。
pub fn VectorIndex::count(self : VectorIndex) -> Int {
  self.items.length()
}

///|
/// 计算两个向量的余弦相似度。维度不一致或零向量返回 0。
pub fn cosine(a : Array[Double], b : Array[Double]) -> Double {
  if a.length() != b.length() || a.is_empty() {
    return 0.0
  }
  let mut dot = 0.0
  let mut na = 0.0
  let mut nb = 0.0
  for i = 0; i < a.length(); i = i + 1 {
    dot = dot + a[i] * b[i]
    na = na + a[i] * a[i]
    nb = nb + b[i] * b[i]
  }
  if na == 0.0 || nb == 0.0 {
    0.0
  } else {
    dot / (@math.pow(na, 0.5) * @math.pow(nb, 0.5))
  }
}

///|
/// 用 RRF（Reciprocal Rank Fusion）融合两路检索结果。
pub fn rrf_fuse(
  a : Array[ScoredDoc],
  b : Array[ScoredDoc],
  k? : Int = 60,
  top_k? : Int = 10,
) -> Array[ScoredDoc] {
  let scores : Map[String, Double] = Map([])
  let mut rank = 1
  for item in a {
    scores[item.id] = scores.get_or_default(item.id, 0.0) +
      1.0 / (k.to_double() + rank.to_double())
    rank = rank + 1
  }
  rank = 1
  for item in b {
    scores[item.id] = scores.get_or_default(item.id, 0.0) +
      1.0 / (k.to_double() + rank.to_double())
    rank = rank + 1
  }
  let arr : Array[(String, Double)] = []
  for kv in scores.iter() {
    arr.push(kv)
  }
  arr.sort_by(fn(a, b) {
    let cmp = b.1.compare(a.1)
    if cmp != 0 {
      cmp
    } else {
      a.0.compare(b.0)
    }
  })
  let out : Array[ScoredDoc] = []
  for i = 0; i < arr.length() && i < top_k; i = i + 1 {
    let (id, score) = arr[i]
    out.push({ id, score })
  }
  out
}
