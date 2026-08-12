///|
test "short doc stays one chunk" {
  let c = @MoonSearch.Chunker::new()
  let chunks = c.chunk("doc1", "第一段\n第二段")
  assert_true(chunks.length() == 1)
  assert_true(chunks[0].doc_id == "doc1")
  assert_true(chunks[0].text == "第一段\n第二段")
}

///|
test "chunks carry overlap from previous chunk" {
  let c = @MoonSearch.Chunker::new(max_chars=20, overlap=5)
  let chunks = c.chunk("doc2", "aaaaaaaaaaaa\nbbbbbbbbbbbb")
  assert_true(chunks.length() == 2)
  assert_true(chunks[0].text == "aaaaaaaaaaaa")
  assert_true(chunks[1].text == "aaaaa\nbbbbbbbbbbbb")
  assert_true(chunks[1].index == 1)
}

///|
test "long paragraph hard split" {
  let c = @MoonSearch.Chunker::new(max_chars=10, overlap=0)
  let chunks = c.chunk("doc3", "abcdefghijklmnopqrst")
  assert_true(chunks.length() == 2)
  assert_true(chunks[0].text == "abcdefghij")
  assert_true(chunks[1].text == "klmnopqrst")
}
