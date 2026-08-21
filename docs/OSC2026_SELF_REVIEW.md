# OSC 2026 项目自查报告

## 总体判断

`MoonRetrieve` 是一个有效的 MoonBit 项目，定位为纯 MoonBit 零 FFI 的本地全文检索与 RAG 检索库。项目具备分词、分块、BM25、短语/布尔/前缀检索、向量索引、RRF 融合、上下文组装、CLI、可在 wasm-gc 运行的最小示例、差异化文档、CI、测试和 Apache-2.0 许可证，适合作为 MoonBit 应用生态/基础组件方向提交。

项目有效 MoonBit 源码与测试已超过 4,000 行，新增检索评估、查询纠错、结构化查询、结果融合去重、摘要与相关性解释，达到章程项目规模参考下限。GitHub、CI、许可证、README、示例、测试和 mooncakes 发布均已具备终审所需证据。

## 提交前需要处理的问题

- Gitlink 仓库未在本地 remote 中体现。提交申报前需要导入并同步 Gitlink，确认默认分支能看到主要代码、README、LICENSE、CI、docs 和 examples。
- 项目目录名是 `MoonSearch`，但 `moon.mod` 包名和 README 项目名是 `MoonRetrieve`。这不一定是错误，但提交材料中应统一说明，避免评审误以为仓库/包名不一致。

## 需要进一步确认的问题

- 申请人牛畅乐与 `niuniu513-ask` 的关系及两个历史 Git 作者身份已由 `docs/PARTICIPATION.md` 和 `.mailmap` 说明。
- 是否已经把 GitHub 当前默认分支同步到 Gitlink。
- 是否与已有 MoonBit 检索项目存在功能重合；README 已说明与 `Lucius646/MoonSearch`、`houjie/rag-mbt` 的差异，申报书中也应保持同样说明。

## 建议改进

- 补充更完整的文档持久化示例，例如索引 JSON 格式兼容性、版本升级策略和错误恢复。
- 增加真实 RAG 场景示例：多文档导入、上下文预算、引用编号、中文/英文混合查询。
- 增加更多边界测试：空文档、重复文档、删除后重建、长文本分块、CJK 查询、向量维度不匹配。

## 已检查的证据

- `moon.mod`：包名为 `niuniu513-ask/MoonRetrieve`，许可证为 `Apache-2.0`，仓库为 `https://github.com/niuniu513-ask/MoonRetrieve`。
- `moon check`：通过。
- `moon test`：100 个测试全部通过。
- `moon check --deny-warn`：通过。
- `moon test --deny-warn`：100 个测试全部通过。
- `moon fmt --check .`：通过。
- `moon info`：通过。
- `moon run examples/quickstart --target wasm-gc`：通过，可直接验证建索引、检索和上下文组装。
- GitHub Actions：最新 CI 已通过 native CLI smoke、三目标测试和 benchmark。
- `moon publish`：`niuniu513-ask/MoonRetrieve@0.4.3` 已发布成功；当前本地版本为 `0.5.0`，待发布。
- `git remote show origin`：远程默认分支为 `main`，本地 `main` 已跟踪 `origin/main`。
- `git rev-list --count HEAD`：当前历史为 22 个提交，超过申报阶段建议的 10–20 个有效提交；这些提交均为真实开发历史，不做破坏性改写。该区间不是终审硬标准。

## 可选环境建议

- 当前 MoonBit 工具链版本满足要求：`moon 0.1.20260807`，`moonc v0.10.7`。
- 当前环境未发现 `moonbitlang/skills` 本地技能目录。后续开发 MoonBit 项目时，建议安装以获得更贴近 MoonBit 包结构、测试和工具链的辅助。
