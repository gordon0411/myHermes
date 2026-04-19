# myHermes

`myHermes` 是我个人的 Hermes 工作目录备份，包含 `xilu` 这套本地脚本、飞书网关包装层、Obsidian 路由和定时任务配置。

## 仓库内容

- Hermes 启动脚本和 Windows 兼容包装
- 飞书网关启动与守护脚本
- 计划任务安装脚本
- Obsidian 路由与辅助脚本
- Cron 任务定义
- 常用文档、模板和 skills

## 不包含的内容

- `.env`、`auth.json` 等密钥和认证状态
- 日志、会话、缓存、数据库
- 本地虚拟环境和运行时沙箱
- `tools/` 下的大体积二进制依赖
- pairing、memory 等运行态数据

这些内容已经通过 `.gitignore` 排除，不会一起推送到 GitHub。

## 首次恢复

1. 克隆仓库
2. 复制 `.env.example` 为 `.env`
3. 填入你自己的 API key、本地路径和飞书配置
4. 安装 Hermes 主程序
5. 登录需要的 provider
6. 启动本地 Hermes 或飞书网关

## 环境文件

示例环境文件见 [.env.example](D:\GuojinX\xilu\.env.example)。

你至少需要按自己环境填写这些变量：

- `MINIMAX_CN_API_KEY`
- `FEISHU_APP_ID`
- `FEISHU_APP_SECRET`
- `EXA_API_KEY`
- `NOTION_API_KEY`
- `OBSIDIAN_VAULT_PATH`
- `OBSIDIAN_ROUTE_FILE`

## 常用命令

启动 Hermes CLI：

```powershell
powershell -ExecutionPolicy Bypass -File .\start-hermes.ps1
```

检查环境：

```powershell
powershell -ExecutionPolicy Bypass -File .\set-hermes-env.ps1
```

手动启动飞书网关：

```powershell
python .\start-hermes-gateway-v2.py
```

安装网关守护任务：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-hermes-service.ps1
```

## 自动守护

安装脚本会创建 `\Codex\HermesGateway` 计划任务：

- 登录时自动启动
- 每 5 分钟巡检一次
- 发现网关异常时自动重拉

## 迁移到新机器

1. 拉取仓库
2. 重建 `.env`
3. 重新登录 Hermes provider
4. 确认 Obsidian 路径和飞书应用配置正确
5. 运行 `set-hermes-env.ps1`
6. 安装计划任务并验证飞书连通

## 说明

- 仓库中的 `config.yaml`、`cron/jobs.json` 和脚本会尽量走环境变量，不应再写死密钥。
- 如果你已经泄露过旧 key，请在新机器恢复前先轮换。
