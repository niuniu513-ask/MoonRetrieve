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
  { chunker, index }
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
