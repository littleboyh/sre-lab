#!/usr/bin/env bash
# M00 证据封装：为基线证据目录生成 SHA256SUMS
#
# 用途：证据目录在采集/比对/人工补充后重新封存，保证"证据未被篡改"。
# 用法：seal-evidence.sh <baseline-evidence-dir>

set -u

D="${1:-}"
if [ -z "$D" ] || [ ! -d "$D" ]; then
  echo "usage: $0 <baseline-evidence-dir>" >&2
  exit 2
fi

cd "$D" || exit 1
sha256sum ./*.txt >SHA256SUMS
echo "sealed: $D ($(wc -l <SHA256SUMS) files)"
