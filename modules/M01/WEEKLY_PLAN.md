# 周学习计划：M01 CPU 与进程调度

模块目标：建立"CPU 时间如何被分配、被耗尽、被限制"的心智模型，并用 **3 组可复现实验**把
「CPU 繁忙 / I/O 等待 / CPU 限流」三种高负载现象区分开，最终沉淀一份可复用的 CPU 排查 SOP。

参考周期：5 周 · 每周 6～8 小时。状态以 [进度总账](../../PROGRESS.md) 为准。

## 分工约定（本模块生效）

- **你（学习者）**：决定学什么、设计实验、动手执行、下判断、写结论。所有诊断结论由你给出。
- **我（文档辅助）**：把你的结论整理成 [THEORY.md](THEORY.md) / `experiments/lab-00X.md` / `runbooks/`；
  维护证据目录与 SHA256；更新 `PROGRESS.md`；每周生成 `reviews/week-0X.md` 草稿。
  我可以在你卡住时给**提示和检查清单**，但不代做实验判断，也不替你写"结论"。
- 每次实验结束你把原始输出/命令/判断丢给我，我当天完成归档；**证据必须可复跑**。

## 五周安排

| 周次 / 日期 | 一个可验收的目标 | 学习与实验任务 | 预计工时 | 交付物与通过标准 |
|---|---|---|---:|---|
| 第 1 周<br>11-14 ~ 11-20 | 说清 CPU 时间是怎么被分出去的 | 读：进程 vs 线程（`task_struct`/`clone`）、调度类、CFS/EEVDF（`vruntime`、权重、调度延迟）、`nice` 与权重的对应、上下文切换的分类。动手：用 `mpstat`/`pidstat`/`/proc/stat`/`/proc/<pid>/schedstat`/`/proc/pressure/cpu` 观察自己机器上的 idle 状态 | 6h | [THEORY.md](THEORY.md) 的"心智模型 + 可检验预测"两节成稿；[观测速查表](observability-cheatsheet.md) 第 1～4 节填完；能不看资料解释 CFS 如何决定下一个运行的 task |
| 第 2 周<br>11-21 ~ 11-27 | 实验 1：同样的"高 load"，两种根因 | 设计实验：空闲对照 / CPU 饱和（`stress-ng --cpu 10`）/ I/O 等待（`stress-ng --hdd` 或对 `/mnt/d` 做慢 I/O）。重点验证：**loadavg 高 ≠ CPU 忙**；用 `vmstat` 的 `r`/`b`、进程 `D` 状态、`iowait`、PSI 区分 | 7h | `experiments/lab-001-loadavg-cpu-vs-io.md` + `evidence/`；基线/实测/预期对照表；能解释"load 包含不可中断睡眠" |
| 第 3 周<br>11-28 ~ 12-04 | 实验 2：CPU 有余量却被限流 | 用 `systemd-run --user --scope -p CPUQuota=50%`（已验证可用，无需 root）限制 `stress-ng`，对比 100% / 50% / 20% 三档；采集 cgroup `cpu.stat`（`nr_throttled`、`throttled_time`）、`cpu.max`、`mpstat`、`pidstat` | 6h | `experiments/lab-002-cpu-throttling.md` + `evidence/`；给出"限流"的 2～3 个判别信号；解释 host 有余量而进程变慢的原因 |
| 第 4 周<br>12-05 ~ 12-11 | 实验 3：调度开销与 `perf` 可行性 | 量化上下文切换成本（`pidstat -w` 自愿/非自愿、`sar -w`、`/proc/schedstat`）；评估 `perf`：见下方"环境预检"。`perf` 可用则做 `perf stat`/`perf sched` 热点与调度延迟；不可用则用软件事件与 `/proc` 采样替代，并记录限制 | 7h | `experiments/lab-003-context-switch.md` + `evidence/`；"perf 可用/不可用"的结论与替代方案 |
| 第 5 周<br>12-12 ~ 12-18 | 汇总成图 + SOP + 验收预演 | 把 3 组实验的判据合成一张决策树（现象 → 假设 → 采集 → 排除 → 定位）；写 CPU 排查 SOP；按验收标准做 3 个盲测场景预演（CPU 繁忙 / I/O 等待 / 限流） | 6h | CPU 原理图（Markdown/ASCII）、`runbooks/cpu-triage.md`、SOP；三个场景都能只靠证据下结论 |

## 环境预检结论（2026-11-14 实测，规划依据）

| 能力 | 状态 | 对计划的影响 |
|---|---|---|
| `pidstat / mpstat / sar / stress-ng / taskset / chrt` | ✅ 可用 | 主体观测与施压手段齐备 |
| cgroup v2 用户委派 + `systemd-run --user --scope -p CPUQuota=` | ✅ 实测可跑通（无需 root） | 第 3 周限流实验可行 |
| `perf` | ❌ 未安装（`/usr/bin/perf`、`/usr/lib/linux-tools` 均不存在） | 第 4 周需先决策：装 or 用替代 |
| `numactl` | ❌ 未安装 | 本机只有 1 个 NUMA 节点，可跳过 |
| vCPU → 宿主逻辑核映射 | 不可见且不稳定（[M00 lab-002](../M00/experiments/lab-002-vcpu-topology.md)） | 所有结论只能用 guest 内指标，不得假设绑核 |

**`perf` 决策（第 4 周前由你决定）**：

```bash
# 方案 A：尝试安装（需你输入 sudo 密码；会拉取较新的内核 tools 包，体积较大）
sudo apt-get install -y linux-tools-common linux-tools-generic
perf --version
perf stat -e task-clock,context-switches true     # 软件事件
perf stat -e cycles,instructions true             # 硬件事件：WSL2 自定义内核大概率不支持
```

- 若硬件事件失败但软件事件可用：第 4 周用 `task-clock / context-switches / page-faults` + `perf sched`，结论仍然成立。
- 若 `perf` 整体不可用：降级为 `pidstat -w`、`sar -w`、`/proc/schedstat`、`/proc/<pid>/schedstat` 采样；
  **不降低验收要求**，但在 THEORY 中记录"环境能力缺失"及其对结论边界的影响。

## 证据与文档约定

- 每个实验一个目录：`modules/M01/evidence/<lab 名>-<时间戳>/`，内含原始输出 + `SHA256SUMS`（复用 M00 的 `seal-evidence.sh`）。
- 实验报告：`modules/M01/experiments/lab-00X-<主题>.md`（用 [实验模板](../../templates/EXPERIMENT.md)：问题/假设/步骤/结果/解释与恢复）。
- 原理笔记：`modules/M01/THEORY.md`（用 [原理模板](../../templates/THEORY.md)），第 1 周先立骨架，之后每周补。
- 周复盘：`modules/M01/reviews/week-0X.md`，我出草稿（本周做了什么/证据/被推翻的假设/下周目标），你补判断。
- 所有实验必须注明：**对照 / 唯一变量 / 采样窗口 / 恢复验证**——这是 M00 已经验证过的规矩。

## 超时与降级

- 单周超时：优先保住"本周交付物 + 证据"，削减阅读范围，不削减实验的对照与唯一变量要求。
- `perf` 不可用、WSL2 cgroup 行为异常等环境问题：记入 THEORY 的"边界与反例"，并给出替代观测方案；
  模块验收要求（区分三种高负载）不因工具缺失而放宽。

## 周末复盘

- 第 1 周末：`modules/M01/reviews/week-01.md`（我出草稿）。
- 调整触发条件：某一周实验结论无法复现、或证据链缺环 → 当周复盘调整，不拖到下周。
