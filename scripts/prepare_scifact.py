"""Prepare the BEIR SciFact test split for MoonRetrieve's document-level evaluation."""

import argparse
import csv
import hashlib
import io
import json
import urllib.request
import zipfile
from collections import defaultdict
from pathlib import Path


URL = "https://public.ukp.informatik.tu-darmstadt.de/thakur/BEIR/datasets/scifact.zip"
SHA256 = "536e14446a0ba56ed1398ab1055f39fe852686ecad24a6306c80c490fa8e0165"


def records(archive, member):
    with archive.open(member) as source:
        for line in source:
            yield json.loads(line)


def prepare(archive_path, output):
    digest = hashlib.sha256(archive_path.read_bytes()).hexdigest()
    if digest != SHA256:
        raise ValueError(f"SciFact archive SHA-256 mismatch: {digest}")

    with zipfile.ZipFile(archive_path) as archive:
        corpus = list(records(archive, "scifact/corpus.jsonl"))
        corpus_ids = {row["_id"] for row in corpus}
        if len(corpus_ids) != len(corpus):
            raise ValueError("duplicate corpus IDs")
        queries = {
            row["_id"]: row["text"]
            for row in records(archive, "scifact/queries.jsonl")
        }
        labels = defaultdict(set)
        with archive.open("scifact/qrels/test.tsv") as source:
            reader = csv.DictReader(io.TextIOWrapper(source, encoding="utf-8"), delimiter="\t")
            for row in reader:
                if int(row["score"]) > 0:
                    labels[row["query-id"]].add(row["corpus-id"])

    if not labels or any(key not in queries for key in labels):
        raise ValueError("test labels reference unknown queries")
    if any(doc not in corpus_ids for docs in labels.values() for doc in docs):
        raise ValueError("test labels reference unknown documents")
    cases = [
        {"query": queries[key], "relevant_doc_ids": sorted(labels[key])}
        for key in sorted(labels, key=int)
    ]
    output.mkdir(parents=True, exist_ok=True)
    with (output / "corpus.jsonl").open("w", encoding="utf-8", newline="\n") as dest:
        for row in corpus:
            dest.write(json.dumps({key: row[key] for key in ("_id", "title", "text")}, ensure_ascii=False) + "\n")
    (output / "cases.json").write_text(
        json.dumps(cases, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(
        f"SciFact test: {len(corpus)} documents, {len(cases)} queries, "
        f"{sum(map(len, labels.values()))} positive query-document labels"
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("_build/scifact/prepared"))
    parser.add_argument("--archive", type=Path, default=Path("_build/scifact/scifact.zip"))
    args = parser.parse_args()
    args.archive.parent.mkdir(parents=True, exist_ok=True)
    if not args.archive.exists():
        urllib.request.urlretrieve(URL, args.archive)
    prepare(args.archive, args.output)


if __name__ == "__main__":
    main()
