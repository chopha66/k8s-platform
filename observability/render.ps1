# Rendered Manifests Pattern: 로컬 helm 차트를 리소스별로 렌더링 (Windows/PowerShell)
# 사용: .\render.ps1  ->  git add/commit/push  ->  ArgoCD가 rendered/ 동기화
#
# 구조 전제 (스크립트는 observability/ 에 위치):
#   observability/
#   ├── render.ps1
#   └── prometheus/
#       ├── values.yaml
#       └── charts/kube-prometheus-stack/   (helm pull --untar 로 받은 로컬 차트)

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("prometheus", "loki", "alloy")]
    [string]$Component
)

$ErrorActionPreference = "Stop"

# --- 컴포넌트별 설정 ---
$ReleaseMap = @{
    "prometheus" = "kube-prometheus-stack"
    "loki"       = "loki"
    "alloy"      = "alloy"
}
$Release   = $ReleaseMap[$Component]
$Namespace = "monitoring"

$ScriptDir  = $PSScriptRoot
# 차트는 charts/ 아래 유일한 폴더를 자동 탐색 (차트명 하드코딩 불필요)
$ChartRoot  = Join-Path $ScriptDir "$Component\helm\charts"
$ChartPath  = Get-ChildItem -Directory $ChartRoot -ErrorAction SilentlyContinue | Select-Object -First 1 | ForEach-Object { $_.FullName }
$ValuesPath = Join-Path $ScriptDir "$Component\helm\$Component-values.yaml"
$OutDir     = Join-Path $ScriptDir "$Component\kustomize\overlays\base\rendered"

Write-Host "=== [1/3] Preflight check ($Component) ===" -ForegroundColor Cyan
if (-not $ChartPath) {
    Write-Error "Chart not found under: $ChartRoot (did you run 'helm pull'?)"
}
if (-not (Test-Path $ValuesPath)) {
    Write-Error "Values file not found: $ValuesPath"
}

Write-Host "=== [2/3] Reset output directory ===" -ForegroundColor Cyan
# 이전 렌더링 결과 제거 (삭제된 리소스가 남지 않도록 clean)
if (Test-Path $OutDir) {
    Remove-Item -Recurse -Force $OutDir
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "=== [3/3] helm template (split per-resource output) ===" -ForegroundColor Cyan
# --output-dir: 리소스를 원본 templates 구조 그대로 파일별로 분리 저장
# --include-crds: CRD도 함께 렌더링
helm template $Release $ChartPath `
    --namespace $Namespace `
    --values $ValuesPath `
    --include-crds `
    --output-dir $OutDir

if ($LASTEXITCODE -ne 0) {
    Write-Error "helm template failed (exit $LASTEXITCODE)"
}

$fileCount = (Get-ChildItem -Recurse -File $OutDir | Measure-Object).Count
Write-Host "Done: $fileCount files -> $OutDir" -ForegroundColor Green