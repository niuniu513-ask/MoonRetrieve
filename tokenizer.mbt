///|
/// 分词器配置。
///
/// 默认行为：
/// - 英文/数字按字母数字串切分并转小写，过滤长度小于 `min_token_len` 的词
/// - 中日韩文字按单字 + 相邻二字 bigram 切分
/// - 可配置停用词与英文词干化
pub struct Tokenizer {
  min_token_len : Int
  bigram_cjk : Bool
  stem_english : Bool
  stopwords : Array[String]
} derive(ToJson, FromJson)

///|
pub fn Tokenizer::new(
  min_token_len? : Int = 2,
  bigram_cjk? : Bool = true,
  stem_english? : Bool = false,
  stopwords? : Array[String] = [],
) -> Tokenizer {
  { min_token_len, bigram_cjk, stem_english, stopwords }
}

///|
/// 常用中文停用词。
pub fn default_stopwords() -> Array[String] {
  [
    "的", "了", "和", "是", "在", "与", "及", "或", "等", "之", "一个",
    "我们", "你们", "他们", "这个", "那个", "可以", "进行", "以及",
    "the", "a", "an", "is", "are", "was", "were", "to", "of", "in", "on", "for",
    "and", "or", "with", "this", "that", "it",
  ]
}

///|
/// 对文本分词，返回词条数组。
pub fn Tokenizer::tokenize(self : Tokenizer, text : String) -> Array[String] {
  let out : Array[String] = []
  let ascii : Array[Char] = []
  let mut last_cjk : Char? = None
  for c in text.iter() {
    if is_ascii_alnum(c) {
      last_cjk = None
      ascii.push(ascii_lower(c))
    } else if is_cjk(c) {
      self.flush_ascii(out, ascii)
      ascii.clear()
      let unigram = StringView::from_iter([c].iter()).to_owned()
      // 中文单字不卡最小长度，保证单字查询可用；仅过滤停用词。
      if !self.stopwords.contains(unigram) {
        out.push(unigram)
      }
      if self.bigram_cjk {
        match last_cjk {
          Some(prev) => {
            let bigram = StringView::from_iter([prev, c].iter()).to_owned()
            if self.keep(bigram) {
              out.push(bigram)
            }
          }
          None => ()
        }
      }
      last_cjk = Some(c)
    } else {
      self.flush_ascii(out, ascii)
      ascii.clear()
      last_cjk = None
    }
  }
  self.flush_ascii(out, ascii)
  out
}

///|
/// 估算文本的 token 数（按当前分词结果计数，供上下文预算使用）。
pub fn Tokenizer::estimate_tokens(self : Tokenizer, text : String) -> Int {
  self.tokenize(text).length()
}

///|
fn Tokenizer::flush_ascii(
  self : Tokenizer,
  out : Array[String],
  chars : Array[Char],
) -> Unit {
  if chars.is_empty() {
    return
  }
  let word = StringView::from_iter(chars.iter()).to_owned()
  let result = if self.stem_english { stem_word(word) } else { word }
  if self.keep(result) {
    out.push(result)
  }
}

///|
fn Tokenizer::keep(self : Tokenizer, token : String) -> Bool {
  token.length() >= self.min_token_len && !self.stopwords.contains(token)
}

///|
fn is_ascii_alnum(c : Char) -> Bool {
  let n = c.to_int()
  (n >= 48 && n <= 57) || (n >= 65 && n <= 90) || (n >= 97 && n <= 122)
}

///|
fn is_cjk(c : Char) -> Bool {
  let n = c.to_int()
  (n >= 0x3400 && n <= 0x4DBF) ||
  (n >= 0x4E00 && n <= 0x9FFF) ||
  (n >= 0xF900 && n <= 0xFAFF) ||
  (n >= 0x3040 && n <= 0x30FF)
}

///|
fn ascii_lower(c : Char) -> Char {
  let n = c.to_int()
  if n >= 65 && n <= 90 {
    (n + 32).unsafe_to_char()
  } else {
    c
  }
}

///|
fn stem_word(w : String) -> String {
  let n = w.length()
  if n > 5 && w.has_suffix("ing") {
    w.sub(start=0, end=n - 3).to_owned()
  } else if n > 4 && w.has_suffix("ed") {
    w.sub(start=0, end=n - 2).to_owned()
  } else if n > 4 && w.has_suffix("ly") {
    w.sub(start=0, end=n - 2).to_owned()
  } else if n > 4 && w.has_suffix("es") {
    w.sub(start=0, end=n - 2).to_owned()
  } else if n > 3 && w.has_suffix("s") && !w.has_suffix("ss") {
    w.sub(start=0, end=n - 1).to_owned()
  } else {
    w
  }
}
