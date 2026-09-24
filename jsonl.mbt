///|
/// Parse JSONL documents with `id` or `_id`, optional `title`, and `text`.
/// The complete batch is validated before the caller changes its index.
pub fn parse_document_jsonl(
  input : String,
) -> Result[Array[(String, String)], String] {
  let documents : Array[(String, String)] = []
  let seen : Map[String, Bool] = Map([])
  let mut line_number = 0
  for raw_line in input.split("\n") {
    line_number = line_number + 1
    let line = raw_line.trim().to_owned()
    if line == "" {
      continue
    }
    let parsed = @json.parse(line) catch {
      _ => return Err("line \{line_number}: invalid JSON")
    }
    guard parsed is Object(fields) else {
      return Err("line \{line_number}: expected an object")
    }
    let id = match fields.get("id") {
      Some(String(value)) => value
      _ =>
        match fields.get("_id") {
          Some(String(value)) => value
          _ => return Err("line \{line_number}: missing id or _id")
        }
    }
    if id == "" {
      return Err("line \{line_number}: empty document ID")
    }
    if seen.contains(id) {
      return Err("line \{line_number}: duplicate document ID \{id}")
    }
    let body = match fields.get("text") {
      Some(String(value)) => value
      _ => return Err("line \{line_number}: missing text")
    }
    let title = match fields.get("title") {
      Some(String(value)) => value
      _ => ""
    }
    let content = if title == "" { body } else { title + "\n\n" + body }
    seen[id] = true
    documents.push((id, content))
  }
  if documents.is_empty() {
    Err("no documents in JSONL input")
  } else {
    Ok(documents)
  }
}
