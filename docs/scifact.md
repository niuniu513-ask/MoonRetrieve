# SciFact 科研摘要检索复现

场景是给本地科研摘要库做可追溯检索。导入时保留论文 ID；查询返回排名；`context --json` 给出进入提示词的原文片段及引用编号；`trace --json` 可检查命中的词和来源。这里不调用生成模型，也不把“检索到”当作“结论已获论文证实”。

## 数据与准备

使用 BEIR 发布的 SciFact 测试划分。上游提供 5,183 篇摘要、300 条带正相关文档的测试查询、339 条正相关 query-document 标注。标注来自 SciFact 原始项目的人工作业，本项目没有重新人工标注。`scripts/prepare_scifact.py` 固定数据地址和 SHA-256，检查外键后生成本地 JSONL 与 `EvaluationCase` JSON；`_build/` 已忽略，仓库不分发语料。许可与来源见 [SOURCES.md](SOURCES.md)。

需要 Python 3、MoonBit 工具链；native 构建还需要 C 编译器。在仓库根目录执行：

```bash
python3 scripts/prepare_scifact.py
moon run cmd/main --target native -- index-jsonl _build/scifact/prepared/corpus.jsonl _build/scifact/index.json
moon run cmd/main --target native -- evaluate _build/scifact/index.json _build/scifact/prepared/cases.json -k 10 --json > _build/scifact/report.json
python3 scripts/check_scifact.py _build/scifact/report.json
```

评测按原始论文 ID 去重，报告每题 Top 10、Precision@10、Recall@10、MRR@10、MAP@10 与均值。脚本要求完整 300 题，不会用少量样例冒充全量结果。指标是英文医学摘要的文档级相关性，不衡量答案事实性、中文检索或用户满意度。

## 核对一条查询

测试集第一条查询为 `0-dimensional biomaterials show inductive properties.`，上游相关文档 ID 是 `31715818`。可直接查看排名、检索过程和进入上下文的引文：

```bash
moon run cmd/main --target native -- query _build/scifact/index.json "0-dimensional biomaterials show inductive properties." -k 10
moon run cmd/main --target native -- trace _build/scifact/index.json "0-dimensional biomaterials show inductive properties." -k 10 --json
moon run cmd/main --target native -- context _build/scifact/index.json "0-dimensional biomaterials show inductive properties." -k 5 --tokens 2000 --diverse --json
```

`context` 的 `citations[].doc_id` 含 `#` 分块编号，去掉该后缀后可与原始论文 ID 对照；`citations[].text` 是实际纳入提示词的内容。可在 `report.json` 中找低 Recall 的查询，结合 `trace` 检查词项缺失、分块或排序问题。需要外部试用反馈时，应单独记录使用者、任务、日期和得到的改动，不能用公开数据集评测代替真实用户采用证据。
