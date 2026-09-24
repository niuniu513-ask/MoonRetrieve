# Sources and Compliance Notes

`MoonRetrieve` is an original MoonBit implementation. It does not copy source code from another search engine, RAG framework, tokenizer, or vector database.

The project uses public information-retrieval concepts as implementation references:

- BM25 scoring, inverted indexes, phrase search, boolean search, prefix search, cosine similarity, and Reciprocal Rank Fusion are implemented from standard public IR concepts.
- The tokenizer, chunker, context builder, JSON persistence helpers, and CLI are project-local MoonBit code.
- Example notes under `examples/notes/` are short repository-local sample documents written for tests and demos.
- The differentiation from existing MoonBit search/RAG projects is documented in `docs/differentiation.md`.

No private corpus, commercial dataset, copied fixture, or closed model output is included in the repository.

## SciFact evaluation data

The reproducible evaluation uses the public [SciFact dataset](https://github.com/allenai/scifact) through the [BEIR SciFact archive](https://github.com/beir-cellar/beir). Its corpus consists of S2ORC paper abstracts (ODC-By 1.0); SciFact claims and evidence annotations are CC BY 4.0 according to the upstream `LICENSE.md`. The upstream code is Apache-2.0. The 300 test queries and 339 positive query-document labels were created upstream by human annotators, not by MoonRetrieve's author. They are relevance labels, not proof that every retrieved passage supports a generated answer.

The archive URL and SHA-256 are pinned in `scripts/prepare_scifact.py`. The script downloads the dataset to ignored `_build/`, verifies the archive, and produces local input files. No SciFact corpus text, queries, or labels are committed or republished in this repository. See [the reproduction guide](scifact.md) for evaluation commands and scope.
