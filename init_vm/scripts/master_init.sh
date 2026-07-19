#!/usr/bin/env bash
# master 전용: kubeadm init + kubeconfig + Cilium CNI
set -euo pipefail

CP_IP="192.168.56.10"
POD_CIDR="10.244.0.0/16"
# 고정 토큰 (형식: [a-z0-9]{6}.[a-z0-9]{16}) — worker join에 사용
TOKEN="master.0123456789abcdef"

# 이미 init 됐으면 스킵 (멱등성)
if [ -f /etc/kubernetes/admin.conf ]; then
  echo "=== 이미 초기화된 클러스터, init 스킵 ==="
else
  echo "=== [1/2] kubeadm init ==="
  kubeadm init \
    --apiserver-advertise-address="${CP_IP}" \
    --pod-network-cidr="${POD_CIDR}" \
    --token "${TOKEN}" \
    --token-ttl 0
fi

echo "=== [2/2] kubeconfig 설정 (vagrant 유저) ==="
mkdir -p /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

echo "=== 완료 ==="