///|
/// Metrics for one ranked retrieval result list.
pub struct RetrievalMetrics {
  cutoff : Int
  retrieved : Int
  relevant : Int
  relevant_retrieved : Int
  precision : Double
  recall : Double
  f1 : Double
  hit_rate : Double
  reciprocal_rank : Double
  average_precision : Double
  r_precision : Double
} derive(Debug)

///|
/// Aggregate metrics over multiple queries.
pub struct EvaluationSummary {
  query_count : Int
  mean_precision : Double
  mean_recall : Double
  mean_f1 : Double
  mean_reciprocal_rank : Double
  mean_average_precision : Double
  hit_rate : Double
} derive(Debug)

///|
pub fn result_ids(results : Array[SearchResult]) -> Array[String] {
  let ids : Array[String] = []
  for result in results {
    ids.push(result.doc_id)
  }
  ids
}

///|
fn unique_strings(values : Array[String]) -> Array[String] {
  let out : Array[String] = []
  for value in values {
    if !out.contains(value) {
      out.push(value)
    }
  }
  out
}

///|
fn effective_cutoff(ranked : Array[String], cutoff : Int) -> Int {
  if cutoff <= 0 {
    0
  } else if cutoff < ranked.length() {
    cutoff
  } else {
    ranked.length()
  }
}

///|
fn count_relevant_at(
  ranked : Array[String],
  relevant : Array[String],
  cutoff : Int,
) -> Int {
  let limit = effective_cutoff(ranked, cutoff)
  let seen : Array[String] = []
  let mut count = 0
  for i = 0; i < limit; i = i + 1 {
    let id = ranked[i]
    if !seen.contains(id) {
      seen.push(id)
      if relevant.contains(id) {
        count = count + 1
      }
    }
  }
  count
}

///|
pub fn precision_at(
  ranked : Array[String],
  relevant : Array[String],
  cutoff : Int,
) -> Double {
  let limit = effective_cutoff(ranked, cutoff)
  if limit == 0 {
    return 0.0
  }
  count_relevant_at(ranked, relevant, cutoff).to_double() / limit.to_double()
}

///|
pub fn recall_at(
  ranked : Array[String],
  relevant : Array[String],
  cutoff : Int,
) -> Double {
  let expected = unique_strings(relevant)
  if expected.is_empty() {
    return 0.0
  }
  count_relevant_at(ranked, expected, cutoff).to_double() /
  expected.length().to_double()
}

///|
pub fn f1_score(precision : Double, recall : Double) -> Double {
  if precision <= 0.0 || recall <= 0.0 {
    0.0
  } else {
    2.0 * precision * recall / (precision + recall)
  }
}

///|
pub fn reciprocal_rank_at(
  ranked : Array[String],
  relevant : Array[String],
  cutoff : Int,
) -> Double {
  let limit = effective_cutoff(ranked, cutoff)
  for i = 0; i < limit; i = i + 1 {
    if relevant.contains(ranked[i]) {
      return 1.0 / (i + 1).to_double()
    }
  }
  0.0
}

///|
pub fn average_precision_at(
  ranked : Array[String],
  relevant : Array[String],
  cutoff : Int,
) -> Double {
  let expected = unique_strings(relevant)
  if expected.is_empty() {
    return 0.0
  }
  let limit = effective_cutoff(ranked, cutoff)
  let seen : Array[String] = []
  let mut hits = 0
  let mut total = 0.0
  for i = 0; i < limit; i = i + 1 {
    let id = ranked[i]
    if expected.contains(id) && !seen.contains(id) {
      seen.push(id)
      hits = hits + 1
      total = total + hits.to_double() / (i + 1).to_double()
    }
  }
  total / expected.length().to_double()
}

///|
pub fn r_precision(ranked : Array[String], relevant : Array[String]) -> Double {
  let expected = unique_strings(relevant)
  if expected.is_empty() {
    return 0.0
  }
  precision_at(ranked, expected, expected.length())
}

///|
pub fn evaluate_ranking(
  ranked : Array[String],
  relevant : Array[String],
  cutoff? : Int = 10,
) -> RetrievalMetrics {
  let expected = unique_strings(relevant)
  let limit = effective_cutoff(ranked, cutoff)
  let hits = count_relevant_at(ranked, expected, cutoff)
  let precision = precision_at(ranked, expected, cutoff)
  let recall = recall_at(ranked, expected, cutoff)
  {
    cutoff,
    retrieved: limit,
    relevant: expected.length(),
    relevant_retrieved: hits,
    precision,
    recall,
    f1: f1_score(precision, recall),
    hit_rate: if hits > 0 {
      1.0
    } else {
      0.0
    },
    reciprocal_rank: reciprocal_rank_at(ranked, expected, cutoff),
    average_precision: average_precision_at(ranked, expected, cutoff),
    r_precision: r_precision(ranked, expected),
  }
}

///|
pub fn evaluate_results(
  results : Array[SearchResult],
  relevant : Array[String],
  cutoff? : Int = 10,
) -> RetrievalMetrics {
  evaluate_ranking(result_ids(results), relevant, cutoff~)
}

///|
pub fn summarize_evaluations(
  evaluations : Array[RetrievalMetrics],
) -> EvaluationSummary {
  if evaluations.is_empty() {
    return {
      query_count: 0,
      mean_precision: 0.0,
      mean_recall: 0.0,
      mean_f1: 0.0,
      mean_reciprocal_rank: 0.0,
      mean_average_precision: 0.0,
      hit_rate: 0.0,
    }
  }
  let mut precision = 0.0
  let mut recall = 0.0
  let mut f1 = 0.0
  let mut reciprocal_rank = 0.0
  let mut average_precision = 0.0
  let mut hits = 0.0
  for evaluation in evaluations {
    precision = precision + evaluation.precision
    recall = recall + evaluation.recall
    f1 = f1 + evaluation.f1
    reciprocal_rank = reciprocal_rank + evaluation.reciprocal_rank
    average_precision = average_precision + evaluation.average_precision
    hits = hits + evaluation.hit_rate
  }
  let count = evaluations.length().to_double()
  {
    query_count: evaluations.length(),
    mean_precision: precision / count,
    mean_recall: recall / count,
    mean_f1: f1 / count,
    mean_reciprocal_rank: reciprocal_rank / count,
    mean_average_precision: average_precision / count,
    hit_rate: hits / count,
  }
}

///|
pub fn mean_reciprocal_rank(
  rankings : Array[Array[String]],
  relevance : Array[Array[String]],
  cutoff? : Int = 10,
) -> Double {
  if rankings.is_empty() || rankings.length() != relevance.length() {
    return 0.0
  }
  let mut total = 0.0
  for i = 0; i < rankings.length(); i = i + 1 {
    total = total + reciprocal_rank_at(rankings[i], relevance[i], cutoff)
  }
  total / rankings.length().to_double()
}

///|
pub fn mean_average_precision(
  rankings : Array[Array[String]],
  relevance : Array[Array[String]],
  cutoff? : Int = 10,
) -> Double {
  if rankings.is_empty() || rankings.length() != relevance.length() {
    return 0.0
  }
  let mut total = 0.0
  for i = 0; i < rankings.length(); i = i + 1 {
    total = total + average_precision_at(rankings[i], relevance[i], cutoff)
  }
  total / rankings.length().to_double()
}

///|
pub fn corpus_coverage(
  rankings : Array[Array[String]],
  corpus_ids : Array[String],
  cutoff? : Int = 10,
) -> Double {
  let corpus = unique_strings(corpus_ids)
  if corpus.is_empty() {
    return 0.0
  }
  let retrieved : Array[String] = []
  for ranking in rankings {
    let limit = effective_cutoff(ranking, cutoff)
    for i = 0; i < limit; i = i + 1 {
      if corpus.contains(ranking[i]) && !retrieved.contains(ranking[i]) {
        retrieved.push(ranking[i])
      }
    }
  }
  retrieved.length().to_double() / corpus.length().to_double()
}
