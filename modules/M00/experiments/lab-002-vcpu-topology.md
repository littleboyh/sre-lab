# 实验：lab-002 vCPU 拓扑与宿主映射

- 问题、假设与可量化预测：
  - 问题：`.wslconfig processors=10` 在 8C/16T 的 Ryzen 7 9800X3D 上究竟暴露什么 CPU 拓扑？guest 的 10 个 vCPU 与宿主 16 个逻辑核之间是否存在**稳定 1:1 映射**？
  - 假设 A（拓扑）：guest 会把 10 个 vCPU 呈现为 5 个物理核 × 2 个 SMT 线程。
  - 假设 B（映射）：每个 vCPU 固定绑定到宿主的某个逻辑核。
  - 可量化预测：若 B 成立，用 `taskset -c N` 把单个 busy 线程钉在 guest 的某个 vCPU 时，**宿主同一个逻辑核**应持续出现高利用率；若 B 不成立，抬升的宿主逻辑核应在采样间漂移。
- 实验环境、版本、隔离范围与停止条件：
  - guest：Ubuntu 24.04.4，内核 `6.18.26.1-microsoft-standard-WSL2`，`.wslconfig processors=10`（宿主 8C/16T）。
  - 测量：guest 侧 `taskset` 钉核 + `stress-ng --cpu 1 --timeout 20s`；宿主侧每秒采样 `\Processor(*)\% Processor Time`（16 个逻辑核）。
  - 隔离：只跑 1 个 busy 线程，20 秒自动结束；不修改任何配置。
  - 停止条件：stress-ng 未按 timeout 退出（立即 `pkill`），或采样器持续失败。
- 初始状态、负载及基线：空载时宿主无逻辑核利用率 ≥40%（3 次采样 hot=0，Top 值 8%～23%，属桌面背景噪声）。

## 可重复步骤

```bash
# 1) guest 侧拓扑探针（只读）
bash modules/M00/scripts/probe-vcpu.sh modules/M00/evidence/vcpu-topology-<ts>.txt

# 2) 宿主侧逐核采样（PowerShell 片段）
#    空载采样 3 次；然后分别钉住 guest vCPU 0 / vCPU 5 各 20s，每秒采 8 次：
#    Get-Counter '\Processor(*)\% Processor Time' -SampleInterval 1 -MaxSamples 1
#    （完整采样脚本与输出见 evidence/vcpu-mapping-note.txt 的头注释）
```

对照组：空载 vs 钉住 cpu0 vs 钉住 cpu5；唯一变量是“被钉住的 guest vCPU”。

## 结果

| 观测项 | 实测 | 预期（若 B 成立） |
|---|---|---|
| guest CPU 总量 | `CPU(s): 10`，`Thread(s) per core: 2`，`Core(s) per socket: 5`，`Socket(s): 1` | — |
| SMT 兄弟核 | `0-1`、`2-3`、`4-5`、`6-7`、`8-9`；apicid 0～9，`siblings: 10` | 支持假设 A |
| cpuset | `/sys/fs/cgroup/cpuset.cpus.effective = 0-9` | — |
| taskset 生效范围 | 默认 `0-9`；`-c 0,1` → `0-1`；`-c 9` → `9` | guest 内可控 |
| 空载基线 | `hot>=40%:0`（3/3 次） | — |
| 钉住 vCPU 0 | 抬升逻辑核逐次漂移：`{13,2,12,0}` → `{0,2}` → `{2}` → `{1,3}` → `{1,3,2}`… | 应固定为同一个核 |
| 钉住 vCPU 5 | 抬升逻辑核逐次漂移：`{2,1,13,0}` → `{2,12,0}` → `{1,3,12}` → `{2,12,13}`… | 应固定为同一个核 |

原始证据：[vcpu-topology-20261114T102342.txt](../evidence/vcpu-topology-20261114T102342.txt)、
[vcpu-mapping-note.txt](../evidence/vcpu-mapping-note.txt)。

## 解释与恢复

- **支持**：假设 A 成立——guest 看到的是 5 核 × 2 线程的 SMT 拓扑，`taskset` 在 guest 内能正确收紧 `Cpus_allowed_list`。
- **推翻**：假设 B 不成立——钉住同一个 guest vCPU 时，宿主被抬升的逻辑核在采样间不断变化（cpu0 观测到 13/2/12/0/1/3；cpu5 观测到 2/1/12/13/0/3），且两个不同 vCPU 点亮的是**重叠**的宿主集合。说明 vCPU 由宿主调度器动态放置，**不存在对 guest 可见的固定 1:1 绑定**。
- 干扰因素：采样间隔 1 秒、桌面背景负载（空载 Top 也有 8%～23%）、WSL 自身服务与采样进程本身的开销；因此判读依据是“相对抬升 + 是否漂移”，不是绝对进度。更严格的核级关联需要停掉其他工作负载并使用更高频采样，超出 M00 范围。
- **对 M01 的直接约束**：CPU 争用/限流实验必须在 guest 内用 `taskset`、`nice`、cgroup（`cpu.max`）施加控制，并只用 guest 侧指标（`/proc/stat`、`vmstat`、`pidstat`、`stress-ng --metrics`）下结论；**不得假设**某个 guest vCPU 对应某个宿主逻辑核，也不要试图用“宿主那个核忙”来证明 guest 现象。
- 恢复：stress-ng 均按 20s 超时自动退出；实验后 `pgrep -a stress-ng` 返回 `none`，无残留进程，无需清理。
- 再次运行结果：拓扑探针幂等；映射观测的“漂移”形态可复现（两次运行都未出现固定核）。
