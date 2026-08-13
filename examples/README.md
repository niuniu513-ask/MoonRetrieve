# 示例

`examples/notes/` 是一组 Markdown 笔记，用于演示完整流程。

## 建索引

```bash
moon run cmd/main --target native -- index examples/notes index.json
```

输出会逐条打印 `indexed <文件>`，最后汇总文件数与分块数。

## 检索

```bash
moon run cmd/main --target native -- query index.json "MoonBit 黑客松" -k 3
```

## 生成 LLM 上下文

```bash
moon run cmd/main --target native -- context index.json "奖励" -k 3
```

## 查看统计

```bash
moon run cmd/main --target native -- stats index.json
```

```text
chunks: 12
terms: 86
total tokens: 342
avg doc len: 28.5
```

## 短语检索与高亮

```bash
moon run cmd/main --target native -- phrase index.json "MoonBit 黑客松" -k 3 --highlight
```
