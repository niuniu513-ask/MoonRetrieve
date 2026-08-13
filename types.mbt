///|
/// 文档分块结果。
pub struct Chunk {
  doc_id : String
  index : Int
  text : String
} derive(ToJson, FromJson, Eq, Debug)

///|
pub fn Chunk::new(doc_id : String, index : Int, text : String) -> Chunk {
  { doc_id, index, text }
}

///|
/// 检索结果：命中的分块/文档及其 BM25 分数。
pub struct SearchResult {
  doc_id : String
  score : Double
  text : String
} derive(ToJson, FromJson, Eq, Debug)

///|
pub fn SearchResult::new(
  doc_id : String,
  score : Double,
  text : String,
) -> SearchResult {
  { doc_id, score, text }
}

///|
/// 向量检索或混合检索的排序结果。
pub struct ScoredDoc {
  id : String
  score : Double
} derive(ToJson, FromJson, Eq, Debug)

///|
pub fn ScoredDoc::new(id : String, score : Double) -> ScoredDoc {
  { id, score }
}

///|
/// 索引统计信息。
pub struct IndexStats {
  doc_count : Int
  term_count : Int
  total_tokens : Int
  avg_doc_len : Double
} derive(ToJson, FromJson, Debug)

///|
pub fn IndexStats::new(
  doc_count : Int,
  term_count : Int,
  total_tokens : Int,
  avg_doc_len : Double,
) -> IndexStats {
  { doc_count, term_count, total_tokens, avg_doc_len }
}
