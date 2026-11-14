# 原理笔记：M00 实验环境与系统基线

- 要回答的问题：
  1. 在 Windows + WSL2 上，“实验环境”到底是什么？哪些资源是虚拟的、边界在哪里？
  2. 一份**可复跑**的系统基线应该采什么、哪些字段是身份、哪些是噪声？
  3. 怎样证明环境“可重建、可恢复”，而不是偶然能跑？
- 环境与版本：
  - 宿主 Windows 11 build 26200.9974，WSL 2.7.7.0
  - guest Ubuntu 24.04.4 LTS，内核 `6.18.26.1-microsoft-standard-WSL2`，x86_64
  - `.wslconfig`：`memory=20GB`、`processors=10`、`swap=8GB`、`autoMemoryReclaim=gradual`

## 心智模型

三层结构，边界逐层虚拟化：

```
Windows 宿主（8C/16T，31.1 GB，真实磁盘）
  └─ WSL2 轻量 VM（Hyper-V，vCPU=10，vMem=20 GB，swap 文件 8 GB）
       └─ Ubuntu 用户空间（systemd 作为 PID 1）
            ├─ /        → /dev/sdd ext4，位于动态 VHD（1 TB 稀疏，实际 2.2 GB）
            └─ /mnt/c、/mnt/d → 9p 网络文件系统（不是本地磁盘 I/O）
```

由此推出三条对后续所有实验都成立的结论：

1. **guest 看到的容量是配额，不是硬件。** guest 的 20 GB 内存来自 `memory=20GB`，10 个 CPU 来自 `processors=10`；换算成宿主要乘以虚拟化开销。M01/M02 讨论“机器不够用”时必须先问：不够的是 guest 配额，还是宿主真资源？
2. **`/` 与 `/mnt/*` 的 I/O 语义不同。** 前者走 ext4→VHD→宿主磁盘，后者走 9p。M03 的 fio 测试若落在 `/mnt/d`，测到的是 9p 协议开销，不能代表磁盘能力。
3. **基线 = 身份字段 + 运行时状态。** 身份字段应稳定：内核、发行版、CPU 拓扑、MemTotal/SwapTotal、根文件系统类型、cgroup 版本、工具面、宿主/WSL 版本。运行时状态必然波动：loadavg、free/vmstat、各类计数器、NAT 分配的 IP。**比对时只能比身份，不能比噪声**，否则“重建成功”会被误判成失败。

可重建性的检验标准只有一条：同一套采集脚本，在“原环境再跑一次”和“从快照重建的新环境”上，**身份指纹完全一致**。

## 可检验预测

| 改变什么 | 预期现象 | 观测信号 | 什么会推翻预测 |
|---|---|---|---|
| 同一环境连续采集两次 | 身份指纹完全一致 | `compare-baseline.sh` 退出码 0 | 出现字段差异 → 说明指纹混入了易变项（如 NAT IP、loadavg） |
| 从导出的快照 `wsl --import` 新发行版并重跑基线 | 身份指纹与原始一致 | `fingerprint.txt` diff 为空 | 内核/CPU/内存/工具面不同 → 快照不完整或采集脚本不幂等 |
| 修改 `.wslconfig` 的 `memory` 后重启 WSL | guest `MemTotal` 随之变化 | `/proc/meminfo` 的 `MemTotal`、`free -m` | 仍为 20 GB → 配置未生效（需 `wsl --shutdown`） |
| 在 `/mnt/d` 上做顺序写 | 吞吐/延迟明显劣于根文件系统 | M03 的 fio、`iostat`、`/proc/diskstats` | 若两者接近 → 9p 缓存或页缓存干扰了测量 |
| 采集脚本在 `set -u` 下遇到缺失工具 | 整次采集中止 | 证据目录缺文件 | 若只记录 `MISS` 继续运行 → 说明脚本做了降级处理（当前实现即如此） |

## 边界与反例

- **同一症状的其他解释**：
  - `free -m` 的 `used` 偏低、`buff/cache` 偏高 ≠ 内存浪费；Linux 会主动用空闲内存做缓存，判断内存压力应看 `MemAvailable` 与 PSI。
  - WSL 的 `loadavg` 混入了 Hyper-V 与宿主调度的影响，不能直接当宿主负载读。
  - `df` 里 1 TB 的 `/dev/sdd` 是 VHD 的**最大**容量，稀疏分配，真实占用看 `Used`（2.2 GB）。
- **哪些版本/配置会改变结论**：
  - WSL 版本升级（本次 2.7.7.0）、内核升级（6.18.26.1）都会改变 `uname` 与工具面；
  - `.wslconfig` 的 `memory/processors/swap`、`autoMemoryReclaim=gradual` 直接影响 M02 的内存回收实验；
  - Docker Desktop（`docker-desktop` 发行版存在）与 Tailscale（DNS `search tail3eef43.ts.net`）会引入额外进程、监听端口与 DNS 行为，属于基线噪声源。
- **已证实（2026-11-14，[lab-002](experiments/lab-002-vcpu-topology.md)）**：guest 呈现 5 核 × 2 SMT 线程（兄弟核 0-1/2-3/4-5/6-7/8-9，apicid 0～9）；`taskset` 在 guest 内可正确收紧亲和性；但 **vCPU → 宿主逻辑核的映射不可见且不稳定**——钉住单个 vCPU 时，宿主抬升的逻辑核在采样间漂移。因此 M01 不得假设 1:1 绑定。
- **尚未证实的推测**：
  - 9p 是否对 `/mnt/d` 的 `fsync` 语义有额外放大，需在 M03 实测。

## 证据与参考

| 来源 | 支持什么结论 |
|---|---|
| [baseline-20261113T235410](../evidence/baseline-20261113T235410/00-meta.txt)（冷启动 0 分钟，第一次） | 身份字段首次落库；本次基线的主证据 |
| [baseline-20261113T235505](../evidence/baseline-20261113T235505/00-meta.txt)（同会话第二次） | 两次采集身份指纹一致 → 基线可复跑 |
| [fingerprint-diff.txt](../evidence/baseline-20261113T235505/fingerprint-diff.txt)（空 diff） | “IDENTICAL”的机器可读证据 |
| [07-host-windows.txt](../evidence/baseline-20261113T235410/07-host-windows.txt) | 宿主 8C/16T、31.1 GB、`.wslconfig` 配额，解释 guest 资源来源 |
| 实验报告 [lab-001-environment-baseline](../experiments/lab-001-environment-baseline.md) | 完整步骤、结果与恢复验证 |
| [vcpu-topology-20261114T102342.txt](../evidence/vcpu-topology-20261114T102342.txt)、[vcpu-mapping-note.txt](../evidence/vcpu-mapping-note.txt) | guest 拓扑为 5C×2T；vCPU→宿主映射不稳定（lab-002） |
| [lab-002-vcpu-topology](../experiments/lab-002-vcpu-topology.md) | 上述拓扑与映射结论的完整实验记录 |
