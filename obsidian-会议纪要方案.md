# Obsidian 会议录音与 AI 总结方案

这套方案适合你现在的工作流：

- 在 Obsidian 里开会记笔记
- 直接录音或导入访谈音频
- 把转写稿放回同一篇笔记
- 调用本地脚本生成 AI 会议总结

## 推荐插件组合

### 必装

- `Audio Recorder`
  - Obsidian 官方录音插件
  - 用来在笔记里直接开始和结束录音
  - 来源：https://obsidian.md/help/plugins/audio-recorder

### 二选一

- `Obsidian Transcription`
  - 适合做长录音和访谈整理
  - 来源：https://github.com/djmango/obsidian-transcription
- `Whisper for Obsidian`
  - 适合快速录音转文字
  - 来源：https://github.com/nikdanilov/whisper-obsidian-plugin

### 推荐补充

- `Templater`
  - 用来管理会议模板
  - 来源：https://github.com/SilentVoid13/Templater
- `QuickAdd`
  - 用来做一个快捷命令，一键新建会议记录
  - 来源：https://github.com/chhoumann/quickadd

## 目录建议

建议在 Vault 里固定使用下面两个目录：

- `26子不语/会议记录`
- `26子不语/会议录音`

## 已提供的脚本

### 1. 新建会议笔记

```powershell
powershell -ExecutionPolicy Bypass -File .\bin\obsidian-meeting.ps1 new "客户访谈-张三" "我, 张三" "需求访谈"
```

### 2. 生成 AI 会议总结

当笔记中的 `## 转写全文` 已经有内容时，执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\bin\obsidian-meeting.ps1 summarize "26子不语/会议记录/2026-04-18-客户访谈-张三"
```

如果转写内容在外部文本文件中，也可以执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\bin\obsidian-meeting.ps1 summarize "26子不语/会议记录/2026-04-18-客户访谈-张三" ".\cache\transcript.txt"
```

## 实际使用流程

1. 在 Obsidian 中新建会议笔记
2. 用 Audio Recorder 开始录音
3. 会议结束后，把音频保存在同一篇笔记里
4. 用转写插件把录音变成文字
5. 把转写结果放到 `## 转写全文` 下
6. 运行 `obsidian-meeting.ps1 summarize`
7. 脚本会读取当前 `config.yaml` 和 `.env` 中的 MiniMax 配置，自动生成总结并回写到 `## AI会议总结`

## 输出结构

脚本会生成下面这几段：

- 一句话总结
- 核心结论
- 待办事项
- 风险与分歧
- 关键原话

## 注意事项

- 当前会议总结脚本走的是 MiniMax Anthropic 兼容接口
- 需要 `.env` 中已存在 MiniMax 中国区 API Key 和 Base URL
- 如果转写稿太短，输出会提示“转写信息不足”
