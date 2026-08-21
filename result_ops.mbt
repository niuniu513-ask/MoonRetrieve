///|
/// Aggregated result information for chunks from the same source document.
pub struct ResultGroup {
  doc_id : String
  best_score : Double
  total_score : Double
  chunk_count : Int
  chunks : Array[SearchResult]
} derive(Debug)

///|
pub fn source_doc_id(chunk_id : String) -> String {
  match chunk_id.find("#") {
    Some(index) => chunk_id.sub(start=0, end=index).to_owned()
    None => chunk_id
  }
}

///|
fn clone_result(result : SearchResult, score : Double) -> SearchResult {
  { doc_id: result.doc_id, score, text: result.text }
}

///|
pub fn sort_results(results : Array[SearchResult]) -> Array[SearchResult] {
  let out = results.copy()
  out.sort_by(fn(a, b) {
    let score_order = b.score.compare(a.score)
    if score_order != 0 {
      score_order
    } else {
      a.doc_id.compare(b.doc_id)
    }
  })
  out
}

///|
/// Min-max normalize scores into [0, 1]. Equal nonzero scores become 1.
pub fn normalize_result_scores(
  results : Array[SearchResult],
) -> Array[SearchResult] {
  if results.is_empty() {
    return []
  }
  let mut minimum = results[0].score
  let mut maximum = results[0].score
  for result in results {
    if result.score < minimum {
      minimum = result.score
    }
    if result.score > maximum {
      maximum = result.score
    }
  }
  let out : Array[SearchResult] = []
  if maximum == minimum {
    let value = if maximum == 0.0 { 0.0 } else { 1.0 }
    for result in results {
      out.push(clone_result(result, value))
    }
    return out
  }
  for result in results {
    out.push(
      clone_result(result, (result.score - minimum) / (maximum - minimum)),
    )
  }
  out
}

///|
pub fn filter_results(
  results : Array[SearchResult],
  min_score? : Double = 0.0,
  max_results? : Int = 10,
) -> Array[SearchResult] {
  if max_results <= 0 {
    return []
  }
  let out : Array[SearchResult] = []
  for result in sort_results(results) {
    if result.score >= min_score && out.length() < max_results {
      out.push(result)
    }
  }
  out
}

///|
pub fn paginate_results(
  results : Array[SearchResult],
  offset? : Int = 0,
  limit? : Int = 10,
) -> Array[SearchResult] {
  if limit <= 0 || offset >= results.length() {
    return []
  }
  let start = if offset < 0 { 0 } else { offset }
  let out : Array[SearchResult] = []
  for i = start; i < results.length() && out.length() < limit; i = i + 1 {
    out.push(results[i])
  }
  out
}

///|
/// Keep only the highest-scored chunk for each source document.
pub fn deduplicate_by_source(
  results : Array[SearchResult],
  limit? : Int = 10,
) -> Array[SearchResult] {
  if limit <= 0 {
    return []
  }
  let seen : Array[String] = []
  let out : Array[SearchResult] = []
  for result in sort_results(results) {
    let source = source_doc_id(result.doc_id)
    if !seen.contains(source) {
      seen.push(source)
      out.push(result)
      if out.length() >= limit {
        break
      }
    }
  }
  out
}

///|
pub fn group_results_by_source(
  results : Array[SearchResult],
) -> Array[ResultGroup] {
  let sources : Array[String] = []
  let chunks : Map[String, Array[SearchResult]] = Map([])
  for result in sort_results(results) {
    let source = source_doc_id(result.doc_id)
    if !sources.contains(source) {
      sources.push(source)
      chunks[source] = []
    }
    chunks[source].push(result)
  }
  let groups : Array[ResultGroup] = []
  for source in sources {
    let source_chunks = chunks[source]
    let mut total = 0.0
    for chunk in source_chunks {
      total = total + chunk.score
    }
    groups.push({
      doc_id: source,
      best_score: if source_chunks.is_empty() {
        0.0
      } else {
        source_chunks[0].score
      },
      total_score: total,
      chunk_count: source_chunks.length(),
      chunks: source_chunks,
    })
  }
  groups.sort_by(fn(a, b) {
    let score_order = b.best_score.compare(a.best_score)
    if score_order != 0 {
      score_order
    } else {
      a.doc_id.compare(b.doc_id)
    }
  })
  groups
}

///|
/// Weighted score fusion. Duplicate IDs within one list keep their highest
/// contribution; text comes from the highest-scored occurrence.
pub fn weighted_fuse_results(
  left : Array[SearchResult],
  right : Array[SearchResult],
  left_weight? : Double = 0.5,
  right_weight? : Double = 0.5,
  limit? : Int = 10,
) -> Array[SearchResult] {
  if limit <= 0 {
    return []
  }
  let scores : Map[String, Double] = Map([])
  let texts : Map[String, String] = Map([])
  let best_original : Map[String, Double] = Map([])
  for result in left {
    let contribution = result.score * left_weight
    if contribution > scores.get_or_default(result.doc_id, 0.0) {
      scores[result.doc_id] = contribution
    }
    if result.score > best_original.get_or_default(result.doc_id, -1.0) {
      best_original[result.doc_id] = result.score
      texts[result.doc_id] = result.text
    }
  }
  for result in right {
    scores[result.doc_id] = scores.get_or_default(result.doc_id, 0.0) +
      result.score * right_weight
    if result.score > best_original.get_or_default(result.doc_id, -1.0) {
      best_original[result.doc_id] = result.score
      texts[result.doc_id] = result.text
    }
  }
  let out : Array[SearchResult] = []
  for pair in scores.iter() {
    let (id, score) = pair
    out.push({ doc_id: id, score, text: texts.get_or_default(id, "") })
  }
  paginate_results(sort_results(out), limit~)
}

///|
fn max_text_similarity(
  candidate : SearchResult,
  selected : Array[SearchResult],
  tokenizer : Tokenizer,
) -> Double {
  let mut maximum = 0.0
  for result in selected {
    let similarity = token_jaccard(candidate.text, result.text, tokenizer~)
    if similarity > maximum {
      maximum = similarity
    }
  }
  maximum
}

///|
/// Greedy diversity filter. Results above `similarity_threshold` with an
/// already-selected result are skipped.
pub fn diversify_results(
  results : Array[SearchResult],
  similarity_threshold? : Double = 0.8,
  limit? : Int = 10,
  tokenizer? : Tokenizer = Tokenizer::new(),
) -> Array[SearchResult] {
  if limit <= 0 {
    return []
  }
  let out : Array[SearchResult] = []
  for candidate in sort_results(results) {
    if out.is_empty() ||
      max_text_similarity(candidate, out, tokenizer) < similarity_threshold {
      out.push(candidate)
      if out.length() >= limit {
        break
      }
    }
  }
  out
}

///|
pub fn result_score_range(results : Array[SearchResult]) -> (Double, Double)? {
  if results.is_empty() {
    return None
  }
  let mut minimum = results[0].score
  let mut maximum = results[0].score
  for result in results {
    if result.score < minimum {
      minimum = result.score
    }
    if result.score > maximum {
      maximum = result.score
    }
  }
  Some((minimum, maximum))
}
