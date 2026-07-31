#!/usr/bin/env bash
# master 전용: Cilium Hubble 활성화 (네트워크 가시성)
set -euo pipefail

export KUBECONFIG=/etc/kubernetes/admin.conf

echo "=== [1/3] Hubble 활성화 (cilium upgrade) ==="
# 기존 설정 유지를 위해 KPR/Gateway 관련 값을 모두 다시 명시 + Hubble 추가
cilium upgrade \
  --reuse-values \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set hubble.metrics.enableOpenMetrics=true \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2}"

echo "=== [2/3] Hubble 컴포넌트 대기 ==="
cilium status --wait --wait-duration 5m

echo "=== [3/3] Hubble UI HTTPRoute 적용 ==="
kubectl apply -f /home/vagrant/k8s/hubble/

echo "=== 완료. Hubble UI: http://hubble.local (hosts에 Gateway IP 등록) ==="