# CPU 观测命令 → 信号速查表（M01）

> 用途：把“命令 → 关键字段 → 能支持/排除什么判断 → 陷阱”整理成一页，供排查和验收复用。
> 填写方式：每行填一个命令/工具，**只写你实际跑过并理解了的**；不确定的不要写进来。
> 最后一列"陷阱"最重要——同一个指标在不同负载下会指向不同结论，写清它什么时候会误导你。

## 1. 全局与单核利用率

| 命令 / 工具 | 关键字段或选项 | 信号含义（看什么） | 能支持 / 排除的判断 | 陷阱 |
|---|---|---|---|---|
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |

填写提示（可删）：
- 关注：`mpstat -P ALL 1`（每 vCPU 的 `%usr/%sys/%iowait/%idle`）、`vmstat 1`（`us/sy/id/wa`）、`top`/`ps` 的 `%CPU`。
- 要回答：`%CPU` 超过 100% 意味着什么？`us` 高和 `sy` 高分别暗示什么？

## 2. 进程 / 线程级

| 命令 / 工具 | 关键字段或选项 | 信号含义（看什么） | 能支持 / 排除的判断 | 陷阱 |
|---|---|---|---|---|
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |

填写提示（可删）：
- 关注：`ps -o pid,stat,pcpu,psr,etime,wchan`、`pidstat -u -p <pid> 1`、`pidstat -t`、`/proc/<pid>/schedstat`、`/proc/<pid>/status` 的 `voluntary_ctxt_switches`。
- 要回答：进程状态 `R/S/D` 分别说明它卡在哪？`psr` 显示的 CPU 号可信度有多少（结合 M00 lab-002）？

## 3. 队列、负载与压力

| 命令 / 工具 | 关键字段或选项 | 信号含义（看什么） | 能支持 / 排除的判断 | 陷阱 |
|---|---|---|---|---|
|  |  |  |  |  |
|  |  |  |  |  |
|  |  |  |  |  |

填写提示（可删）：
- 关注：`vmstat` 的 `r`/`b`、`/proc/loadavg`、`/proc/pressure/cpu`、`/proc/pressure/io`、`/proc/schedstat`。
- 要回答：`loadavg` 的 1/5/15 分钟窗口是什么算法？它为什么把 `D` 状态也算进去？PSI 的 `some`/`full` 差别在哪？

## 4. 上下文切换与调度延迟

| 命令 / 工具 | 关键字段或选项 | 信号含义（看什么） | 能支持 / 排除的判断 | 陷阱 |
|---|---|---|---|---|
|  |  |  |  |  |
|  |  |  |  |  |

填写提示（可删）：
- 关注：`pidstat -w`（`cswch/s` 自愿、`nvcswch/s` 非自愿）、`sar -w`、`/proc/<pid>/status`、`/proc/schedstat` 的 `ttwu`/`sched_switch` 计数。
- 要回答：非自愿切换多说明什么？自愿切换多又说明什么？两者同时升高可能是哪种负载？

## 5. cgroup / CPU 配额（第 3 周）

| 命令 / 工具 | 关键字段或选项 | 信号含义（看什么） | 能支持 / 排除的判断 | 陷阱 |
|---|---|---|---|---|
|  |  |  |  |  |
|  |  |  |  |  |

填写提示（可删）：
- 关注：`systemd-run --user --scope -p CPUQuota=50%`、`cpu.max`、`cpu.stat`（`nr_throttled`、`throttled_time`、`nr_periods`、`usage_usec`）、`systemd-cgtop`。
- 要回答：`nr_throttled` 增长能证明什么？为什么 `mpstat` 看到宿主机/guest 有余量，被限进程仍然变慢？

## 6. perf（第 4 周，视是否安装）

| 命令 / 工具 | 关键字段或选项 | 信号含义（看什么） | 能支持 / 排除的判断 | 陷阱 |
|---|---|---|---|---|
|  |  |  |  |  |
|  |  |  |  |  |

填写提示（可删）：
- 先确认能力边界：软件事件 `perf stat -e task-clock,context-switches,page-faults true`；硬件事件 `-e cycles,instructions`（WSL2 大概率不支持）。
- 若不可用：替代方案 `pidstat -w`、`sar -w`、`/proc/schedstat` 采样——写进"陷阱"或单独备注。

## 待验证清单（每验证一条就勾掉并补证据链接）

- [ ] `loadavg` 高 ≠ CPU 忙：用 `vmstat` 的 `r`/`b` 与 `%iowait` 拆开两种成因
- [ ] `%CPU` 与 `psr` 的关系，以及为什么不能靠 `psr` 推断宿主核
- [ ] 自愿 / 非自愿上下文切换的判别阈值
- [ ] `nr_throttled` / `throttled_time` 能区分"限流"与"算力不足"
- [ ] PSI `cpu` 与 `iowait` 同时升高的场景

## 备注

- 本机限制：guest 10 vCPU（`.wslconfig processors=10`）；vCPU→宿主映射不可见（[M00 lab-002](../M00/experiments/lab-002-vcpu-topology.md)）。
- 证据归档：每次用速查表采集的原始输出放到 `modules/M01/evidence/<实验名>-<时间戳>/`，并跑 `seal-evidence.sh` 生成 SHA256SUMS。
