# Service Reliability Lab

在隔离环境维护同一套服务。起点是可部署、可验证的 Go HTTP 服务，随后加入 Redis、PostgreSQL、Kafka、Kubernetes、OpenTelemetry、监控告警和自动发布。每阶段保存可重建的版本、部署说明、指标基线和相关模块证据。

| 学习阶段 | 长期项目增加什么 |
|--------|--------|
| 第一阶段 | 一个具备 CPU、内存、I/O 和网络故障开关的 Go 服务 |
| 第二阶段 | 容器化，迁移到 K8s，接入缓存、数据库、消息队列 |
| 第三阶段 | 三大遥测信号、OpenTelemetry、仪表盘、SLO |
| 第四阶段 | 事故处理、灰度发布、容量治理、自动化恢复 |
| 第五阶段 | 端到端演练、可靠性架构设计、综合评审 |

用 [设计评审](../templates/DESIGN_REVIEW.md) 记录方案取舍，按需维护 `ARCHITECTURE.md`、`OPERATIONS.md` 和 `SLO.md`。

终验：由另一人按文档从零部署；在可控流量下量化容量与依赖降级边界；验证告警对应用户影响；完成未知故障诊断与备份恢复；实测 RTO/RPO；演练发布回滚；评审每个主要架构选择的代价。将证据汇入 [M16](../modules/M16/MODULE.md) 的验收结果。
