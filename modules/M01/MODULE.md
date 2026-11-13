# M01 CPU与进程调度

参考周期：5 周 · 每周 6～8 小时。状态以 [进度总账](../../PROGRESS.md) 为准。

## 输入 / 前提

M00 基线；Linux 进程观测工具。

## 必学内容

进程/线程、调度器、Run Queue、Load Average、上下文切换、CPU throttling、perf。

## 输出 / 交付物

CPU 原理图、3组性能实验、CPU排查SOP。记录版本与证据链接，确保能再次运行。

## 学习与实验任务

- [ ] 从 [周计划](../../templates/WEEKLY_PLAN.md) 拆出本模块的周目标。
- [ ] 用 [原理笔记](../../templates/THEORY.md) 写下机制、预测与适用边界。
- [ ] 在隔离环境完成实验：比较计算饱和、I/O 等待和 CPU 配额限制；记录进程、队列与配额指标。
- [ ] 对照实验前后指标，保存数据并记录恢复验证。
- [ ] 整理交付物与可复用排查步骤；安排独立验收。

## 必过的模块验收

不看答案，独立区分 CPU 繁忙、I/O 等待、CPU 限流。验收者只给现象和目标；记录假设、排除依据、操作与恢复证据。按 [统一验收标准](../../ASSESSMENT.md) 评分，将 [验收结果](../../templates/ASSESSMENT_RESULT.md) 存入 `assessment/RESULT.md`，再更新总账。
