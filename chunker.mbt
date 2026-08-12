///|
/// 文档分块器：按段落切分，块之间保留重叠内容。
pub struct Chunker {
  max_chars : Int
  overlap : Int
} derive(ToJson, FromJson)

///|
pub fn Chunker::new(max_chars? : Int = 800, overlap? : Int = 80) -> Chunker {
  let m = if max_chars < 1 { 1 } else { max_chars }
  let o = if overlap < 0 { 0 } else if overlap >= m { m / 2 } else { overlap }
  { max_chars: m, overlap: o }
}

///|
/// 将文档切成带编号的分块。
pub fn Chunker::chunk(
  self : Chunker,
  doc_id : String,
  text : String,
) -> Array[Chunk] {
  let paragraphs : Array[String] = []
  for line in text.split("\n") {
    let t = line.trim().to_owned()
    if !t.is_empty() {
      paragraphs.push(t)
    }
  }
  let chunks : Array[Chunk] = []
  let current : Array[String] = []
  let mut current_len = 0
  let mut index = 0
  for para in paragraphs {
    if para.length() >= self.max_chars {
      if !current.is_empty() {
        index = flush_chunk(chunks, doc_id, current, index)
        current.clear()
        current_len = 0
      }
      for piece in split_long(para, self.max_chars) {
        chunks.push({ doc_id, index, text: piece })
        index = index + 1
      }
      continue
    }
    if current_len + para.length() + 1 > self.max_chars && !current.is_empty() {
      let last_text = current.join("\n")
      index = flush_chunk(chunks, doc_id, current, index)
      current.clear()
      if self.overlap > 0 && last_text.length() > self.overlap {
        current.push(
          last_text
          .sub(start=last_text.length() - self.overlap, end=last_text.length())
          .to_owned(),
        )
        current_len = self.overlap
      } else {
        current_len = 0
      }
    }
    current.push(para)
    current_len = current_len + para.length() + 1
  }
  if !current.is_empty() {
    ignore(flush_chunk(chunks, doc_id, current, index))
  }
  chunks
}

///|
fn flush_chunk(
  chunks : Array[Chunk],
  doc_id : String,
  lines : Array[String],
  index : Int,
) -> Int {
  chunks.push({ doc_id, index, text: lines.join("\n") })
  index + 1
}

///|
fn split_long(text : String, max : Int) -> Array[String] {
  let out : Array[String] = []
  let chars = text.to_array()
  let mut i = 0
  while i < chars.length() {
    let end = if i + max < chars.length() { i + max } else { chars.length() }
    out.push(StringView::from_iter(chars.view(start=i, end~).iter()).to_owned())
    i = end
  }
  out
}
