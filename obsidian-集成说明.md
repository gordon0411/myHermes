# Obsidian 集成说明

当前 Hermes 已固定 3 条 Obsidian 路由：

- `ai_digest` -> `26子不语/AI周报记录.md`
- `weekly_work_report` -> `26子不语/产品周报记录.md`
- `work_log` -> `26子不语/工作日志.md`

这意味着飞书消息、定时任务和手工记录，都可以稳定落到固定笔记里，不会再四处分散。

## 常用命令

```powershell
powershell -ExecutionPolicy Bypass -File .\bin\obsidian.ps1 list "26子不语"
powershell -ExecutionPolicy Bypass -File .\bin\obsidian.ps1 read "26子不语\产品周报记录"
powershell -ExecutionPolicy Bypass -File .\bin\obsidian-route.ps1 weekly_work_report "2026-04-18 每周工作周报" "正文内容"
```

## 固定笔记规范

- AI 资讯类内容统一写入 `ai_digest`
- 周报类内容统一写入 `weekly_work_report`
- 日志和随手记录统一写入 `work_log`

`work_log` 采用统一结构：

```markdown
## 2026-04-18 工作日志

记录时间：2026-04-18 18:00

- 今日事项：...
- 关键进展：...
- 风险阻塞：...
- 下一步：...

---
```

## 工作日志快捷写入

可以直接调用下面这个脚本，把内容按固定结构写入工作日志：

```powershell
powershell -ExecutionPolicy Bypass -File .\bin\obsidian-worklog.ps1 `
  -Summary "梳理飞书到 Obsidian 的自动落盘流程" `
  -Progress "已完成路由脚本和定时任务改造" `
  -Risks "需要继续观察定时任务真实运行效果" `
  -NextStep "验证今晚或明日的自动写入结果"
```
