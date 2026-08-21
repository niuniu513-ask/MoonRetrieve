///|
/// One extracted keyword and its corpus-local frequency.
pub struct Keyword {
  term : String
  count : Int
  frequency : Double
} derive(Eq, Debug)

///|
/// Query-focused extractive summary.
pub struct TextSummary {
  text : String
  original_sentences : Int
  selected_sentences : Int
  estimated_tokens : Int
} derive(Eq, Debug)

///|
fn chars_owned(chars : Array[Char]) -> String {
  StringView::from_iter(chars.iter()).to_owned()
}

///|
fn is_sentence_end(char : Char) -> Bool {
  char == '.' ||
  char == '!' ||
  char == '?' ||
  char == '。' ||
  char == '！' ||
  char == '？' ||
  char == '\n'
}

///|
/// Split prose into non-empty sentences while retaining terminal punctuation.
pub fn split_sentences(text : String) -> Array[String] {
  let sentences : Array[String] = []
  let current : Array[Char] = []
  for char in text.iter() {
    current.push(char)
    if is_sentence_end(char) {
      let sentence = chars_owned(current).trim().to_owned()
      if !sentence.is_empty() {
        sentences.push(sentence)
      }
      current.clear()
    }
  }
  let tail = chars_owned(current).trim().to_owned()
  if !tail.is_empty() {
    sentences.push(tail)
  }
  sentences
}

///|
pub fn extract_keywords(
  text : String,
  limit? : Int = 10,
  tokenizer? : Tokenizer = Tokenizer::new(stopwords=default_stopwords()),
) -> Array[Keyword] {
  if limit <= 0 {
    return []
  }
  let tokens = tokenizer.tokenize(text)
  if tokens.is_empty() {
    return []
  }
  let counts : Map[String, Int] = Map([])
  for token in tokens {
    counts[token] = counts.get_or_default(token, 0) + 1
  }
  let keywords : Array[Keyword] = []
  for pair in counts.iter() {
    let (term, count) = pair
    keywords.push({
      term,
      count,
      frequency: count.to_double() / tokens.length().to_double(),
    })
  }
  keywords.sort_by(fn(a, b) {
    let count_order = b.count.compare(a.count)
    if count_order != 0 {
      count_order
    } else {
      a.term.compare(b.term)
    }
  })
  let out : Array[Keyword] = []
  for i = 0; i < keywords.length() && i < limit; i = i + 1 {
    out.push(keywords[i])
  }
  out
}

///|
fn summary_unique_tokens(text : String, tokenizer : Tokenizer) -> Array[String] {
  let out : Array[String] = []
  for token in tokenizer.tokenize(text) {
    if !out.contains(token) {
      out.push(token)
    }
  }
  out
}

///|
fn sentence_query_score(
  sentence : String,
  query_tokens : Array[String],
  tokenizer : Tokenizer,
) -> Int {
  let sentence_tokens = summary_unique_tokens(sentence, tokenizer)
  let mut score = 0
  for token in query_tokens {
    if sentence_tokens.contains(token) {
      score = score + 1
    }
  }
  score
}

///|
/// Select the most query-relevant sentences, then restore document order.
pub fn summarize_text(
  text : String,
  query? : String = "",
  max_sentences? : Int = 3,
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> TextSummary {
  let sentences = split_sentences(text)
  if sentences.is_empty() || max_sentences <= 0 {
    return {
      text: "",
      original_sentences: sentences.length(),
      selected_sentences: 0,
      estimated_tokens: 0,
    }
  }
  let query_tokens = summary_unique_tokens(query, tokenizer)
  let ranked : Array[(Int, Int)] = []
  for i = 0; i < sentences.length(); i = i + 1 {
    ranked.push(
      (i, sentence_query_score(sentences[i], query_tokens, tokenizer)),
    )
  }
  ranked.sort_by(fn(a, b) {
    let score_order = b.1.compare(a.1)
    if score_order != 0 {
      score_order
    } else {
      a.0.compare(b.0)
    }
  })
  let selected : Array[Int] = []
  for i = 0; i < ranked.length() && i < max_sentences; i = i + 1 {
    selected.push(ranked[i].0)
  }
  selected.sort()
  let builder = StringBuilder::new()
  for i = 0; i < selected.length(); i = i + 1 {
    if i > 0 {
      builder.write_string(" ")
    }
    builder.write_string(sentences[selected[i]])
  }
  let summary = builder.to_string()
  {
    text: summary,
    original_sentences: sentences.length(),
    selected_sentences: selected.length(),
    estimated_tokens: tokenizer.estimate_tokens(summary),
  }
}

///|
fn first_term_position(text : String, terms : Array[String]) -> Int? {
  let mut best : Int? = None
  for term in terms {
    match text.find(term) {
      Some(position) =>
        match best {
          Some(current) => if position < current { best = Some(position) }
          None => best = Some(position)
        }
      None => ()
    }
  }
  best
}

///|
fn ascii_lower_text(text : String) -> String {
  let chars : Array[Char] = []
  for char in text.iter() {
    let value = char.to_int()
    if value >= 65 && value <= 90 {
      chars.push((value + 32).unsafe_to_char())
    } else {
      chars.push(char)
    }
  }
  chars_owned(chars)
}

///|
/// Create a bounded result snippet centered near the first query match.
pub fn result_snippet(
  text : String,
  query : String,
  max_chars? : Int = 160,
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> String {
  if max_chars <= 0 || text.is_empty() {
    return ""
  }
  if text.length() <= max_chars {
    return text
  }
  let terms = summary_unique_tokens(query, tokenizer)
  let position = first_term_position(ascii_lower_text(text), terms).unwrap_or(0)
  let half = max_chars / 2
  let mut start = if position > half { position - half } else { 0 }
  if start + max_chars > text.length() {
    start = text.length() - max_chars
  }
  let end = start + max_chars
  let builder = StringBuilder::new()
  if start > 0 {
    builder.write_string("...")
  }
  builder.write_string(text.sub(start~, end~).to_owned())
  if end < text.length() {
    builder.write_string("...")
  }
  builder.to_string()
}

///|
pub fn snippets_for_results(
  results : Array[SearchResult],
  query : String,
  max_chars? : Int = 160,
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> Array[SearchResult] {
  let out : Array[SearchResult] = []
  for result in results {
    out.push({
      doc_id: result.doc_id,
      score: result.score,
      text: result_snippet(result.text, query, max_chars~, tokenizer~),
    })
  }
  out
}
