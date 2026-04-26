#!/usr/bin/env python3
import urllib.request
import json

# Get Feishu token
secret = 'BspDO3FUKvCLtiil2i13g8rInmU371Ag'

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
# Report content - 2026年4月25日（周六）IT管理工作日报
# ============================================================
report = """📋 IT管理工作日报
📅 2026年4月25日（周六）

━━━━━━━━━━━━━━━━━
一、今日重点工作
━━━━━━━━━━━━━━━━━
1. 子不语信息化建设里程碑推进 ✅
   · 确认广告范围及下周详细计划
   · 智能广告六周上线目标：产品、交付、销售、研发四方联合对齐

2. 智能广告产品规划 ✅
   · 商品侧与计划侧需求沟通完成
   · 产品讨论会召开，MVP边界与上线节奏初步锁定

3. 团队管理收尾
   · Q1绩效打分 & Q2目标审核已完成
   · 人员淘汰计划按430节点稳步执行（产品2+研发3+数据2）

━━━━━━━━━━━━━━━━━
二、待办/进行中事项
━━━━━━━━━━━━━━━━━
· 子不语430节点后续：调拨提效一期（4/30上线）、调拨作业整体改造（220人天，5月中评审）
· 供应链AI项目：商品销售计划（AI创新）推进中
· TK数据波动：财务与业务数据不一致，持续跟踪
· CEO驾驶舱改造：主动推送机制尚未建立
· 物流模块人力瓶颈（单开发）：运输单等核心功能待完善

━━━━━━━━━━━━━━━━━
三、风险与关注点
━━━━━━━━━━━━━━━━━
⚠️ 智能广告PM角色仍缺位：影响六周MVP交付计划执行节奏
⚠️ 子不语调拨改造并行压力：4/30上线 + 5月中大改造，资源集中度高
⚠️ TK数据质量问题：财务与业务口径不统一，需管理机制介入

━━━━━━━━━━━━━━━━━
四、本周工作连续性
━━━━━━━━━━━━━━━━━
（周五 4/24）✅
· 智能广告六周MVP目标锁定：AI分析模块 + 存量策略参数调优
· 定价18.8万/年，核心场景：拓词分析、广告结构诊断、策略配置提效
· 职责分工：福菁（分析）、星哲（策略）、玉玲（体验定价）
· 广告范围确认，下周详细计划制定

（周四 4/23）✅
· 子不语18个月里程碑计划制定完成
· 团队Q1绩效打分 & Q2目标审核完成

（周三 4/22）✅
· 商品中心需求沟通排期确认
· 供应链AI智能广告Agent定位：面向超级运营个体的"高效"广告投放专家

（周二 4/21）✅
· 智能广告规划讨论，产品经理缺位问题凸显
· 向男调回产品组，产品人员架构微调完成

（周一 4/20）✅
· 子不语430淘汰名单更新
· IT管理周会：TK数据波动、R高端正常、CEO驾驶舱改造议题
· 数织BI项目全面盘点

━━━━━━━━━━━━━━━━━
五、本周其他重要进展
━━━━━━━━━━━━━━━━━
· 4/19：Hermes与飞书集成修复完成；Codex API Key采购落地
· 4/18：工作日志从V63空间迁移至个人Obsidian空间
· 4/17：项目周会、店铺/设计/品牌复盘、数据周会、AI创新实验室周会
· 4/16：财务AI需求沟通；IT月度复盘
· 4/15：物流需求评估（国进+诗思）；子不语架构组长沟通
· 4/14：子不语项目人员预算盘点；数织4月薪资借款方案；产品架构讨论
· 4/13：供应链商品月度复盘；子不语需求精简 & 人员架构调整启动

━━━━━━━━━━━━━━━━━
六、信息来源备注
━━━━━━━━━━━━━━━━━
· Notion 工作日志（页面ID: 34349d5b27068057ac62c99678af306c）
  https://www.notion.so/002-34349d5b27068057ac62c99678af306c
  备注：Notion最新记录为4/24（周五），今日（4/25）无新增记录
· Obsidian 工作日志（26子不语/0020工作日志.md）
  备注：Obsidian当日无4/25新增记录，现有内容为4/18归档（知识库结构搭建：原始资料库、gordonKB创建，周报归档及文章整理）"""

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
