# Rendered Manifests Pattern: 로컬 helm 차트를 리소스별로 렌더링 (Windows/PowerShell)
# 사용: .\render.ps1  ->  git add/commit/push  ->  ArgoCD가 rendered/ 동기화
#
# 구조 전제 (스크립트는 observability/ 에 위치):
#   observability/
#   ├── render.ps1
#   └── prometheus/
#       ├── values.yaml
#       └── charts/kube-prometheus-stack/   (helm pull --untar 로 받은 로컬 차트)

$ErrorActionPreference = "Stop"

# --- 설정 ---
$Release    = "kube-prometheus-stack"
$Namespace  = "monitoring"

$ScriptDir  = $PSScriptRoot
$ChartPath  = Join-Path $ScriptDir "prometheus\charts\kube-prometheus-stack"
$ValuesPath = Join-Path $ScriptDir "prometheus\prometheus-values.yaml"
$OutDir     = Join-Path $ScriptDir "prometheus\rendered\base"

Write-Host "=== [1/3] 사전 확인 ===" -ForegroundColor Cyan
if (-not (Test-Path $ChartPath)) {
    Write-Error "차트 경로 없음: $ChartPath"
}
if (-not (Test-Path $ValuesPath)) {
    Write-Error "values 경로 없음: $ValuesPath"
}

Write-Host "=== [2/3] 출력 디렉터리 초기화 ===" -ForegroundColor Cyan
# 이전 렌더링 결과 제거 (삭제된 리소스가 남지 않도록 clean)
if (Test-Path $OutDir) {
    Remove-Item -Recurse -Force $OutDir
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "=== [3/3] helm template (리소스별 분리 출력) ===" -ForegroundColor Cyan
# --output-dir: 리소스를 원본 templates 구조 그대로 파일별로 분리 저장
# --include-crds: CRD도 함께 렌더링
helm template $Release $ChartPath `
    --namespace $Namespace `
    --values $ValuesPath `
    --include-crds `
    --output-dir $OutDir

if ($LASTEXITCODE -ne 0) {
    Write-Error "helm template 실패 (exit $LASTEXITCODE)"
}

$fileCount = (Get-ChildItem -Recurse -File $OutDir | Measure-Object).Count
Write-Host "완료: $fileCount 개 파일 -> $OutDir" -ForegroundColor Green