///|
/// MoonRetrieve CLI。
///
/// 用法：
///   moon run cmd/main -- index <文件或目录> [输出.json]
///   moon run cmd/main -- index-jsonl <文档.jsonl> [输出.json]
///   moon run cmd/main -- query <索引.json> "<查询>" [-k N]
///   moon run cmd/main -- context <索引.json> "<查询>" [-k N] [--tokens N] [--diverse] [--json]
///   moon run cmd/main -- evaluate <索引.json> <标注.json> [-k N] [--json]
///   moon run cmd/main -- trace <索引.json> "<查询>" [-k N] [--json]
///   moon run cmd/main -- stats <索引.json>
///   moon run cmd/main -- phrase <索引.json> "<短语>" [-k N]
///   moon run cmd/main -- boolean <索引.json> "<表达式>" [-k N]
///   moon run cmd/main -- prefix <索引.json> "<前缀>" [-k N]
///   moon run cmd/main -- snippet <索引.json> "<查询>" [-k N] [--chars N]
///   moon run cmd/main -- explain <索引.json> "<查询>" [-k N]
async fn main {
  let args = @env.args()
  if args.length() < 2 {
    usage()
    return
  }
  let cmd = args[1]
  match cmd {
    "index" =>
      run_index(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    "index-jsonl" =>
      run_index_jsonl(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    "query" =>
      run_query(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    "context" =>
      run_context(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    "evaluate" =>
      run_evaluate(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    "trace" =>
      run_trace(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    "stats" =>
      run_stats(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    "phrase" =>
      run_phrase(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    "boolean" =>
      run_boolean(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    "prefix" =>
      run_prefix(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    "snippet" =>
      run_snippet(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    "explain" =>
      run_explain(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    _ => usage()
  }
}

///|
fn usage() -> Unit {
  println("MoonRetrieve CLI")
  println(
    "  index <path> [output.json]        建索引（支持 .md/.txt 文件或目录）",
  )
  println("  index-jsonl <path> [output.json]  导入 id/title/text JSONL")
  println("  query <index.json> \"<query>\" [-k N] [--highlight]   检索")
  println(
    "  context <index.json> \"<query>\" [-k N] [--tokens N] [--diverse] [--json] 生成上下文",
  )
  println(
    "  evaluate <index.json> <cases.json> [-k N] [--json] 评测文档级检索",
  )
  println(
    "  trace <index.json> \"<query>\" [-k N] [--json] 输出检索诊断轨迹",
  )
  println("  stats <index.json>                      索引统计")
  println("  phrase <index.json> \"<phrase>\" [-k N]  短语检索")
  println(
    "  boolean <index.json> \"<expr>\" [-k N]   布尔检索（AND/OR/-term）",
  )
  println("  prefix <index.json> \"<prefix>\" [-k N]  前缀检索")
  println(
    "  snippet <index.json> \"<query>\" [-k N] [--chars N]  输出命中片段",
  )
  println("  explain <index.json> \"<query>\" [-k N]  输出相关性解释")
}

///|
async fn run_index(args : Array[String]) -> Unit {
  if args.length() < 3 {
    usage()
    return
  }
  let path = args[2]
  let output = if args.length() >= 4 { args[3] } else { "index.json" }
  let files : Array[String] = []
  collect_files(path, files)
  if files.is_empty() {
    println("No .md/.txt files found under \{path}")
    return
  }
  let engine = @lib.Engine::new()
  let mut count = 0
  for f in files {
    let text = @fs.read_file(f).text()
    engine.add_document(f, text)
    count = count + 1
    println("indexed \{f}")
  }
  let json = engine.save()
  @fs.write_file(output, json, create_mode=@fs.CreateOrTruncate)
  println("Done: \{count} files, \{engine.count()} chunks -> \{output}")
}

///|
async fn run_index_jsonl(args : Array[String]) -> Unit {
  if args.length() < 3 {
    usage()
    return
  }
  let input = @fs.read_file(args[2]).text()
  let documents = match @lib.parse_document_jsonl(input) {
    Ok(documents) => documents
    Err(message) => abort("invalid document JSONL: \{message}")
  }
  let output = if args.length() >= 4 { args[3] } else { "index.json" }
  let engine = @lib.Engine::new()
  engine.add_documents(documents)
  @fs.write_file(output, engine.save(), create_mode=@fs.CreateOrTruncate)
  println(
    "Done: \{documents.length()} documents, \{engine.count()} chunks -> \{output}",
  )
}

///|
async fn run_query(args : Array[String]) -> Unit {
  if args.length() < 4 {
    usage()
    return
  }
  let json_path = args[2]
  let query = args[3]
  let top_k = parse_top_k(args, 5)
  let engine = load_engine(json_path)
  let results = engine.search(query, top_k~)
  println("Top \{results.length()} results for: \{query}")
  for r in results {
    println("\n[\{r.doc_id}] score=\{r.score}")
    if args.contains("--highlight") {
      println(engine.highlight(r.text, query))
    } else {
      let n = r.text.length()
      let end = if n > 300 { 300 } else { n }
      println(r.text.exact_view(start=0, end~))
    }
  }
}

///|
async fn run_phrase(args : Array[String]) -> Unit {
  if args.length() < 4 {
    usage()
    return
  }
  let json_path = args[2]
  let query = args[3]
  let top_k = parse_top_k(args, 5)
  let engine = load_engine(json_path)
  let results = engine.search_phrase(query, top_k~)
  println("Top \{results.length()} phrase results for: \{query}")
  for r in results {
    println("\n[\{r.doc_id}] score=\{r.score}")
    if args.contains("--highlight") {
      println(engine.highlight(r.text, query))
    } else {
      let n = r.text.length()
      let end = if n > 300 { 300 } else { n }
      println(r.text.exact_view(start=0, end~))
    }
  }
}

///|
async fn run_boolean(args : Array[String]) -> Unit {
  if args.length() < 4 {
    usage()
    return
  }
  let engine = load_engine(args[2])
  let query = args[3]
  let top_k = parse_top_k(args, 5)
  let results = engine.search_boolean(query, top_k~)
  println("Top \{results.length()} boolean results for: \{query}")
  for r in results {
    println("\n[\{r.doc_id}] score=\{r.score}")
    let n = r.text.length()
    let end = if n > 300 { 300 } else { n }
    println(r.text.exact_view(start=0, end~))
  }
}

///|
async fn run_prefix(args : Array[String]) -> Unit {
  if args.length() < 4 {
    usage()
    return
  }
  let engine = load_engine(args[2])
  let prefix = args[3]
  let top_k = parse_top_k(args, 5)
  let results = engine.search_prefix(prefix, top_k~)
  println("Top \{results.length()} prefix results for: \{prefix}")
  for r in results {
    println("\n[\{r.doc_id}] score=\{r.score}")
    let n = r.text.length()
    let end = if n > 300 { 300 } else { n }
    println(r.text.exact_view(start=0, end~))
  }
}

///|
async fn run_snippet(args : Array[String]) -> Unit {
  if args.length() < 4 {
    usage()
    return
  }
  let engine = load_engine(args[2])
  let query = args[3]
  let top_k = parse_top_k(args, 5)
  let max_chars = parse_option(args, "--chars", 160)
  let results = engine.search_snippets(query, top_k~, max_chars~)
  println("Top \{results.length()} snippets for: \{query}")
  for r in results {
    println("\n[\{r.doc_id}] score=\{r.score}")
    println(r.text)
  }
}

///|
async fn run_explain(args : Array[String]) -> Unit {
  if args.length() < 4 {
    usage()
    return
  }
  let engine = load_engine(args[2])
  let query = args[3]
  let top_k = parse_top_k(args, 5)
  let explanations = engine.search_explained(query, top_k~)
  println("Explanations for: \{query}")
  for explanation in explanations {
    println(@lib.explanation_summary(explanation))
  }
}

///|
async fn run_context(args : Array[String]) -> Unit {
  if args.length() < 4 {
    usage()
    return
  }
  let json_path = args[2]
  let query = args[3]
  let top_k = parse_top_k(args, 5)
  let max_tokens = parse_option(args, "--tokens", 800)
  let engine = load_engine(json_path)
  let report = if args.contains("--diverse") {
    engine.build_diverse_context_report(query, top_k~, max_tokens~)
  } else {
    engine.build_context_report(query, top_k~, max_tokens~)
  }
  if args.contains("--json") {
    println(@json.to_json(report).stringify())
  } else {
    println(report.prompt)
  }
}

///|
async fn run_evaluate(args : Array[String]) -> Unit {
  if args.length() < 4 {
    usage()
    return
  }
  let engine = load_engine(args[2])
  let text = @fs.read_file(args[3]).text()
  let cases = match @lib.parse_evaluation_cases(text) {
    Ok(cases) => cases
    Err(msg) => abort("invalid evaluation set: \{msg}")
  }
  let report = engine.evaluate_queries(cases, cutoff=parse_top_k(args, 10))
  if args.contains("--json") {
    println(@json.to_json(report).stringify())
  } else {
    for query in report.queries {
      println(
        "\{query.query}: \{@json.to_json(query.ranked_doc_ids).stringify()}",
      )
    }
    println("Queries: \{report.summary.query_count}")
    println("Precision@\{report.cutoff}: \{report.summary.mean_precision}")
    println("Recall@\{report.cutoff}: \{report.summary.mean_recall}")
    println("MRR@\{report.cutoff}: \{report.summary.mean_reciprocal_rank}")
    println("MAP@\{report.cutoff}: \{report.summary.mean_average_precision}")
    println("Hit rate@\{report.cutoff}: \{report.summary.hit_rate}")
  }
}

///|
async fn run_trace(args : Array[String]) -> Unit {
  if args.length() < 4 {
    usage()
    return
  }
  let trace = load_engine(args[2]).trace(args[3], top_k=parse_top_k(args, 10))
  if args.contains("--json") {
    println(@json.to_json(trace).stringify())
    return
  }
  println("Query: \{trace.query}")
  println("Terms: \{@json.to_json(trace.query_terms).stringify()}")
  println("Sources: \{trace.source_count}")
  for hit in trace.hits {
    println(
      "\{hit.rank}. \{hit.doc_id} score=\{hit.score} overlap=\{hit.token_overlap}",
    )
    println(
      "   matched=\{@json.to_json(hit.matched_terms).stringify()} missing=\{@json.to_json(hit.missing_terms).stringify()}",
    )
  }
}

///|
async fn run_stats(args : Array[String]) -> Unit {
  if args.length() < 3 {
    usage()
    return
  }
  let engine = load_engine(args[2])
  let s = engine.stats()
  println("chunks: \{s.doc_count}")
  println("terms: \{s.term_count}")
  println("total tokens: \{s.total_tokens}")
  println("avg doc len: \{s.avg_doc_len}")
}

///|
async fn load_engine(json_path : String) -> @lib.Engine {
  let text = @fs.read_file(json_path).text()
  match @lib.Engine::try_load(text) {
    Ok(engine) => engine
    Err(msg) => abort("invalid index: \{msg}")
  }
}

///|
async fn collect_files(path : String, out : Array[String]) -> Unit {
  match @fs.kind(path) {
    @fs.FileKind::Regular => if is_doc_file(path) { out.push(path) }
    @fs.FileKind::Directory => {
      let names = @fs.readdir(path, sort=true)
      for name in names {
        if name != "." && name != ".." {
          collect_files(path + "/" + name, out)
        }
      }
    }
    _ => ()
  }
}

///|
fn is_doc_file(path : String) -> Bool {
  path.has_suffix(".md") ||
  path.has_suffix(".txt") ||
  path.has_suffix(".markdown")
}

///|
fn parse_top_k(args : Array[String], default : Int) -> Int {
  for i = 2; i + 1 < args.length(); i = i + 1 {
    if args[i] == "-k" {
      return @string.parse_int(args[i + 1]) catch { _ => default }
    }
  }
  default
}

///|
fn parse_option(args : Array[String], name : String, default : Int) -> Int {
  for i = 2; i + 1 < args.length(); i = i + 1 {
    if args[i] == name {
      return @string.parse_int(args[i + 1]) catch { _ => default }
    }
  }
  default
}
