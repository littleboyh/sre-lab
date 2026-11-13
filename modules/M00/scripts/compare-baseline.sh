#!/usr/bin/env bash
# M00 基线比对：两次基线采集的稳定字段对比
#
# 用途：验证"同一环境再次采集，身份字段一致"，即基线可复跑、可比较。
#       这是 M00 验收"从干净快照按文档重建并比对结果"的比对工具。
# 用法：compare-baseline.sh <baseline-A-dir> <baseline-B-dir>
#
# 输出：
#   <A>/fingerprint.txt、<B>/fingerprint.txt
#   <B>/fingerprint-diff.txt
# 退出码：0 = 指纹一致；1 = 存在差异

set -u

A="${1:-}"; B="${2:-}"
if [ -z "$A" ] || [ -z "$B" ] || [ ! -d "$A" ] || [ ! -d "$B" ]; then
  echo "usage: $0 <baseline-A-dir> <baseline-B-dir>" >&2
  exit 2
fi

SDIR="$(cd "$(dirname "$0")" && pwd)"

bash "$SDIR/fingerprint.sh" "$A" >"$A/fingerprint.txt" || exit 1
bash "$SDIR/fingerprint.sh" "$B" >"$B/fingerprint.txt" || exit 1

if diff -u "$A/fingerprint.txt" "$B/fingerprint.txt" >"$B/fingerprint-diff.txt"; then
  echo "IDENTICAL: environment fingerprint matches ($A vs $B)"
  exit 0
else
  echo "DIFFERENT: see $B/fingerprint-diff.txt"
  exit 1
fi
