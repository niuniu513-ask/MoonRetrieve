///|
/// Keep derived trait methods available as explicit methods on public types.
pub extend Chunker with ToJson::{to_json}

///|
pub extend Chunker with @json.FromJson::{from_json}

///|
pub extend ContextBuilder with ToJson::{to_json}

///|
pub extend ContextBuilder with @json.FromJson::{from_json}

///|
pub extend Engine with ToJson::{to_json}

///|
pub extend Engine with @json.FromJson::{from_json}

///|
pub extend RetrievalMetrics with @debug.Debug::{to_repr}

///|
pub extend EvaluationSummary with @debug.Debug::{to_repr}

///|
pub extend ResultExplanation with @debug.Debug::{to_repr}

///|
pub extend Posting with ToJson::{to_json}

///|
pub extend Posting with @json.FromJson::{from_json}

///|
pub extend Posting with Eq::{not_equal, equal}

///|
pub extend Posting with @debug.Debug::{to_repr}

///|
pub extend SearchIndex with ToJson::{to_json}

///|
pub extend SearchIndex with @json.FromJson::{from_json}

///|
pub extend QueryClause with Eq::{not_equal, equal}

///|
pub extend QueryClause with @debug.Debug::{to_repr}

///|
pub extend QueryPlan with Eq::{not_equal, equal}

///|
pub extend QueryPlan with @debug.Debug::{to_repr}

///|
pub extend ResultGroup with @debug.Debug::{to_repr}

///|
pub extend QuerySuggestion with Eq::{not_equal, equal}

///|
pub extend QuerySuggestion with @debug.Debug::{to_repr}

///|
pub extend Keyword with Eq::{not_equal, equal}

///|
pub extend Keyword with @debug.Debug::{to_repr}

///|
pub extend TextSummary with Eq::{not_equal, equal}

///|
pub extend TextSummary with @debug.Debug::{to_repr}

///|
pub extend Tokenizer with ToJson::{to_json}

///|
pub extend Tokenizer with @json.FromJson::{from_json}

///|
pub extend Chunk with ToJson::{to_json}

///|
pub extend Chunk with @json.FromJson::{from_json}

///|
pub extend Chunk with Eq::{not_equal, equal}

///|
pub extend Chunk with @debug.Debug::{to_repr}

///|
pub extend SearchResult with ToJson::{to_json}

///|
pub extend SearchResult with @json.FromJson::{from_json}

///|
pub extend SearchResult with Eq::{not_equal, equal}

///|
pub extend SearchResult with @debug.Debug::{to_repr}

///|
pub extend ScoredDoc with ToJson::{to_json}

///|
pub extend ScoredDoc with @json.FromJson::{from_json}

///|
pub extend ScoredDoc with Eq::{not_equal, equal}

///|
pub extend ScoredDoc with @debug.Debug::{to_repr}

///|
pub extend IndexStats with ToJson::{to_json}

///|
pub extend IndexStats with @json.FromJson::{from_json}

///|
pub extend IndexStats with @debug.Debug::{to_repr}

///|
pub extend VectorIndex with ToJson::{to_json}

///|
pub extend VectorIndex with @json.FromJson::{from_json}
