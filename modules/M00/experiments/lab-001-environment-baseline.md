# 实验：lab-001 实验环境与系统基线

- 问题、假设与可量化预测：
  - 问题：在 Windows 11 + WSL2 上，能否建立一个**可复跑、可从快照重建、可恢复初始状态**的实验环境，并采到一份可作为后续所有性能实验参照的系统基线？
  - 假设：环境身份（内核、发行版、CPU 拓扑、内存/swap 容量、根文件系统类型、工具面）由镜像与 `.wslconfig` 决定，**重建后应完全一致**；而负载、空闲内存、计数器、NAT IP、块设备清单属于运行期状态，每次都可能不同。
  - 可量化预测：① 同一环境连续采集两次，身份指纹逐字相同；② 从导出的 tar 快照 `wsl --import` 出的新发行版，身份指纹与原始逐字相同；③ 清理副本后 `wsl -l -v` 恢复为初始两项。
- 实验环境、版本、隔离范围与停止条件：
  - 宿主 Windows 11 build 26200.9974，WSL 2.7.7.0，`.wslconfig` 限 `memory=20GB`、`processors=10`、`swap=8GB`。
  - guest：Ubuntu 24.04.4 LTS，内核 `6.18.26.1-microsoft-standard-WSL2`，x86_64，systemd 作为 PID 1，cgroup v2。
  - 隔离范围：只在 `Ubuntu-24.04` 与临时导入的 `sre-lab-rebuild` 内执行；采集脚本**只读**，不安装软件包、不改内核参数。
  - 停止条件：任一采集步骤修改了系统状态，或清理后 `wsl -l -v` 不能回到初始状态，立即停止并记为失败。
- 初始状态、负载及基线：
  - 采集时系统刚启动（`uptime` 0 分钟），处于冷缓存状态；负载 `0.12 / 0.04 / 0.01`。
  - 内存 `MemTotal=20481156 kB`（约 19.5 GiB），`SwapTotal=8388608 kB`（8 GiB），`MemAvailable≈18.8 GiB`。
  - 根文件系统 `/dev/sdd ext4`，1007 G 中已用 2.2 G；`/mnt/c`、`/mnt/d` 为 9p，分别 201 G / 732 G。

## 可重复步骤

工具：`modules/M00/scripts/` 下四个脚本，全部只读或只写证据目录。

```bash
# 0) 进入仓库（Windows 路径 D:\hqhe\WorkSpacee\sre-lab 在 WSL 中为 /mnt/d/...）
cd /mnt/d/hqhe/WorkSpacee/sre-lab

# 1) 第一次基线采集（冷启动后立即执行）
bash modules/M00/scripts/collect-baseline.sh \
     modules/M00/evidence/baseline-20261113T235410

# 2) 宿主侧版本信息（PowerShell，git 之外的大文件不涉及）
#    见 evidence/baseline-20261113T235410/07-host-windows.txt 的生成方式：
#    Get-CimInstance Win32_OperatingSystem / wsl --status / .wslconfig

# 3) 同一环境第二次采集
bash modules/M00/scripts/collect-baseline.sh \
     modules/M00/evidence/baseline-20261113T235505

# 4) 比对身份指纹（退出码 0 = 一致）
bash modules/M00/scripts/compare-baseline.sh \
     modules/M00/evidence/baseline-20261113T235410 \
     modules/M00/evidence/baseline-20261113T235505

# 5) 快照导出 → 导入 → 重建采集（详见 runbooks/wsl-snapshot-restore.md）
wsl --terminate Ubuntu-24.04
wsl --export Ubuntu-24.04 D:\hqhe\WorkSpacee\sre-lab-vm\ubuntu-24.04-base.tar
wsl --import sre-lab-rebuild D:\hqhe\WorkSpacee\sre-lab-vm\sre-lab-rebuild \
    D:\hqhe\WorkSpacee\sre-lab-vm\ubuntu-24.04-base.tar --version 2
bash modules/M00/scripts/collect-baseline.sh \
     modules/M00/evidence/rebuild-20261113T235603   # 在 sre-lab-rebuild 内执行

# 6) 原始环境 vs 重建环境比对
bash modules/M00/scripts/compare-baseline.sh \
     modules/M00/evidence/baseline-20261113T235410 \
     modules/M00/evidence/rebuild-20261113T235603

# 7) 恢复初始状态并封存证据
wsl --unregister sre-lab-rebuild
bash modules/M00/scripts/seal-evidence.sh <每个证据目录>
```

对照组与唯一变量（对“重建比对”这一组而言）：

| 组 | 环境 | 变量 |
|---|---|---|
| A | 原始 `Ubuntu-24.04` | — |
| B | 原始 `Ubuntu-24.04`，再次采集 | 时间/运行期状态 |
| C | 从 A 的 tar 快照导入的 `sre-lab-rebuild` | 镜像实例（重建） |

> 踩坑记录：在 PowerShell 里用 `wsl -d ... -- bash -lc "…\"$var\"…"` 时，内层双引号会被
> PowerShell 的原生参数传递吞掉，导致脚本收不到参数（报 `usage:`）。改为**把脚本写成文件、
> 参数分开传**，不要在 `-lc` 里嵌套引号；`wsl --version` 输出是 UTF-16，直接 `Out-File`
> 会乱码，需按 Unicode 解码。

采样窗口：每次采集在同一会话内一次性完成；`vmstat 1 5` 固定 5 个 1 秒样本，其余为瞬时快照。

## 结果

| 观测项 | 基线 A（第一次） | 实测 B（第二次） | 实测 C（快照重建） | 预期 | 原始证据 |
|---|---|---|---|---|---|
| 内核 | 6.18.26.1-microsoft-standard-WSL2 | 同 A | 同 A | 一致 | [00-meta.txt](../evidence/baseline-20261113T235410/00-meta.txt) |
| 发行版 | Ubuntu 24.04.4 LTS | 同 A | 同 A | 一致 | 同上 |
| 可见 CPU 数 | 10（`processors=10`） | 10 | 10 | 一致 | [01-cpu.txt](../evidence/baseline-20261113T235410/01-cpu.txt) |
| CPU 型号 | AMD Ryzen 7 9800X3D | 同 A | 同 A | 一致 | 同上 |
| MemTotal | 20481156 kB | 同 A | 同 A | 一致 | [02-memory.txt](../evidence/baseline-20261113T235410/02-memory.txt) |
| SwapTotal | 8388608 kB | 同 A | 同 A | 一致 | 同上 |
| 根文件系统 | ext4, `rw,relatime,discard,...` | 同 A | 同 A | 一致 | [03-disk.txt](../evidence/baseline-20261113T235410/03-disk.txt) |
| cgroup | v2（`cgroup2fs`） | 同 A | 同 A | 一致 | 00-meta.txt |
| 缺失工具 | iostat/mpstat/pidstat/sar/dig/nslookup/jq/go/stress/fio/unzip | 同 A | 同 A | 一致 | [06-tools.txt](../evidence/baseline-20261113T235410/06-tools.txt) |
| **身份指纹 A vs B** | — | **IDENTICAL** | — | 一致 | [fingerprint-diff.txt](../evidence/baseline-20261113T235505/fingerprint-diff.txt)（空） |
| **身份指纹 A vs C** | — | — | **IDENTICAL** | 一致 | [fingerprint-diff.txt](../evidence/rebuild-20261113T235603/fingerprint-diff.txt)（空） |
| 块设备清单 | 4 个设备 | 4 个 | 采集时 5 个（多 1×1T ext4） | 一致 | [device-topology-note.txt](../evidence/device-topology-note.txt) |

汇总：**环境身份可复跑（A=B）、可从快照重建（A=C）**；唯一的观测差异是块设备清单，经对照实验证明属于运行期状态，见下。

## 解释与恢复

- **支持了什么**：身份字段选择正确时，基线的“可复跑 / 可重建”可以被机器判定，而不靠目测；`compare-baseline.sh` 退出码即结论。
- **推翻了什么（重要）**：第一次 A vs C 比对结果是 `DIFFERENT`。逐字段排查后确认，**不是环境不可重建，而是指纹设计有 4 个缺陷**：
  1. 根文件系统把设备节点 `/dev/sdd` 当身份 → 重建后变成 `/dev/sde`，实际是挂载顺序属性；
  2. `grep -E "^CPU(s):"` 把 `(s)` 当正则分组，`lscpu` 的 CPU 拓扑字段**静默取空**，等于没比；
  3. 块设备清单被当成身份 → WSL2 共享 utility VM 时，别的发行版 VHD 也会挂进来；
  4. `host.wsl` 正则写成 `^W.S.L`，匹配不到 `WSL 版本:`，字段为空。
  修正为：设备节点归一化为 `<root-dev>`、`lscpu` 键用 `grep -F` 字面匹配、块设备清单移出指纹、正则改为 `^WSL`。修正后 A vs B、A vs C 均为 `IDENTICAL`。
- **块设备差异的机制（已用对照实验证实）**：执行 `wsl --shutdown` 后只启动 `sre-lab-rebuild`，`lsblk` 只有 4 个设备；再启动 `Ubuntu-24.04` 后，在 rebuild 内立刻看到第 5 个 1T ext4（Ubuntu 的 VHD）。反之在 Ubuntu 内也能看到 rebuild 的 VHD。结论：**块设备清单随“当前有哪些发行版在运行”变化，属运行期状态**，不能进身份指纹。
- **干扰因素**：采集发生在冷启动后 0 分钟，页缓存未热，`buff/cache` 与 I/O 计数偏低；`loadavg` 含 Hyper-V 与宿主调度影响；`sudo` 需要密码，`sysstat` 等工具缺失，因此本实验没有 `iostat/mpstat/sar` 数据，用 `vmstat` 与 `/proc` 替代。
- **如何恢复与清理**：`wsl --unregister sre-lab-rebuild` 删除副本；确认 `wsl -l -v` 回到 `Ubuntu-24.04` + `docker-desktop` 两项，与实验前一致。原始发行版未被修改（采集全程只读），无需回滚。
- **恢复后用什么数据确认**：清理后的发行版列表；以及 A/B/C 三份指纹与两份空 diff。
- **再次运行结果**：按上述步骤可重复得到 `IDENTICAL`；快照 sha256 与大小记录在 [snapshot-ubuntu-2404-base.txt](../evidence/snapshot-ubuntu-2404-base.txt)。

## 遗留问题

1. `sudo` 需要密码，`sysstat / fio / stress-ng / jq` 未安装 → M03（I/O）、M14（压测）前必须由本人执行一次
   `sudo apt-get install -y sysstat fio stress-ng jq` 并记录版本。
2. `processors=10` 在 8C/16T 的 9800X3D 上映射到哪些逻辑核、是否 SMT 兄弟核绑定，尚未验证 → M01 前用 `taskset` + `/proc/cpuinfo` 的 `siblings` 补测。
3. 本模块尚未做**独立验收**（需他人按 [ASSESSMENT.md](../../../ASSESSMENT.md) 给出现象与目标）。
