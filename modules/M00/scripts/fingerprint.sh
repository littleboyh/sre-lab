#!/usr/bin/env bash
# M00 环境指纹：从基线证据目录提取"应稳定不变"的身份字段
#
# 用途：把两次基线采集（或重建前后）的稳定字段归一化后比较，
#       判断环境是否可重建；易变指标（内存余量、计数器、负载）不参与比对。
# 用法：fingerprint.sh <baseline-evidence-dir>
#
# 输出：稳定字段清单（key=value），可直接 diff 两份输出。

set -u

DIR="${1:-}"
if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  echo "usage: $0 <baseline-evidence-dir>" >&2
  exit 2
fi

p() { printf '%s\n' "$*"; }

p "# fingerprint (stable identity fields only)"
p "# NOTE: volatile metrics (load, free mem, counters) intentionally excluded"

# ---- 版本身份（00-meta） ----
if [ -f "$DIR/00-meta.txt" ]; then
  p "uname=$(grep -m1 '^Linux ' "$DIR/00-meta.txt")"
  p "os=$(grep -m1 '^PRETTY_NAME=' "$DIR/00-meta.txt")"
  p "timezone=$(sed -n '/^## timezone$/,+2p' "$DIR/00-meta.txt" | sed -n '2p')"
  p "cgroup=$(sed -n '/^## cgroup version/,+1p' "$DIR/00-meta.txt" | sed -n '2p')"
fi

# ---- CPU 拓扑（01-cpu） ----
# 注意：lscpu 的键名含 "(s)" 等正则元字符，必须用 -F 字面匹配，否则静默取空
if [ -f "$DIR/01-cpu.txt" ]; then
  while IFS= read -r k; do
    v="$(grep -m1 -F "${k}:" "$DIR/01-cpu.txt" | sed 's/  */ /g; s/ *$//')"
    [ -z "$v" ] && v="(missing)"
    p "lscpu.$(printf '%s' "$k" | tr ' ()' '.__')=$v"
  done <<'KEYS'
Architecture
CPU(s)
Model name
Thread(s) per core
Core(s) per socket
Socket(s)
NUMA node(s)
KEYS
  p "nproc=$(grep -m1 '^nproc=' "$DIR/01-cpu.txt")"
fi

# ---- 内存与交换容量（02-memory，只看总量） ----
if [ -f "$DIR/02-memory.txt" ]; then
  p "meminfo.MemTotal=$(grep -m1 '^MemTotal:' "$DIR/02-memory.txt")"
  p "meminfo.SwapTotal=$(grep -m1 '^SwapTotal:' "$DIR/02-memory.txt")"
  p "swapon.size=$(awk '/^\/dev\// {print $3}' "$DIR/02-memory.txt" | head -1)"
fi

# ---- 存储拓扑（03-disk） ----
# 注意：
#   - /dev/sdX 的字母由挂载顺序决定，属实例属性，故根文件系统只比 fstype+挂载选项；
#   - WSL2 运行期会把其他发行版的 VHD 也挂到同一个 utility VM，块设备清单随
#     "当前有哪些发行版在运行" 变化，属运行期状态，不进身份指纹；
#   - 因此这里只保留根文件系统的类型与容量。
if [ -f "$DIR/03-disk.txt" ]; then
  p "rootfs=$(sed -n '/^## root filesystem mount$/,+1p' "$DIR/03-disk.txt" | sed -n '2p' \
      | sed -E 's#^/dev/[a-z0-9]+#<root-dev>#; s/  */ /g; s/ *$//')"
  p "root.df=$(grep -E '^/dev/[a-z0-9]+[[:space:]]+ext4' "$DIR/03-disk.txt" | awk '{print $2, $3}' | head -1)"
fi

# ---- 网络身份（04-network） ----
# 注意：WSL2 NAT 的 eth0 IP 每次启动可能变化，属于易变项，不参与身份比对
if [ -f "$DIR/04-network.txt" ]; then
  p "net.nameserver=$(grep -m1 '^nameserver ' "$DIR/04-network.txt")"
  p "net.default_gw=$(grep -m1 '^default via' "$DIR/04-network.txt" | sed -E 's/ via [0-9.]+ / via <nat-gw> /')"
fi

# ---- 工具可用性（06-tools） ----
if [ -f "$DIR/06-tools.txt" ]; then
  while IFS= read -r line; do
    case "$line" in
      OK*|MISS*) p "tools.$(echo "$line" | sed 's/  */ /g')" ;;
    esac
  done <"$DIR/06-tools.txt"
fi

# ---- 宿主身份（07-host-windows，可选） ----
if [ -f "$DIR/07-host-windows.txt" ]; then
  p "host.windows=$(grep -m1 '^BuildNumber' "$DIR/07-host-windows.txt" | sed 's/  */ /g; s/ *$//')"
  p "host.wsl=$(grep -m1 '^WSL' "$DIR/07-host-windows.txt" | sed 's/  */ /g; s/ *$//')"
fi
