#!/usr/bin/env python3
import urllib.request
import json

# Get token from .env
with open('/mnt/d/GuojinX/xilu/.env', 'r') as f:
    for line in f:
        line = line.strip()
        if line.startswith('FEISHU_APP_SECRET'):
            secret = line.split('=', 1)[1].strip()
            break

data = json.dumps({
    'app_id': 'cli_a968e84c6878dbc4',
    'app_secret': secret
}).encode()
req = urllib.request.Request(
    'https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal',
    data=data, headers={'Content-Type': 'application/json'}
)
resp = urllib.request.urlopen(req, timeout=10)
token = json.loads(resp.read())['tenant_access_token']

# ============================================================
# Report content - 2026年4月24日（周五）IT管理工作日报
# ============================================================
report = """📋 IT管理工作日报
📅 2026年4月24日（周五）

━━━━━━━━━━━━━━━━━
一、今日重点工作
━━━━━━━━━━━━━━━━━
1. 智能广告产品六周MVP规划会议 ✅
   · 围绕六周内上线可销售MVP目标召开专项会议
   · 产品定位：在现有广告产品基础上新增AI分析模块与存量策略参数调优，定价维持18.8万元/年
   · 核心功能锁定：拓词分析、广告结构诊断、策略参数配置提效（AI仅协助调整，不从零生成策略）
   · 数据基础：依赖标签中心与已聚合宽表，30分钟数据时效基准，不接入原始明细表
   · 职责分工明确：福菁负责分析模块，星哲负责策略配置，玉玲负责用户体验与定价
   · 关键约束：下周一前完成核心场景、数据范围、客户试点名单锁定

2. 广告业务口径确认
   · 与广告业务侧确认口径及下周计划，推进需求落地

━━━━━━━━━━━━━━━━━
二、待办/进行中事项
━━━━━━━━━━━━━━━━━
· 智能广告六周MVP：下周一前锁定约束定义（核心场景+数据范围+试点客户）
· 广告业务需求跟进与口径对齐
· 物流模块后续跟进（待诗思完成人力评估）
· IT管理周会问题后续跟踪落实

━━━━━━━━━━━━━━━━━
三、风险与关注点
━━━━━━━━━━━━━━━━━
· PM角色缺位：智能广告产品经理仍未到位，六周交付计划存在执行风险
· 物流模块单开发人力瓶颈，运输单等核心功能待完善
· TK数据波动问题：财务数据与业务数据不一致，持续关注

━━━━━━━━━━━━━━━━━
四、本周工作连续性
━━━━━━━━━━━━━━━━━
（周四 4/23）
· 子不语项目18个月里程碑计划制定完成，各模块进度跟踪机制建立
· 团队Q1绩效打分完成，Q2目标审核完成

（周三 4/22）
· 商品中心需求沟通，推进业务侧需求落地
· 智能广告Agent规划材料准备（定位：超级运营个体的广告投放AI智能体）
· 前端功能壁垒评估推进中

（周二 4/21）
· 智能广告规划讨论，产品经理缺位问题凸显
· 产品人员微调（向男调回产品组）
· 数织与子不语人员调整确认，430淘汰名单锁定（合计11人）

（周一 4/20）
· 子不语430淘汰名单更新（数据1人调至AI创新，1人延至630节点）
· IT管理周会：TK数据波动问题跟踪
· CEO驾驶舱改造需求提出：需建立主动推送机制
· 数织BI项目全面盘点

━━━━━━━━━━━━━━━━━
五、本周其他进展
━━━━━━━━━━━━━━━━━
· 4/23：子不语18个月里程碑计划建立；团队Q1绩效完成
· 4/22：商品中心需求对齐；智能广告前端壁垒评估
· 4/21：产品人员微调确认；430淘汰名单锁定（11人）
· 4/20：TK数据跟踪；数织BI全面盘点
· 4/19：Hermes与飞书集成修复；Codex API Key采购落地

━━━━━━━━━━━━━━━━━
六、信息来源备注
━━━━━━━━━━━━━━━━━
· Notion 工作日志（页面ID: 34349d5b27068057ac62c99678af306c）
  https://www.notion.so/002-34349d5b27068057ac62c99678af306c
· Obsidian 工作日志
  备注：Obsidian vault路径（C:\Users\admin.ZBYCORP\Documents\Obsidian Vault）为Windows路径，本执行环境（Linux）无法直接访问；日报内容以Notion数据为准"""

# Send message
payload = json.dumps({
    'receive_id': 'oc_40d609fc62c1f82234b75138fbc7a446',
    'msg_type': 'text',
    'content': json.dumps({'text': report}, ensure_ascii=False)
}).encode()

req2 = urllib.request.Request(
    'https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id',
    data=payload,
    headers={'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token}
)
resp2 = urllib.request.urlopen(req2, timeout=15)
result = json.loads(resp2.read())
print("Send result:", result.get('code'), result.get('msg'))
if result.get('code') == 0:
    print("Message sent successfully!")
    msg_data = result.get('data', {})
    print("Message ID:", msg_data.get('message_id'))
else:
    print("Error details:", result)
