///|
/// 在文本中用 `**term**` 标记查询命中的词，返回高亮后的文本。
///
/// 长词优先、区间不重叠，避免中文单字与 bigram 同时命中时重复标记。
pub fn highlight(
  text : String,
  query : String,
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> String {
  let tokens = tokenizer.tokenize(query)
  let terms : Array[String] = []
  for t in tokens {
    if !terms.contains(t) {
      terms.push(t)
    }
  }
  terms.sort_by(fn(a, b) { b.length().compare(a.length()) })
  let ranges : Array[(Int, Int)] = []
  let mut pos = 0
  while pos < text.length() {
    let mut best : (Int, Int)? = None
    for term in terms {
      match text.sub(start=pos, end=text.length()).find(term) {
        None => continue
        Some(off) => {
          let s = pos + off
          let e = s + term.length()
          match best {
            None => best = Some((s, e))
            Some((bs, _)) => if s < bs { best = Some((s, e)) }
          }
        }
      }
    }
    match best {
      None => break
      Some((s, e)) => {
        ranges.push((s, e))
        pos = e
      }
    }
  }
  let merged : Array[(Int, Int)] = []
  for r in ranges {
    let (s, e) = r
    if merged.is_empty() {
      merged.push((s, e))
    } else {
      let (ps, pe) = merged[merged.length() - 1]
      if s == pe {
        merged[merged.length() - 1] = (ps, e)
      } else {
        merged.push((s, e))
      }
    }
  }
  let sb = StringBuilder::new()
  let mut last = 0
  for r in merged {
    let (s, e) = r
    sb.write_string(text.sub(start=last, end=s).to_owned())
    sb.write_string("**")
    sb.write_string(text.sub(start=s, end=e).to_owned())
    sb.write_string("**")
    last = e
  }
  sb.write_string(text.sub(start=last, end=text.length()).to_owned())
  sb.to_string()
}
