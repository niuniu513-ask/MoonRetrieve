# OSC 2026 项目自查报告

## 总体判断

`MoonRetrieve` 是一个有效的 MoonBit 项目，定位为纯 MoonBit 零 FFI 的本地全文检索与 RAG 检索库。项目具备分词、分块、BM25、短语/布尔/前缀检索、向量索引、RRF 融合、上下文组装、CLI、示例、差异化文档、CI、测试和 Apache-2.0 许可证，适合作为 MoonBit 应用生态/基础组件方向提交。

当前主要风险是源码规模偏小：核心 MoonBit 源码约 1302 行，不含测试；含测试约 1758 行，低于章程 4-10k 有效 MoonBit 行数参考范围。申报和验收时应强调项目边界是轻量本地检索/RAG 组件，并继续补充真实应用示例、持久化格式稳定性和更多检索能力。

## 提交前需要处理的问题

- Gitlink 仓库未在本地 remote 中体现。提交申报前需要导入并同步 Gitlink，确认默认分支能看到主要代码、README、LICENSE、CI、docs 和 examples。
- mooncakes 当前登录用户与包名不一致。本地 `moon publish --dry-run` 通过包校验，但服务端拒绝：`niuniu513-ask` 与当前认证用户 `fan-ere` 不匹配。发布前需要切换到 `niuniu513-ask` 的 mooncakes 登录态。
- 项目目录名是 `MoonSearch`，但 `moon.mod` 包名和 README 项目名是 `MoonRetrieve`。这不一定是错误，但提交材料中应统一说明，避免评审误以为仓库/包名不一致。

## 需要进一步确认的问题

- GitHub、Gitlink、mooncakes 的账号主体是否均为申报人或已在申报材料中解释协作关系。
- GitHub Actions 最新一次 CI 是否已通过，尤其是 native CLI smoke、三目标测试和 benchmark。
- 是否已经发布到 mooncakes.io；若未发布，需要用 `niuniu513-ask` 账号登录后发布。
- 是否与已有 MoonBit 检索项目存在功能重合；README 已说明与 `Lucius646/MoonSearch`、`houjie/rag-mbt` 的差异，申报书中也应保持同样说明。

## 建议改进

- CI 增加 `moon fmt --check .`、`moon check --deny-warn`、`moon test --deny-warn`，把本地严格检查结果固化到远端。
- 补充更完整的文档持久化示例，例如索引 JSON 格式兼容性、版本升级策略和错误恢复。
- 增加真实 RAG 场景示例：多文档导入、上下文预算、引用编号、中文/英文混合查询。
- 增加更多边界测试：空文档、重复文档、删除后重建、长文本分块、CJK 查询、向量维度不匹配。

## 已检查的证据

- `moon.mod`：包名为 `niuniu513-ask/MoonRetrieve`，许可证为 `Apache-2.0`，仓库为 `https://github.com/niuniu513-ask/MoonRetrieve`。
- `moon check`：通过。
- `moon test`：44 个测试全部通过。
- `moon check --deny-warn`：通过。
- `moon test --deny-warn`：44 个测试全部通过。
- `moon fmt --check .`：通过。
- `moon info`：通过。
- `moon publish --dry-run`：包校验和提取后检查通过，但认证用户与包命名空间不匹配。
- `git remote show origin`：远程默认分支为 `main`，本地 `main` 已跟踪 `origin/main`。
- `git rev-list --count HEAD`：原始历史为 18 个提交，提交数满足申报建议范围。

## 可选环境建议

- 当前 MoonBit 工具链版本满足要求：`moon 0.1.20260807`，`moonc v0.10.7`。
- 当前环境未发现 `moonbitlang/skills` 本地技能目录。后续开发 MoonBit 项目时，建议安装以获得更贴近 MoonBit 包结构、测试和工具链的辅助。
