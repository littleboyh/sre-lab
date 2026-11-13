# M07 Kubernetes

参考周期：8 周 · 每周 6～8 小时。状态以 [进度总账](../../PROGRESS.md) 为准。

## 输入 / 前提

M06；可重建的本地集群。

## 必学内容

 API Server、etcd、Scheduler、Controller、Kubelet、CNI、CSI、DNS、HPA、探针与资源管理。

## 输出 / 交付物

可运行的实验集群、部署模板、集群故障排查手册。记录版本与证据链接，确保能再次运行。

## 学习与实验任务

- [ ] 从 [周计划](../../templates/WEEKLY_PLAN.md) 拆出本模块的周目标。
- [ ] 用 [原理笔记](../../templates/THEORY.md) 写下机制、预测与适用边界。
- [ ] 在隔离环境完成实验：分别演练请求资源无法调度、探针配置错误和测试服务解析异常；从事件回溯到组件。
- [ ] 对照实验前后指标，保存数据并记录恢复验证。
- [ ] 整理交付物与可复用排查步骤；安排独立验收。

## 必过的模块验收

独立定位 Pod Pending、CrashLoopBackOff、OOMKilled、网络及存储异常。验收者只给现象和目标；记录假设、排除依据、操作与恢复证据。按 [统一验收标准](../../ASSESSMENT.md) 评分，将 [验收结果](../../templates/ASSESSMENT_RESULT.md) 存入 `assessment/RESULT.md`，再更新总账。
