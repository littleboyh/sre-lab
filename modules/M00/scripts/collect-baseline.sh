#!/usr/bin/env bash
# M00 环境基线采集（只读，无需 root）
#
# 用途：按统一命令集采集主机基线，输出可直接提交为原始证据。
# 用法：collect-baseline.sh <输出目录>
#
# 约定：
#   - 只读命令，不修改系统状态；
#   - 每条输出文件首行记录采集时间与命令，便于复跑比对；
#   - 工具缺失时写 "not available"，不中断整次采集。

set -u

OUTDIR="${1:-}"
if [ -z "$OUTDIR" ]; then
  echo "usage: $0 <outdir>" >&2
  exit 2
fi
mkdir -p "$OUTDIR" || { echo "cannot create $OUTDIR" >&2; exit 1; }

TS="$(date -Is)"
HAVE_MISSING=""

have() { command -v "$1" >/dev/null 2>&1; }

section() {
  # section <文件名> <说明> [命令...]
  local f="$OUTDIR/$1"; shift
  local desc="$1"; shift
  {
    echo "# captured_at=$TS"
    echo "# section=$desc"
    echo "# cmd: $*"
    echo
    if [ "$#" -eq 0 ]; then
      echo "(no command)"
    else
      "$@" 2>&1 || echo "[exit=$?]"
    fi
  } >"$f"
}

section_pipe() {
  # section_pipe <文件名> <说明> <shell 片段>
  local f="$OUTDIR/$1"; shift
  local desc="$1"; shift
  {
    echo "# captured_at=$TS"
    echo "# section=$desc"
    echo
    bash -c "$*" 2>&1 || true
  } >"$f"
}

# ---------- 00 元数据 / 版本 ----------
{
  echo "# M00 baseline metadata"
  echo "captured_at=$TS"
  echo "hostname=$(hostname)"
  echo "user=$(whoami) uid=$(id -u) groups=$(id -Gn | tr ' ' ',')"
  echo
  echo "## uname -a"
  uname -a
  echo
  echo "## /etc/os-release"
  cat /etc/os-release 2>/dev/null || echo "n/a"
  echo
  echo "## /proc/version"
  cat /proc/version 2>/dev/null || echo "n/a"
  echo
  echo "## uptime"
  cat /proc/uptime
  uptime
  echo
  echo "## date"
  date -Is
  date -u -Is
  echo
  echo "## timezone"
  cat /etc/timezone 2>/dev/null || echo "n/a"
  readlink -f /etc/localtime 2>/dev/null || true
  echo
  echo "## locale"
  locale 2>/dev/null || echo "n/a"
  echo
  echo "## cgroup version / limits"
  stat -fc %T /sys/fs/cgroup 2>/dev/null || echo "n/a"
  for f in /sys/fs/cgroup/memory.max /sys/fs/cgroup/memory.current \
           /sys/fs/cgroup/cpu.max /sys/fs/cgroup/pids.current /sys/fs/cgroup/pids.max; do
    [ -r "$f" ] && echo "$f = $(cat "$f")"
  done
} >"$OUTDIR/00-meta.txt" 2>&1

# ---------- 01 CPU ----------
{
  echo "# captured_at=$TS"
  echo "## lscpu"
  lscpu 2>/dev/null || echo "lscpu not available"
  echo
  echo "## nproc / online"
  echo "nproc=$(nproc 2>/dev/null || echo n/a)"
  cat /sys/devices/system/cpu/online 2>/dev/null || true
  echo
  echo "## cpu model"
  grep -m1 -E 'model name' /proc/cpuinfo 2>/dev/null || true
  echo "logical_cpus=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo n/a)"
  echo
  echo "## loadavg (1 5 15) / procs"
  cat /proc/loadavg
  echo
  echo "## /proc/stat cpu totals (user nice system idle iowait irq softirq steal)"
  head -1 /proc/stat
} >"$OUTDIR/01-cpu.txt" 2>&1

# ---------- 02 内存 ----------
{
  echo "# captured_at=$TS"
  echo "## free -m"
  free -m 2>/dev/null || echo "free not available"
  echo
  echo "## /proc/meminfo 关键字段"
  grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree|Dirty|Writeback|Slab|SReclaimable|SUnreclaim|Committed_AS|PageTables):' /proc/meminfo 2>/dev/null || true
  echo
  echo "## swapon"
  swapon --show 2>/dev/null || echo "(no swap or not available)"
  echo
  echo "## OOM / PSI"
  cat /proc/pressure/memory 2>/dev/null || echo "PSI not available"
  echo
  echo "## vmstat 1 5 (r b swpd free buff cache si so bi bo in cs us sy id wa st)"
  if have vmstat; then vmstat 1 5; else echo "vmstat not available"; fi
} >"$OUTDIR/02-memory.txt" 2>&1

# ---------- 03 存储 / I/O ----------
{
  echo "# captured_at=$TS"
  echo "## df -hT (local)"
  df -hT 2>/dev/null || df -h 2>/dev/null || echo "df not available"
  echo
  echo "## df -i (inode)"
  df -i 2>/dev/null || true
  echo
  echo "## lsblk"
  lsblk -o NAME,TYPE,SIZE,FSTYPE,MOUNTPOINTS 2>/dev/null || echo "lsblk not available"
  echo
  echo "## root filesystem mount"
  findmnt -no SOURCE,FSTYPE,OPTIONS / 2>/dev/null || echo "n/a"
  echo
  echo "## /proc/diskstats (sample)"
  cat /proc/diskstats 2>/dev/null | head -20 || true
  echo
  echo "## iostat (if sysstat installed)"
  if have iostat; then iostat -xz 1 2; else echo "iostat not available (sysstat)"; fi
} >"$OUTDIR/03-disk.txt" 2>&1

# ---------- 04 网络 ----------
{
  echo "# captured_at=$TS"
  echo "## ip -br addr"
  ip -br addr 2>/dev/null || echo "ip not available"
  echo
  echo "## ip route"
  ip route 2>/dev/null || true
  echo
  echo "## default gateway"
  ip route show default 2>/dev/null || true
  echo
  echo "## resolv.conf"
  cat /etc/resolv.conf 2>/dev/null || echo "n/a"
  echo
  echo "## socket summary"
  ss -s 2>/dev/null || netstat -s 2>/dev/null | head -5 || echo "ss not available"
  echo
  echo "## interface counters"
  itf="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')"
  if [ -n "${itf:-}" ]; then
    ip -s link show "$itf" 2>/dev/null || true
  else
    echo "no default interface"
  fi
  echo
  echo "## connectivity (best effort, 3s timeout)"
  for target in 1.1.1.1 223.5.5.5; do
    if have ping; then
      echo "-- ping $target"
      ping -c 2 -W 2 "$target" 2>&1 | tail -3
    else
      echo "ping not available"
      break
    fi
  done
  echo
  echo "## DNS resolution (best effort)"
  if have getent; then getent hosts www.baidu.com 2>&1 || echo "getent failed"; fi
} >"$OUTDIR/04-network.txt" 2>&1

# ---------- 05 进程 / 服务 ----------
{
  echo "# captured_at=$TS"
  echo "## pid1"
  ps -p 1 -o pid,comm,args --no-headers 2>/dev/null || true
  echo
  echo "## process count"
  echo "total=$(ps -e --no-headers 2>/dev/null | wc -l)"
  echo
  echo "## top 20 by cpu"
  ps -eo pid,ppid,comm,%cpu,%mem,etime --sort=-%cpu 2>/dev/null | head -21 || true
  echo
  echo "## top 20 by mem"
  ps -eo pid,ppid,comm,%cpu,%mem,rss --sort=-%mem 2>/dev/null | head -21 || true
  echo
  echo "## listening sockets"
  ss -lntup 2>/dev/null | head -30 || echo "ss not available"
} >"$OUTDIR/05-process.txt" 2>&1

# ---------- 06 工具清单 ----------
{
  echo "# captured_at=$TS"
  echo "## baseline tool availability"
  for c in lscpu nproc vmstat free df lsblk findmnt ip ss iostat mpstat pidstat sar ping dig nslookup getent curl wget jq docker go git stress fio unzip tar; do
    if have "$c"; then
      printf 'OK   %-8s %s\n' "$c" "$(command -v "$c")"
    else
      printf 'MISS %-8s\n' "$c"
      HAVE_MISSING="$HAVE_MISSING $c"
    fi
  done
} >"$OUTDIR/06-tools.txt" 2>&1

# ---------- 08 关键工具版本 ----------
{
  echo "# captured_at=$TS"
  echo "## tool versions（版本变化会改变实验结论，必须随基线记录）"
  have git && git --version
  if have curl; then echo -n "curl: "; curl --version 2>/dev/null | head -1; fi
  if have ip; then echo -n "iproute2: "; ip -V 2>/dev/null; fi
  if have ss; then echo -n "ss(iproute2): "; ss -V 2>/dev/null; fi
  if have iostat; then echo -n "sysstat: "; iostat -V 2>/dev/null | head -1; fi
  if have fio; then echo -n "fio: "; fio --version 2>/dev/null; fi
  if have stress-ng; then echo -n "stress-ng: "; stress-ng --version 2>/dev/null; fi
  if have jq; then echo -n "jq: "; jq --version 2>/dev/null; fi
  if have stress; then echo -n "stress: "; stress --version 2>/dev/null | head -1; fi
} >"$OUTDIR/08-tool-versions.txt" 2>&1

# ---------- 校验和 ----------
( cd "$OUTDIR" && sha256sum ./*.txt 2>/dev/null > SHA256SUMS ) || true

echo "baseline collected: $OUTDIR"
echo "missing tools:${HAVE_MISSING:- none}"
