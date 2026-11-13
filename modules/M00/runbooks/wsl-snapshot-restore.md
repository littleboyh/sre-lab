# Runbook：实验环境快照与重建（WSL2）

- 适用版本、触发场景、预期影响与负责人：
  - 适用：Windows 11 + WSL2 2.x，默认发行版 `Ubuntu-24.04`（内核 `6.18.26.1-microsoft-standard-WSL2`）。
  - 触发：M00 验收“从干净快照重建并比对结果”；或实验环境被改坏、需要回到已知良好状态。
  - 预期影响：导出/导入期间该发行版不可用；**不修改**原发行版；导入副本占用约 2 GB VHD。
  - 负责人：本人；本 Runbook 于 2026-11-13 首次演练（见 lab-001）。
- 权限、工具、依赖和前置检查：
  - Windows 管理员**不需要**；`wsl.exe` 在普通用户可用（导出/导入/注销本人发行版）。
  - guest 内**不需要 sudo**：基线脚本全部只读。
  - 前置检查：`wsl -l -v` 确认发行版名与状态；`Get-PSDrive D` 确认剩余空间 ≥ 5 GB（一份 tar ≈ 1.9 GB + 一份 VHD）。
  - 快照目录固定在仓库外：`D:\hqhe\WorkSpacee\sre-lab-vm\`（大文件不进 git）。
- 哪些情况需立即停止或升级：
  - `wsl --export` 报错或 tar 大小异常小（例如 < 500 MB）→ 停止，不要继续导入。
  - 导入后 `uname -a` 与原环境内核不一致 → 停止，快照不可用。
  - 清理阶段 `wsl -l -v` 出现多余的 `sre-lab-rebuild` 残留 → 先 `wsl --unregister` 再重试。

| 顺序 | 检查或操作 | 预期信号 | 分支 / 下一步 |
|---|---|---|---|
| 1 | `wsl -l -v` 记录初始发行版清单 | 与实验前一致（Ubuntu-24.04、docker-desktop） | 不一致 → 先查清来源再继续 |
| 2 | `wsl --terminate Ubuntu-24.04` | 发行版变 Stopped | 导出前必须处于停止状态，避免快照不一致 |
| 3 | `wsl --export Ubuntu-24.04 D:\hqhe\WorkSpacee\sre-lab-vm\ubuntu-24.04-base.tar` | 生成约 1.8–2.0 GB 的 tar；记录 SHA256 | 失败/过小 → 停止 |
| 4 | `wsl --import sre-lab-rebuild <VHD目录> <tar> --version 2` | 退出码 0；`wsl -l -v` 出现新发行版 | 失败 → 检查 tar 完整性与磁盘空间 |
| 5 | 在副本内跑基线：`bash modules/M00/scripts/collect-baseline.sh <证据目录>` | 生成 `00-meta` ~ `06-tools` + SHA256SUMS | 脚本报缺工具 → 正常，记录 `MISS` 即可 |
| 6 | 补宿主证据并比对：`compare-baseline.sh <原始> <副本>` | 输出 `IDENTICAL`，退出码 0 | `DIFFERENT` → 看 `fingerprint-diff.txt`，先判断是“身份字段选错”还是“真不一致” |
| 7 | 封存证据并清理：`seal-evidence.sh <目录>`；`wsl --unregister sre-lab-rebuild` | 证据有 SHA256SUMS；副本消失；`wsl -l -v` 回到第 1 步清单 | 残留 → 重试 unregister |

- 操作风险、回滚步骤与回滚触发条件：
  - 风险：误对**默认发行版**执行 `--unregister` 会删除该发行版数据（不可逆）。本 Runbook 只 unregister 临时副本 `sre-lab-rebuild`。
  - 回滚：原发行版全程只读，无需回滚；副本直接用 `wsl --unregister` 丢弃。
  - 回滚触发：副本内核/发行版与原始不一致，或导入过程被中断。
- 恢复确认指标、观察时长和退出条件：
  - `wsl -l -v` 项数回到初始值（本机为 2 项）；
  - `wsl -d Ubuntu-24.04 -- uname -a` 内核仍为 `6.18.26.1-microsoft-standard-WSL2`；
  - 观察时长：清理后立即确认一次即可。
- 升级对象及需要交接的信息：
  - 若快照损坏且原发行版也被改动：交出 tar 的 SHA256 与大小、`wsl --version`、失败命令的完整输出。
- 最近演练日期、环境与证据：
  - 2026-11-13，WSL 2.7.7.0 / Ubuntu 24.04.4；证据
    [rebuild-20261113T235603](../evidence/rebuild-20261113T235603/fingerprint.txt)、
    [device-topology-note.txt](../evidence/device-topology-note.txt)、
    [snapshot-ubuntu-2404-base.txt](../evidence/snapshot-ubuntu-2404-base.txt)。

## 关键坑位（复跑必读）

1. **PowerShell 嵌套引号**：`wsl -d X -- bash -lc "…\"$v\"…"` 的内层双引号会被吞，脚本收不到参数。
   把命令写成 `.sh` 文件、参数分开传；不要在 `-lc` 里拼引号。
2. **`wsl --version` 是 UTF-16**：直接重定向会乱码，需按 Unicode 解码后再写文件。
3. **设备节点名不稳定**：重建后 `/dev/sdd` 会变成 `/dev/sde`，不能作为身份字段。
4. **共享 utility VM**：只要另一个发行版在运行，它的 VHD 也会出现在当前发行版的 `lsblk` 里；
   比较拓扑前先 `wsl --shutdown`，或干脆不比块设备清单。
5. **快照不入 git**：1.9 GB tar 只保存在仓库外，仓库内只存路径、大小、SHA256 与命令。
