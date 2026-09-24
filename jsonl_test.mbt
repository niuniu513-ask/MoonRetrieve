///|
test "JSONL parser accepts stable IDs and optional titles" {
  let input = "{\"_id\":\"42\",\"title\":\"Guide\",\"text\":\"MoonBit\"}\n" +
    "{\"id\":\"faq\",\"text\":\"RAG\"}\n"
  match @MoonRetrieve.parse_document_jsonl(input) {
    Ok(documents) => {
      assert_eq(documents.length(), 2)
      assert_eq(documents[0].0, "42")
      assert_eq(documents[0].1, "Guide\n\nMoonBit")
      assert_eq(documents[1].0, "faq")
      assert_eq(documents[1].1, "RAG")
    }
    Err(_) => fail("valid JSONL was rejected")
  }
}

///|
test "JSONL parser rejects duplicate and malformed documents" {
  let duplicate = "{\"id\":\"same\",\"text\":\"one\"}\n" +
    "{\"_id\":\"same\",\"text\":\"two\"}"
  match @MoonRetrieve.parse_document_jsonl(duplicate) {
    Ok(_) => fail("duplicate IDs were accepted")
    Err(message) => assert_true(message.contains("duplicate"))
  }
  match @MoonRetrieve.parse_document_jsonl("{\"id\":\"a\"}") {
    Ok(_) => fail("missing text was accepted")
    Err(message) => assert_true(message.contains("missing text"))
  }
  match @MoonRetrieve.parse_document_jsonl("not JSON") {
    Ok(_) => fail("invalid JSON was accepted")
    Err(message) => assert_true(message.contains("line 1"))
  }
}
