#!/usr/bin/env python3
import urllib.request
import json

# Get token
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

# Report content
report = """📋 IT管理工作日报
📅 2026年4月22日（周三）

━━━━━━━━━━━━━━━━━
一、今日重点工作
━━━━━━━━━━━━━━━━━
1. 商品中心需求沟通
   · 内部确认排期和计划，推进业务侧需求落地

2. 供应链AI项目推进
   · 智能广告Agent规划材料准备中
   · 定位：面向超级运营个体的广告投放专家/智能体（硅基员工）
   · 前端功能壁垒评估中

━━━━━━━━━━━━━━━━━
二、待办/进行中事项
━━━━━━━━━━━━━━━━━
· 智能广告Agent产品经理角色缺位，持续影响项目规划进度
· 物流需求后续跟进（待诗思完成人力评估）
· 供应链AI项目前端功能壁垒攻坚
· IT管理周会问题后续跟踪

━━━━━━━━━━━━━━━━━
三、风险与关注点
━━━━━━━━━━━━━━━━━
· TK数据波动问题：财务数据与业务数据不一致，需持续关注
· 物流模块：单开发人力瓶颈，运输单等核心模块尚不完善
· 供应链AI产品经理缺位，可能拖累智能广告项目推进节奏

━━━━━━━━━━━━━━━━━
四、本周工作连续性
━━━━━━━━━━━━━━━━━
（周二 4/21）
· 智能广告规划讨论，产品经理缺位问题凸显
· 产品人员微调（向男调回产品组）
· 数织与子不语人员调整确认，430淘汰名单锁定
  - 430调整7人（产品2+研发3+数据2）
  - 520调整3人（1数据+1AI创新+1运维-陈滨楠）
  - 630调整1人（数据）
  - 合计11人淘汰计划

（周一 4/20）
· 子不语项目430淘汰名单更新
  - 数据1人调整至AI创新（商品销售计划项目）
  - 数据1人调整至630节点
· IT管理周会：TK数据波动问题，财务与业务数据不一致
· R高端数据运营正常
· CEO驾驶舱改造：需建立主动推送机制和管理流程
· 数织BI项目全面盘点

━━━━━━━━━━━━━━━━━
五、本周前期其他进展
━━━━━━━━━━━━━━━━━
· 4/19（周日）：Hermes与飞书集成问题修复完成；Codex API Key采购落地
· 4/18（周六）：工作日志从V63空间迁移至个人空间
· 4/17（周五）：项目周会、店铺/设计/品牌、数据周会、AI创新实验室周会同步推进
· 4/16（周四）：财务AI需求沟通；IT月度复盘
· 4/15（周三）：物流需求评估（国进与诗思完成需求梳理）
  - 当前仅单开发支撑物流迭代，人力瓶颈明显
  - 运输单模块需支持合并下单、FBA追踪等功能，现状不完善
  - 销售订单指派仍在ERP中，ERP卡顿，优化价值有限
· 4/14（周二）：子不语项目人员预算盘点；数织4月薪资借款方案；产品架构讨论
· 4/13（周一）：供应链商品月度复盘；子不语需求精简及人员架构调整启动

━━━━━━━━━━━━━━━━━
六、信息来源备注
━━━━━━━━━━━━━━━━━
· Notion 工作日志（页面ID: 34349d5b27068057ac62c99678af306c）
  https://www.notion.so/002-34349d5b27068057ac62c99678af306c
· Obsidian 工作日志（26子不语/0020工作日志.md）
  备注：Obsidian当日无4/22新增记录，现有内容为4/18归档（知识库结构搭建：原始资料库、gordonKB创建，周报归档及文章整理）"""

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
