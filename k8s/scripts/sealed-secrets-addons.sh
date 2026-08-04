#!/usr/bin/env bash
# master 전용: Sealed Secrets 컨트롤러 설치 (GitOps에서 시크릿을 안전하게 암호화)
# 컨트롤러가 개인키를 클러스터 내부에 보유하고, kubeseal은 공개키로 암호화한다
set -euo pipefail

export KUBECONFIG=/etc/kubernetes/admin.conf
SEALED_SECRETS_VERSION="0.38.4"   # 재현성을 위한 버전 고정

echo "=== [1/4] Install sealed-secrets controller ==="
kubectl apply -f "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${SEALED_SECRETS_VERSION}/controller.yaml"

echo "=== [2/4] Wait for controller to be ready ==="
kubectl wait --namespace kube-system \
  --for=condition=available deployment/sealed-secrets-controller \
  --timeout=120s

echo "=== [3/4] Install kubeseal CLI ==="
# kubeseal: 평문 Secret을 공개키로 암호화해 SealedSecret으로 만드는 CLI
if ! command -v kubeseal &> /dev/null; then
  ARCH=$(dpkg --print-architecture)
  cd /tmp
  curl -L --fail -o kubeseal.tar.gz \
    "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${SEALED_SECRETS_VERSION}/kubeseal-${SEALED_SECRETS_VERSION}-linux-${ARCH}.tar.gz"
  tar -xzf kubeseal.tar.gz kubeseal
  install -m 755 kubeseal /usr/local/bin/kubeseal
  rm -f kubeseal.tar.gz kubeseal
  cd -
fi

echo "=== [4/4] Verify ==="
kubectl get pods -n kube-system -l name=sealed-secrets-controller
kubeseal --version

echo ""
echo "=== Done. Sealed Secrets ready. ==="
# 오프라인 암호화용 공개키 인증서를 미리 받아둘 수 있음:
# kubeseal --fetch-cert > /home/vagrant/pub-cert.pem
echo "Fetch the public cert (for offline sealing):"
echo "kubeseal --fetch-cert > /home/vagrant/pub-cert.pem"