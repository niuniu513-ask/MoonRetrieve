///|
/// One spelling or completion suggestion.
pub struct QuerySuggestion {
  value : String
  distance : Int
  similarity : Double
} derive(Eq, Debug)

///|
fn string_chars(value : String) -> Array[Char] {
  let out : Array[Char] = []
  for char in value.iter() {
    out.push(char)
  }
  out
}

///|
fn int_min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn int_max(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn min_three(a : Int, b : Int, c : Int) -> Int {
  int_min(a, int_min(b, c))
}

///|
fn integer_row(length : Int) -> Array[Int] {
  let row : Array[Int] = []
  for i = 0; i < length; i = i + 1 {
    row.push(0)
  }
  row
}

///|
/// Unicode-aware Levenshtein edit distance.
pub fn edit_distance(left : String, right : String) -> Int {
  if left == right {
    return 0
  }
  let a = string_chars(left)
  let b = string_chars(right)
  if a.is_empty() {
    return b.length()
  }
  if b.is_empty() {
    return a.length()
  }
  let mut previous = integer_row(b.length() + 1)
  for j = 0; j <= b.length(); j = j + 1 {
    previous[j] = j
  }
  for i = 1; i <= a.length(); i = i + 1 {
    let current = integer_row(b.length() + 1)
    current[0] = i
    for j = 1; j <= b.length(); j = j + 1 {
      let cost = if a[i - 1] == b[j - 1] { 0 } else { 1 }
      current[j] = min_three(
        previous[j] + 1,
        current[j - 1] + 1,
        previous[j - 1] + cost,
      )
    }
    previous = current
  }
  previous[b.length()]
}

///|
/// Optimal-string-alignment distance, treating one adjacent transposition as
/// one edit. This is useful for common typing errors such as `serach`.
pub fn transposition_distance(left : String, right : String) -> Int {
  let a = string_chars(left)
  let b = string_chars(right)
  let rows : Array[Array[Int]] = []
  for i = 0; i <= a.length(); i = i + 1 {
    let row = integer_row(b.length() + 1)
    row[0] = i
    rows.push(row)
  }
  for j = 0; j <= b.length(); j = j + 1 {
    rows[0][j] = j
  }
  for i = 1; i <= a.length(); i = i + 1 {
    for j = 1; j <= b.length(); j = j + 1 {
      let cost = if a[i - 1] == b[j - 1] { 0 } else { 1 }
      rows[i][j] = min_three(
        rows[i - 1][j] + 1,
        rows[i][j - 1] + 1,
        rows[i - 1][j - 1] + cost,
      )
      if i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1] {
        rows[i][j] = int_min(rows[i][j], rows[i - 2][j - 2] + 1)
      }
    }
  }
  rows[a.length()][b.length()]
}

///|
pub fn edit_similarity(left : String, right : String) -> Double {
  let length = int_max(
    string_chars(left).length(),
    string_chars(right).length(),
  )
  if length == 0 {
    return 1.0
  }
  1.0 - edit_distance(left, right).to_double() / length.to_double()
}

///|
fn normalize_vocabulary(vocabulary : Array[String]) -> Array[String] {
  let out : Array[String] = []
  for value in vocabulary {
    let word = value.trim().to_owned()
    if !word.is_empty() && !out.contains(word) {
      out.push(word)
    }
  }
  out
}

///|
fn distance_similarity(left : String, right : String, distance : Int) -> Double {
  let length = int_max(
    string_chars(left).length(),
    string_chars(right).length(),
  )
  if length == 0 {
    1.0
  } else {
    1.0 - distance.to_double() / length.to_double()
  }
}

///|
/// Suggest vocabulary entries within `max_distance`, ranked by distance,
/// similarity, then lexical order for deterministic output.
pub fn suggest_terms(
  query : String,
  vocabulary : Array[String],
  max_distance? : Int = 2,
  limit? : Int = 5,
) -> Array[QuerySuggestion] {
  if query.is_empty() || max_distance < 0 || limit <= 0 {
    return []
  }
  let suggestions : Array[QuerySuggestion] = []
  for candidate in normalize_vocabulary(vocabulary) {
    let distance = transposition_distance(query, candidate)
    if distance <= max_distance {
      suggestions.push({
        value: candidate,
        distance,
        similarity: distance_similarity(query, candidate, distance),
      })
    }
  }
  suggestions.sort_by(fn(a, b) {
    let distance_order = a.distance.compare(b.distance)
    if distance_order != 0 {
      distance_order
    } else {
      let similarity_order = b.similarity.compare(a.similarity)
      if similarity_order != 0 {
        similarity_order
      } else {
        a.value.compare(b.value)
      }
    }
  })
  let out : Array[QuerySuggestion] = []
  for i = 0; i < suggestions.length() && i < limit; i = i + 1 {
    out.push(suggestions[i])
  }
  out
}

///|
/// Replace each whitespace-delimited query word with its nearest vocabulary
/// entry when the distance threshold is met.
pub fn correct_query(
  query : String,
  vocabulary : Array[String],
  max_distance? : Int = 2,
) -> String {
  let builder = StringBuilder::new()
  let mut first = true
  for part in query.split(" ") {
    let word = part.trim().to_owned()
    if word.is_empty() {
      continue
    }
    if !first {
      builder.write_string(" ")
    }
    let suggestions = suggest_terms(word, vocabulary, max_distance~, limit=1)
    if suggestions.is_empty() {
      builder.write_string(word)
    } else {
      builder.write_string(suggestions[0].value)
    }
    first = false
  }
  builder.to_string()
}

///|
/// Prefix completions ranked by shortest completion and lexical order.
pub fn complete_prefix(
  prefix : String,
  vocabulary : Array[String],
  limit? : Int = 10,
) -> Array[String] {
  if prefix.is_empty() || limit <= 0 {
    return []
  }
  let matches : Array[String] = []
  for word in normalize_vocabulary(vocabulary) {
    if word.has_prefix(prefix) {
      matches.push(word)
    }
  }
  matches.sort_by(fn(a, b) {
    let length_order = a.length().compare(b.length())
    if length_order != 0 {
      length_order
    } else {
      a.compare(b)
    }
  })
  let out : Array[String] = []
  for i = 0; i < matches.length() && i < limit; i = i + 1 {
    out.push(matches[i])
  }
  out
}

///|
fn unique_tokens_for(text : String, tokenizer : Tokenizer) -> Array[String] {
  let out : Array[String] = []
  for token in tokenizer.tokenize(text) {
    if !out.contains(token) {
      out.push(token)
    }
  }
  out
}

///|
pub fn token_jaccard(
  left : String,
  right : String,
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> Double {
  let a = unique_tokens_for(left, tokenizer)
  let b = unique_tokens_for(right, tokenizer)
  if a.is_empty() && b.is_empty() {
    return 1.0
  }
  let union : Array[String] = []
  for token in a {
    if !union.contains(token) {
      union.push(token)
    }
  }
  for token in b {
    if !union.contains(token) {
      union.push(token)
    }
  }
  let mut intersection = 0
  for token in union {
    if a.contains(token) && b.contains(token) {
      intersection = intersection + 1
    }
  }
  intersection.to_double() / union.length().to_double()
}

///|
pub fn shared_prefix_length(left : String, right : String) -> Int {
  let a = string_chars(left)
  let b = string_chars(right)
  let limit = int_min(a.length(), b.length())
  let mut count = 0
  while count < limit && a[count] == b[count] {
    count = count + 1
  }
  count
}
