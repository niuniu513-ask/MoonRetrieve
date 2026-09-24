"""Validate and summarize a full SciFact retrieval report without hiding failures."""

import json
import sys
from pathlib import Path


def main():
    report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    queries = report["queries"]
    summary = report["summary"]
    if report["cutoff"] != 10 or summary["query_count"] != 300 or len(queries) != 300:
        raise ValueError("expected the complete 300-query SciFact test split at k=10")
    if not 0.0 <= summary["mean_recall"] <= 1.0:
        raise ValueError("invalid recall")
    if not 0.0 <= summary["mean_reciprocal_rank"] <= 1.0:
        raise ValueError("invalid MRR")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
