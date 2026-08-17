# Sources and Compliance Notes

`MoonRetrieve` is an original MoonBit implementation. It does not copy source code from another search engine, RAG framework, tokenizer, or vector database.

The project uses public information-retrieval concepts as implementation references:

- BM25 scoring, inverted indexes, phrase search, boolean search, prefix search, cosine similarity, and Reciprocal Rank Fusion are implemented from standard public IR concepts.
- The tokenizer, chunker, context builder, JSON persistence helpers, and CLI are project-local MoonBit code.
- Example notes under `examples/notes/` are short repository-local sample documents written for tests and demos.
- The differentiation from existing MoonBit search/RAG projects is documented in `docs/differentiation.md`.

No private corpus, commercial dataset, copied fixture, or closed model output is included in the repository.
