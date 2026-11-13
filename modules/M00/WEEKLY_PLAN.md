# 周学习计划：M00 学习系统与实验环境

模块目标：把“学习仓库 + 实验环境 + 系统基线”三者跑通，做到**可复跑、可重建、可恢复**。
优先级：先把环境身份钉死（版本、资源边界、工具面），再谈性能数据；没有可信基线，后续模块的实验结论都不可信。

| 周次 / 日期 | 一个可验收的目标 | 原理与实验任务 | 预计工时 | 交付物与通过标准 |
|---|---|---|---|---|
| 第 1 周<br>2026-11-13 ~ 11-19 | 实验环境可用，采集第一份可复跑基线 | ① 盘点宿主与 WSL2 版本、资源边界；② 写只读基线脚本；③ 连续两次采集，比较“环境指纹” | 4h | `scripts/collect-baseline.sh` + 两份 `evidence/baseline-*`；`compare-baseline.sh` 输出 `IDENTICAL`；`fingerprint.txt` 入库 |
| 第 2 周<br>2026-11-20 ~ 11-26 | 补齐工具链，验证 vCPU 映射，准备独立验收 | ① 安装 sysstat/fio/stress-ng 并复采基线；② 用 `taskset` 验证 10 vCPU 与宿主 16 逻辑核的映射；③ 安排独立验收 | 4h | 工具版本 + 新基线；`THEORY.md` 补映射结论；`assessment/RESULT.md` 就绪 |

> 说明：原计划第 2 周的“从干净快照重建并比对”已在 2026-11-13 提前完成，
> 证据见 [rebuild-20261113T235603](../evidence/rebuild-20261113T235603/fingerprint.txt)。

## 依赖与约束

- 宿主：Windows 11（build 26200）+ WSL2 2.7.7.0，默认发行版 Ubuntu-24.04.4 LTS。
- 资源边界由 `%USERPROFILE%\.wslconfig` 显式限制：`memory=20GB`、`processors=10`、`swap=8GB`，因此 guest 看到的内存/CPU 不等于宿主（宿主 8C/16T、31.1 GB）。
- 当前用户 `hqhe` 的 `sudo` **需要密码**，暂时无法安装 `sysstat / fio / stress-ng / jq` 等工具；本周基线用 `/proc`、`vmstat`、`ip`、`ss` 自身补齐，不依赖新增软件包。
- Git 远端：`https://github.com/littleboyh/sre-lab`（master）。

## 证据保存位置

- 原始证据：`modules/M00/evidence/baseline-<时间戳>/`（`00-meta` ~ `07-host-windows` + `SHA256SUMS` + `fingerprint.txt`）。
- 快照（大文件，不入 git）：仓库外 `D:\hqhe\WorkSpacee\sre-lab-vm\ubuntu-24.04-base.tar`。
- 脚本：`modules/M00/scripts/`（采集 / 指纹 / 比对 / 封存）。

## 超时与降级

- 若快照导出或导入超时，**保底交付**：脚本 + 两份基线 + 指纹一致；重建比对降级为“按 Runbook 手动执行”，写入遗留问题。
- 不降低的验收要求：能重新搭建环境、能执行基线采集、采集后能恢复初始状态。
- 若 `sudo` 仍不可用，`sysstat` 类工具缺失记为环境限制，不作为拒绝验收的理由，但在 M03/M14 前必须补齐。

## 周末复盘

- 复盘链接：`modules/M00/reviews/week-01.md`（第 1 周末创建）。
- 调整理由：待复盘补充。
