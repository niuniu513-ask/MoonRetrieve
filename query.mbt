///|
/// One parsed query clause.
pub struct QueryClause {
  value : String
  field : String?
  required : Bool
  excluded : Bool
  phrase : Bool
  prefix : Bool
} derive(Eq, Debug)

///|
/// Parsed query language representation.
pub struct QueryPlan {
  original : String
  clauses : Array[QueryClause]
} derive(Eq, Debug)

///|
priv struct RawClause {
  value : String
  phrase : Bool
}

///|
fn chars_to_string(chars : Array[Char]) -> String {
  StringView::from_iter(chars.iter()).to_owned()
}

///|
fn raw_query_clauses(query : String) -> Result[Array[RawClause], String] {
  let raw : Array[RawClause] = []
  let current : Array[Char] = []
  let mut quoted = false
  let mut clause_phrase = false
  for char in query.iter() {
    if char == '"' {
      if quoted {
        quoted = false
      } else {
        let modifier_only = current.length() == 1 &&
          (current[0] == '+' || current[0] == '-')
        if !current.is_empty() && !modifier_only {
          return Err("quote must start at a clause boundary")
        }
        quoted = true
        clause_phrase = true
      }
    } else if (char == ' ' || char == '\t' || char == '\n') && !quoted {
      if !current.is_empty() {
        raw.push({ value: chars_to_string(current), phrase: clause_phrase })
        current.clear()
        clause_phrase = false
      }
    } else {
      current.push(char)
    }
  }
  if quoted {
    return Err("unterminated quoted phrase")
  }
  if !current.is_empty() {
    raw.push({ value: chars_to_string(current), phrase: clause_phrase })
  }
  Ok(raw)
}

///|
fn parse_field(value : String) -> (String?, String) {
  match value.find(":") {
    None => (None, value)
    Some(index) => {
      let field = value.sub(start=0, end=index).to_owned()
      let rest = value.sub(start=index + 1, end=value.length()).to_owned()
      if field.is_empty() || rest.is_empty() {
        (None, value)
      } else {
        (Some(field), rest)
      }
    }
  }
}

///|
fn parse_raw_clause(raw : RawClause) -> Result[QueryClause, String] {
  let mut value = raw.value
  let mut required = false
  let mut excluded = false
  if value.has_prefix("+") {
    required = true
    value = value.sub(start=1, end=value.length()).to_owned()
  } else if value.has_prefix("-") {
    excluded = true
    value = value.sub(start=1, end=value.length()).to_owned()
  }
  if value.is_empty() {
    return Err("query modifier requires a value")
  }
  let (field, field_value) = parse_field(value)
  value = field_value
  let mut prefix = false
  if value.has_suffix("*") {
    prefix = true
    value = value.sub(start=0, end=value.length() - 1).to_owned()
  }
  if value.is_empty() {
    return Err("prefix operator requires a value")
  }
  if value.contains("*") {
    return Err("wildcard is supported only at the end of a clause")
  }
  Ok({ value, field, required, excluded, phrase: raw.phrase, prefix })
}

///|
/// Parse a compact query language:
/// - `+term`: required term
/// - `-term`: excluded term
/// - `"exact phrase"`: phrase clause
/// - `prefix*`: prefix clause
/// - `title:moonbit`: field-qualified clause
pub fn parse_query(query : String) -> Result[QueryPlan, String] {
  let trimmed = query.trim().to_owned()
  if trimmed.is_empty() {
    return Err("query must not be empty")
  }
  let clauses : Array[QueryClause] = []
  match raw_query_clauses(trimmed) {
    Err(message) => Err(message)
    Ok(raw_clauses) => {
      for raw in raw_clauses {
        match parse_raw_clause(raw) {
          Ok(clause) => clauses.push(clause)
          Err(message) => return Err(message)
        }
      }
      if clauses.is_empty() {
        Err("query must contain at least one clause")
      } else {
        Ok({ original: trimmed, clauses })
      }
    }
  }
}

///|
pub fn QueryPlan::positive_values(self : QueryPlan) -> Array[String] {
  let out : Array[String] = []
  for clause in self.clauses {
    if !clause.excluded && !out.contains(clause.value) {
      out.push(clause.value)
    }
  }
  out
}

///|
pub fn QueryPlan::excluded_values(self : QueryPlan) -> Array[String] {
  let out : Array[String] = []
  for clause in self.clauses {
    if clause.excluded && !out.contains(clause.value) {
      out.push(clause.value)
    }
  }
  out
}

///|
pub fn QueryPlan::required_values(self : QueryPlan) -> Array[String] {
  let out : Array[String] = []
  for clause in self.clauses {
    if clause.required && !clause.excluded && !out.contains(clause.value) {
      out.push(clause.value)
    }
  }
  out
}

///|
pub fn QueryPlan::search_text(self : QueryPlan) -> String {
  let builder = StringBuilder::new()
  let mut first = true
  for value in self.positive_values() {
    if !first {
      builder.write_string(" ")
    }
    builder.write_string(value)
    first = false
  }
  builder.to_string()
}

///|
pub fn QueryPlan::has_field(self : QueryPlan, field : String) -> Bool {
  for clause in self.clauses {
    if clause.field == Some(field) {
      return true
    }
  }
  false
}

///|
fn clause_matches(
  clause : QueryClause,
  text : String,
  tokenizer : Tokenizer,
) -> Bool {
  if clause.phrase {
    return text.contains(clause.value)
  }
  let tokens = tokenizer.tokenize(text)
  let query_tokens = tokenizer.tokenize(clause.value)
  if clause.prefix {
    for token in tokens {
      for query_token in query_tokens {
        if token.has_prefix(query_token) {
          return true
        }
      }
    }
    return false
  }
  for query_token in query_tokens {
    if tokens.contains(query_token) {
      return true
    }
  }
  false
}

///|
/// Test required and excluded clauses against plain text. Optional clauses do
/// not filter the document; they are used for ranking.
pub fn QueryPlan::matches(
  self : QueryPlan,
  text : String,
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> Bool {
  for clause in self.clauses {
    let matched = clause_matches(clause, text, tokenizer)
    if clause.excluded && matched {
      return false
    }
    if clause.required && !matched {
      return false
    }
  }
  true
}

///|
pub fn filter_with_query_plan(
  results : Array[SearchResult],
  plan : QueryPlan,
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> Array[SearchResult] {
  let out : Array[SearchResult] = []
  for result in results {
    if plan.matches(result.text, tokenizer~) {
      out.push(result)
    }
  }
  out
}

///|
pub fn format_query_plan(plan : QueryPlan) -> String {
  let builder = StringBuilder::new()
  for i = 0; i < plan.clauses.length(); i = i + 1 {
    if i > 0 {
      builder.write_string(" ")
    }
    let clause = plan.clauses[i]
    if clause.required {
      builder.write_string("+")
    } else if clause.excluded {
      builder.write_string("-")
    }
    match clause.field {
      Some(field) => {
        builder.write_string(field)
        builder.write_string(":")
      }
      None => ()
    }
    if clause.phrase {
      builder.write_string("\"")
    }
    builder.write_string(clause.value)
    if clause.phrase {
      builder.write_string("\"")
    }
    if clause.prefix {
      builder.write_string("*")
    }
  }
  builder.to_string()
}
