#!/usr/bin/env bash
# M00 vCPU 拓扑探针（只读，无需 root）
#
# 用途：记录 guest 可见的 CPU 拓扑（核/线程/SMT 兄弟核），并验证 taskset 的生效范围。
# 背景：.wslconfig 的 processors=10 会让 guest 看到 10 个 vCPU，但宿主有 16 个逻辑核；
#       guest 侧只能看到"超管器切出来的拓扑"，看不到 vCPU 与宿主逻辑核的对应关系。
# 用法：probe-vcpu.sh <输出文件>
#
# 输出：单文件文本证据，可直接入库。

set -u

OUT="${1:-}"
if [ -z "$OUT" ]; then
  echo "usage: $0 <output-file>" >&2
  exit 2
fi

TS="$(date -Is)"

{
  echo "# M00 vCPU topology probe"
  echo "captured_at=$TS"
  echo "host=$(hostname) kernel=$(uname -r)"
  echo
  echo "## lscpu -e（拓扑一览）"
  lscpu -e 2>/dev/null || echo "lscpu not available"
  echo
  echo "## 关键拓扑总量"
  lscpu 2>/dev/null | grep -E '^(CPU\(s\)|Thread\(s\) per core|Core\(s\) per socket|Socket\(s\)|NUMA node\(s\))' || true
  echo
  echo "## /sys/devices/system/cpu/*/topology（SMT 兄弟核）"
  for c in /sys/devices/system/cpu/cpu[0-9]*; do
    n="${c##*/}"
    core="$(cat "$c/topology/core_id" 2>/dev/null || echo '?')"
    pkg="$(cat "$c/topology/physical_package_id" 2>/dev/null || echo '?')"
    sib="$(cat "$c/topology/thread_siblings_list" 2>/dev/null || echo '?')"
    printf '%-6s core_id=%-2s pkg=%-2s thread_siblings=%s\n' "$n" "$core" "$pkg" "$sib"
  done
  echo
  echo "## /proc/cpuinfo（processor / core id / apicid / siblings）"
  grep -E '^(processor|core id|apicid|siblings)' /proc/cpuinfo 2>/dev/null || true
  echo
  echo "## cgroup cpuset（若可见）"
  for f in /sys/fs/cgroup/cpuset.cpus.effective /sys/fs/cgroup/cpuset.cpus; do
    [ -r "$f" ] && echo "$f = $(cat "$f")"
  done
  echo
  echo "## taskset 生效范围测试"
  echo "-- 默认亲和性 --"
  grep Cpus_allowed_list /proc/self/status 2>/dev/null || true
  echo "-- taskset -c 0,1 --"
  taskset -c 0,1 grep Cpus_allowed_list /proc/self/status 2>/dev/null || echo "taskset not available"
  echo "-- taskset -c 9 --"
  taskset -c 9 grep Cpus_allowed_list /proc/self/status 2>/dev/null || true
  echo
  echo "## 说明"
  echo "guest 内只能观测到超管器暴露的 vCPU 与 SMT 组合；"
  echo "vCPU -> 宿主逻辑核的对应关系由 Hyper-V 调度决定，guest 内不可见，"
  echo "且会随宿主负载/电源策略变化。M01 设计 CPU 争用实验时不得假设 1:1 绑定。"
} >"$OUT" 2>&1

echo "vcpu topology probe written: $OUT"
