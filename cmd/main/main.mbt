///|
/// MoonRetrieve CLI。
///
/// 用法：
///   moon run cmd/main -- index <文件或目录> [输出.json]
///   moon run cmd/main -- query <索引.json> "<查询>" [-k N]
///   moon run cmd/main -- context <索引.json> "<查询>" [-k N]
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
    "query" =>
      run_query(args) catch {
        err => println("Error: \{err.to_string()}")
      }
    "context" =>
      run_context(args) catch {
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
  println("  query <index.json> \"<query>\" [-k N]   检索")
  println("  context <index.json> \"<query>\" [-k N] 生成 LLM 上下文")
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
    let n = r.text.length()
    let end = if n > 300 { 300 } else { n }
    println(r.text.sub(start=0, end~))
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
  let engine = load_engine(json_path)
  let results = engine.search(query, top_k~)
  let cb = @lib.ContextBuilder::new(max_tokens=800)
  println(cb.build(query, results))
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
