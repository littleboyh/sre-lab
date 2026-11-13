# SRE Expert Learning System

一套以实验和独立验收驱动的长期学习仓库：5 个阶段、17 个模块、1 个贯穿全程的实战项目。建议每周 6～8 小时，按 24～30 个月规划。先打开 [M00 任务书](modules/M00/MODULE.md)，建立能重建、能回滚的实验环境。

## 文件分工

| 文档 | 用途 | 是否复制 / 更新节奏 |
|---|---|---|
| README.md | 仓库使用说明与归档约定 | 主文件；流程改变时更新 |
| [ROADMAP.md](ROADMAP.md) | 各模块周期、输入、交付与验收 | 主文件；按季度审查 |
| [ASSESSMENT.md](ASSESSMENT.md) | 统一能力等级、评分和通过门槛 | 主文件；保持标准稳定 |
| [PROGRESS.md](PROGRESS.md) | 学习状态、分数与下一步 | 主文件；每周及验收后更新 |
| modules/M00～M16/MODULE.md | 各模块的任务书与关卡 | 每模块已预填；开学时细化实验 |
| [capstone/README.md](capstone/README.md) | 实战项目目标、阶段交付和终验 | 项目主文件；按里程碑更新 |
| templates/ | 可重复复制的学习记录 | 原件保留；按下表生成记录 |

| 模板 | 何时用 | 建议保存位置 |
|---|---|---|
| [THEORY.md](templates/THEORY.md) | 写原理、适用边界与证据；每模块持续维护一份 | `modules/Mxx/THEORY.md` |
| [WEEKLY_PLAN.md](templates/WEEKLY_PLAN.md) | 模块开学时拆分周目标；每周调整预计投入和交付 | `modules/Mxx/WEEKLY_PLAN.md` |
| [EXPERIMENT.md](templates/EXPERIMENT.md) | 每个独立技术实验复制一份，用于验证假设 | `modules/Mxx/experiments/lab-001.md` |
| [WEEKLY_REVIEW.md](templates/WEEKLY_REVIEW.md) | 每周复制一份，检查产出、理解差距和下周安排 | `modules/Mxx/reviews/week-01.md` |
| [INCIDENT.md](templates/INCIDENT.md) | 每次正式故障演练复制一份，记录影响、响应与改进 | `modules/Mxx/incidents/incident-001.md` |
| [RUNBOOK.md](templates/RUNBOOK.md) | 每类可重复处理的问题复制一份，供值班演练使用 | `modules/Mxx/runbooks/topic.md` |
| [ASSESSMENT_RESULT.md](templates/ASSESSMENT_RESULT.md) | 每模块一份，记录得分、证据与补考历史 | `modules/Mxx/assessment/RESULT.md` |
| [DESIGN_REVIEW.md](templates/DESIGN_REVIEW.md) | 每次主要架构决策或阶段评审复制一份 | `capstone/reviews/design-001.md` |

模块目录按需增加子目录。把指标、日志、抓包、截图等原始证据放在 `evidence/`，注明采集条件与时间，链接到实验或验收记录。比如 M01 用 THEORY 解释高 Load 的不同原因，实验对照数据，Runbook 写出排查顺序，RESULT 记录独立诊断表现。

## 如何持续推进

1. 对照路线与任务书选一个周目标，复制周计划模板并写出可检查的交付物。
2. 原理学习后先预测结果，再做实验，保存基线、变量、结果与恢复记录。
3. 每周复盘并更新进度；每两周做一次无提示诊断；每月检查薄弱点，每季度做跨模块实战，每半年重评能力地图。
4. 模块结束后按统一标准验收；未通过则补练并复测，通过再进入依赖它的模块。每阶段把成果合入长期项目。
