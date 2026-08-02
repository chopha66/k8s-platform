#!/usr/bin/env bash
# master 전용: local-path 애드온 설치 (MetalLB)
# default 스토리지 클래스
set -euo pipefail

export KUBECONFIG=/etc/kubernetes/admin.conf
MANIFEST="/home/vagrant/k8s/storage/local-path-storage.yaml"

echo "=== [1/3] local-path-provisioner 적용==="
kubectl apply -f "${MANIFEST}"

echo "=== [2/3] Provisioner 대기 ==="
for i in $(seq 1 30); do
  if [ "$(kubectl get pods -n local-path-storage --no-headers 2>/dev/null | wc -l)" -gt 0 ]; then
    break
  fi
  sleep 2
done
kubectl wait --namespace local-path-storage \
  --for=condition=ready pod \
  --selector=app=local-path-provisioner \
  --timeout=120s

echo "=== [3/3] Default 스토리지 클래스 확인 ==="
kubectl get storageclass

echo "=== 완료. 'local-path' should be marked (default) ==="