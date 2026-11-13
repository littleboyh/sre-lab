# 周复盘：M00 第 1 周（2026-11-13）

- 本周目标、计划工时与实际工时：
  - 目标：实验环境可用 + 采集第一份可复跑基线。
  - 计划 4h；实际约 2h（含快照重建比对，原计划第 2 周的内容已提前完成）。
- 完成交付与证据链接：
  - 采集/指纹/比对/封存脚本：[`scripts/`](../scripts/)
  - 基线 A（冷启动首次）：[baseline-20261113T235410](../evidence/baseline-20261113T235410/00-meta.txt)
  - 基线 B（同环境复采）：[baseline-20261113T235505](../evidence/baseline-20261113T235505/00-meta.txt)
  - 快照重建 C：[rebuild-20261113T235603](../evidence/rebuild-20261113T235603/fingerprint.txt)
  - 实验报告：[lab-001-environment-baseline](../experiments/lab-001-environment-baseline.md)
  - 恢复 Runbook：[wsl-snapshot-restore](../runbooks/wsl-snapshot-restore.md)
- 用自己的话说明学会了什么：
  1. 基线要拆成“身份 + 噪声”。身份字段（内核、发行版、资源配额、根文件系统类型、工具面）稳定可比；噪声（loadavg、free、计数器、NAT IP、块设备清单）不能进比对，否则重建成功会被误判为失败。
  2. WSL2 里 guest 看到的 20 GB / 10 vCPU 是 `.wslconfig` 给**配额**，不是宿主硬件（宿主 8C/16T、31.1 GB）。以后说“机器不够用”必须先分清是配额还是宿主。
  3. WSL2 的多个发行版共享 utility VM，块设备清单会随“谁在运行”变化——这条是靠 `wsl --shutdown` 对照实验证出来的，不是猜的。
  4. 工具链有坑要写进 Runbook：PowerShell 嵌套引号会吞参数，`wsl --version` 是 UTF-16。
- 被推翻的假设及证据：
  - 假设“从快照重建后指纹应一致”第一次被判 `DIFFERENT`。逐字段排查后发现是**指纹设计缺陷**而非环境问题：设备节点 `/dev/sdd→sde`、`lscpu` 正则把 `(s)` 当分组导致字段静默为空、块设备清单混入运行期状态、`^W.S.L` 匹配不到 `WSL 版本`。修正后 A=B、A=C 均 `IDENTICAL`。
- 未解决的问题与阻塞：
  1. `sudo` 需要密码，`sysstat / fio / stress-ng / jq` 无法安装 → M03、M14 前必须补齐。
  2. `processors=10` 与 9800X3D 的 16 个逻辑核如何映射（是否 SMT 兄弟核）未验证 → M01 前补测。
  3. 尚未做独立验收（需他人按 [ASSESSMENT.md](../../../ASSESSMENT.md) 出题）。
- 下周最重要的目标、交付与完成条件：
  - 目标：补齐工具链 + 验证 vCPU 映射 + 准备独立验收。
  - 完成条件：`sysstat/fio/stress-ng` 版本入库并复采基线；`taskset` 验证结论写入 THEORY；`assessment/RESULT.md` 就绪待验收。
- 是否已更新 PROGRESS.md：已更新（M00 → 进行中，证据路径已填）。
