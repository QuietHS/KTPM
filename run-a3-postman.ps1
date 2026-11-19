param(
  [string]$ProjectRoot = "D:\KTPM\Healthcare-System-PROJECT-main"
)

$ErrorActionPreference = "Stop"

$Collection = Join-Path $ProjectRoot "N15_A3_Integration_Postman.postman_collection.json"
$Environment = Join-Path $ProjectRoot "N15_A3_Docker.postman_environment.json"
$Report = Join-Path $ProjectRoot "A3_newman_report.json"

Write-Host "== A3 Integration Test ==" -ForegroundColor Cyan

if (-not (Test-Path $Collection)) { throw "Không tìm thấy: $Collection" }
if (-not (Test-Path $Environment)) { throw "Không tìm thấy: $Environment" }

Write-Host "`n[1] Docker services:" -ForegroundColor Cyan
docker compose -f (Join-Path $ProjectRoot "docker-compose.yml") ps

Write-Host "`n[2] Newman:" -ForegroundColor Cyan
docker run --rm `
  -v "${ProjectRoot}:/etc/newman" `
  postman/newman:alpine `
  run "/etc/newman/N15_A3_Integration_Postman.postman_collection.json" `
  -e "/etc/newman/N15_A3_Docker.postman_environment.json" `
  -r cli,json `
  --reporter-json-export "/etc/newman/A3_newman_report.json"

Write-Host "`nReport: $Report" -ForegroundColor Green
