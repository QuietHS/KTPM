param(
  [string]$ProjectRoot = "D:\KTPM\Healthcare-System-PROJECT-main"
)

$ErrorActionPreference = "Stop"

docker run --rm `
  -v "${ProjectRoot}:/etc/newman" `
  postman/newman:alpine `
  run "/etc/newman/N15_A3_Integration_Postman_v2.postman_collection.json" `
  -e "/etc/newman/N15_A3_Docker.postman_environment.json" `
  -r cli,json `
  --reporter-json-export "/etc/newman/A3_newman_report_v2.json"
