# 原理笔记：M01 CPU 与进程调度

> 填写方式：每节先写自己的理解，再补证据链接。**不确定的地方写“推测”，不要写成结论**——
> 后面实验结果会逐条检验。我（文档辅助）负责在你给出内容后做结构调整与交叉引用，不代写判断。

- 要回答的问题：
  1. 进程和线程在内核里如何被表示与调度？（`task_struct`、`clone`、调度实体、调度类）
  2. CFS/EEVDF 如何决定“下一个跑谁”？`vruntime`、权重、`nice`、调度延迟各自起什么作用？
  3. 上下文切换何时发生？自愿切换与非自愿切换的成因与代价分别是什么？
  4. Run Queue 长度、`loadavg`、PSI、`iowait` 各自度量什么？哪些指标会“骗人”？
  5. cgroup CPU 配额（throttling）在内核里如何实现？为什么“宿主还有余量，进程却变慢”？
- 环境与版本：
  - Windows 11 build 26200 + WSL 2.7.7.0；guest Ubuntu 24.04.4，内核 `6.18.26.1-microsoft-standard-WSL2`
  - `.wslconfig`：`memory=20GB`、`processors=10`、`swap=8GB` → guest 可见 10 vCPU（合成 5C×2T）
  - cgroup v2（unified），用户委派可用；`perf` 尚未安装（第 4 周决策）
  - 关键约束：vCPU → 宿主逻辑核映射**不可见且不稳定**（[M00 lab-002](../M00/experiments/lab-002-vcpu-topology.md)），
    因此本模块所有结论只能用 **guest 内指标**，不得假设绑核

## 心智模型

（待填）用自己的话写出链路，建议配一张 ASCII 图：

```
用户态进程/线程
   └─ 调度实体（sched_entity / task）
        └─ 运行队列（per-CPU rq）
             └─ 调度器选择（CFS/EEVDF：vruntime 最小 / 调度延迟）
                  └─ 上下文切换（switch_to）→ CPU 执行
```

需要说清的三件事（待填）：
- 任务状态如何迁移：就绪（R）→ 运行（R）→ 睡眠（S/D）→ 被唤醒后进入哪个队列？
- “被唤醒”到“真正拿到 CPU”之间会发生什么判断？`wakeup_preempt`、`need_resched` 在何时生效？
- `nice` 值如何变成权重？权重差异在 CPU 竞争时具体表现为什么比例？

## 可检验预测

> 至少写 3 行，覆盖 **CPU 饱和 / I/O 等待 / CPU 配额限制** 三类场景；每行都要写“什么会推翻它”，
> 否则实验只是在确认自己。

| 改变什么 | 预期现象 | 观测信号 | 什么会推翻预测 |
|---|---|---|---|
| *（示例行，可删）把 vCPU 用 `stress-ng --cpu 10` 跑满* | *loadavg 上升，CPU 利用率上升，等待时间不变* | *`vmstat` 的 `r` 与 `us`；`mpstat -P ALL` 的 `%usr`* | *若 `wa` 同时显著上升 → 高负载另有 I/O 成因* |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

## 边界与反例

- 同一症状的其他解释（待填）：
  - 例：`loadavg` 高但 CPU 空闲，还有哪些可能？（至少写 2 种，并说明用什么信号排除）
- 哪些版本、配置或负载会改变结论（待填）：
  - 提示：内核版本（EEVDF 从 6.6 起替代 CFS 的选核逻辑）、`processors=10` 的配额、WSL2 虚拟化开销、`autoMemoryReclaim`
- 尚未证实的推测（待填）：
  - 把你暂时无法验证的想法放这里，后面实验能验证的移到上表

## 证据与参考

| 来源 | 支持什么结论 |
|---|---|
| [M00 基线 D](../M00/evidence/baseline-20261114T102254/00-meta.txt) | 本模块的机器基线（10 vCPU / 20 GB / cgroup v2） |
| [M00 lab-002 vCPU 拓扑](../M00/experiments/lab-002-vcpu-topology.md) | vCPU→宿主映射不可见，只能用 guest 指标 |
| `experiments/lab-001-loadavg-cpu-vs-io.md` | （第 2 周创建）CPU 饱和 vs I/O 等待 |
| `experiments/lab-002-cpu-throttling.md` | （第 3 周创建）配额限制的判别信号 |
| `experiments/lab-003-context-switch.md` | （第 4 周创建）切换代价与调度延迟 |
| 内核文档 / 源码 | （待填：补充你实际读过的章节与版本，例如 `Documentation/scheduler/`） |
