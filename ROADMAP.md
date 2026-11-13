# 学习路线

每周 6～8 小时，基础工作量 92 周。另留复习、补考与中断缓冲，日历周期建议 24～30 个月。以验收决定推进。

## 阶段 1：操作系统与计算机基础（28 周）

| 模块 | 周 | 输入与学习内容 | 交付 | 验收 |
|---|---:|---|---|---|
| [M00 学习系统与实验环境](modules/M00/MODULE.md) | 2 | 输入：WSL2、Linux、Git。学习实验隔离、环境管理、系统基线、文档规范 | 实验环境、Git 仓库、环境基线、实验模板 | 能重新搭建环境、执行基线采集、可靠恢复初始状态 |
| [M01 CPU与进程调度](modules/M01/MODULE.md) | 5 | 进程/线程、调度器、Run Queue、Load Average、上下文切换、CPU throttling、perf | CPU 原理图、3组性能实验、CPU排查SOP | 不看答案，独立区分 CPU 繁忙、I/O 等待、CPU 限流 |
| [M02 内存与内核资源](modules/M02/MODULE.md) | 5 | 虚拟内存、页表、Page Cache、Swap、Slab、OOM、PSI、cgroup | 内存实验、OOM证据、内存诊断手册 | 区分内存泄漏、缓存增长、容器内存受限，解释证据 |
| [M03 存储与 I/O](modules/M03/MODULE.md) | 5 | VFS、文件系统、inode、fd、fsync、Writeback、块设备、磁盘延迟与队列 | fio 测试报告、I/O分析报告、恢复脚本 | 能判断磁盘空间、FD、IOPS、吞吐或延迟瓶颈 |
| [M04 Linux 网络](modules/M04/MODULE.md) | 6 | TCP/IP、DNS、Socket、连接队列、重传、拥塞控制、NAT、conntrack、抓包 | 网络故障实验、pcap、网络排查SOP | 独立定位 DNS、连接失败、丢包或重传等网络问题 |
| [M05 编程与工程诊断](modules/M05/MODULE.md) | 5 | 输入：上述基础。学习 Go、Shell、Git、单元测试、并发、pprof、自动化 | 一个带故障开关的 Go 服务、测试脚本、性能分析报告 | 能修改程序、构建测试、定位其性能问题并自动验证 |

## 阶段 2：容器、Kubernetes 与分布式系统（19 周）

| 模块 | 周 | 输入与学习内容 | 交付 | 验收 |
|---|---:|---|---|---|
| [M06 容器原理](modules/M06/MODULE.md) | 4 | 输入：Linux 基础。学习 Namespace、cgroup v2、OCI、OverlayFS、容器网络、资源限制 | 容器运行原理图、CPU/内存隔离实验 | 能说明容器与宿主机的关系，复现 CPU 限流与 OOM |
| [M07 Kubernetes](modules/M07/MODULE.md) | 8 | 输入：容器基础。学习 API Server、etcd、Scheduler、Controller、Kubelet、CNI、CSI、DNS、HPA、探针与资源管理 | 可运行的实验集群、部署模板、集群故障排查手册 | 独立定位 Pod Pending、CrashLoopBackOff、OOMKilled、网络及存储异常 |
| [M08 分布式系统](modules/M08/MODULE.md) | 7 | 输入：Go、K8s。学习一致性、复制、选主、幂等、超时、重试、背压，以及 Kafka、Redis、PostgreSQL、ClickHouse、对象存储 | 一条可靠数据处理流水线、系统依赖图、故障注入报告 | 解释数据重复、丢失、延迟和一致性问题，并证明恢复机制有效 |

## 阶段 3：可观测性与可靠性工程（17 周）

| 模块 | 周 | 输入与学习内容 | 交付 | 验收 |
|---|---:|---|---|---|
| [M09 可观测性基础设施](modules/M09/MODULE.md) | 6 | 输入：K8s、Go服务。学习 USE/RED、Metrics、Histogram、Prometheus、VictoriaMetrics、Grafana、日志、Traces | 完整监控看板、指标规范、基础告警 | 能用可观测数据证明服务状态，避免高基数问题，准确识别性能退化 |
| [M10 OpenTelemetry 工程](modules/M10/MODULE.md) | 6 | 输入：M09。学习 API/SDK、Context、Propagation、OTLP、Collector、采样、队列、重试、WAL、背压 | 多服务 Trace、Collector 管线、可靠性实验报告 | 下游持续失败时，能量化队列、内存、重试和丢数据边界 |
| [M11 SLO与告警工程](modules/M11/MODULE.md) | 5 | 输入：服务指标与用户请求数据。学习 SLI、SLO、错误预算、Burn Rate、多窗口告警 | SLO文档、错误预算看板、告警规则 | 能计算服务可靠性、解释预算消耗，并验证告警是否有效 |

## 阶段 4：生产工程与稳定性治理（20 周）

| 模块 | 周 | 输入与学习内容 | 交付 | 验收 |
|---|---:|---|---|---|
| [M12 故障响应与复盘](modules/M12/MODULE.md) | 5 | 输入：告警系统。学习事故分级、On-call、止损、应急指挥、时间线、Postmortem | 3份完整事故演练记录、Runbook、行动项清单 | 面对未知故障能控制影响、恢复服务、分析原因并验证改进 |
| [M13 发布与自动化工程](modules/M13/MODULE.md) | 5 | 输入：K8s、Git。学习 CI/CD、IaC、Ansible/Terraform、GitOps、灰度发布、回滚 | 完整部署流水线、变更控制、回滚演练 | 从代码提交到部署可追溯，错误版本可安全回滚 |
| [M14 容量、性能与容灾](modules/M14/MODULE.md) | 6 | 输入：监控及负载数据。学习排队理论、容量预测、压测、性能优化、备份与恢复、RTO/RPO | 容量评估、性能报告、备份恢复演练 | 能计算安全容量并实测恢复时间与数据损失窗口 |
| [M15 安全与平台治理](modules/M15/MODULE.md) | 4 | 输入：K8s和发布环境。学习 RBAC、NetworkPolicy、TLS、Secret、镜像安全、配置审计 | 威胁模型、安全基线、最小权限规范 | 未授权访问被阻断，配置可审计，修复措施可验证 |

## 阶段 5：综合架构与专家级实战（8 周）

| 模块 | 周 | 输入与学习内容 | 交付 | 验收 |
|---|---:|---|---|---|
| [M16 综合架构与专家级实战](modules/M16/MODULE.md) | 8 | 输入：M00～M15 的成果与运行数据。学习架构取舍、端到端压测、故障演练、恢复与技术评审 | 架构设计、SLO、容量评估、部署回滚、演练报告与运维文档 | 从零部署与恢复可复现；量化高并发及依赖故障边界；独立盲测；由他人按文档接手 |