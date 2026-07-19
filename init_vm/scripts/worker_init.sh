#!/usr/bin/env bash
# worker 전용: 고정 토큰으로 클러스터 join
set -euo pipefail

MASTER_ENDPOINT="192.168.56.10:6443"
TOKEN="master.0123456789abcdef"

# 이미 join 됐으면 스킵 (멱등성)
if [ -f /etc/kubernetes/kubelet.conf ]; then
  echo "=== 이미 join된 노드, 스킵 ==="
  exit 0
fi

echo "=== kubeadm join ==="
kubeadm join "${MASTER_ENDPOINT}" \
  --token "${TOKEN}" \
  --discovery-token-unsafe-skip-ca-verification

echo "=== 완료: $(hostname) ==="