# Obsidian 本地 Whisper 说明

当前已经接入本地 `whisper.cpp` 方案，目标是让 Obsidian 在本机完成录音转写，再交给 Hermes 生成会议总结。

## 目录位置

- `D:\GuojinX\xilu\tools\whispercpp`
- `D:\GuojinX\xilu\tools\ffmpeg`

## 常用命令

### 启动本地转写服务

最稳的方式是直接运行：

```powershell
.\run-whisper-local.cmd
```

或者：

```powershell
powershell -ExecutionPolicy Bypass -File .\bin\run-whisper-local.ps1
```

### 查看状态

```powershell
powershell -ExecutionPolicy Bypass -File .\bin\whisper-local-status.ps1
```

### 停止服务

```powershell
powershell -ExecutionPolicy Bypass -File .\bin\stop-whisper-local.ps1
```

## Obsidian 侧行为

Whisper 插件会调用：

- `http://127.0.0.1:8080/inference`

生成的录音和笔记默认保存到：

- `26子不语/会议录音`
- `26子不语/会议记录`

转写笔记会直接生成下面的结构：

```markdown
# 会议记录

日期：...
时间：...
标签：#会议记录

## AI会议总结

等待生成。

## 录音

![[音频文件]]

## 转写全文

...
```

## 下一步

当转写完成后，再运行会议总结脚本：

```powershell
powershell -ExecutionPolicy Bypass -File .\bin\obsidian-meeting.ps1 summarize "26子不语/会议记录/你的笔记名"
```
