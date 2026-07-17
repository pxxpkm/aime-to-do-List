# Smoke test for local SQLite library API (S1).
# Start: python proxy_server.py
# Then:  powershell -NoProfile -File scripts/smoke_api.ps1

$ErrorActionPreference = "Stop"
$base = "http://127.0.0.1:8080"

Write-Host "GET /api/health"
$h = Invoke-RestMethod "$base/api/health"
if (-not $h.ok) { throw "health.ok is false" }
Write-Host "  ok items=$($h.itemCount) folders=$($h.folderCount)"
Write-Host "  db=$($h.dbPath)"

$id = "smoke_bgm_1"
$json = @"
{"id":"$id","userId":"local_user","type":"anime","title":"Smoke Test","currentUnits":3,"unitLabel":"ep","status":"in_progress","sortOrder":0,"tags":[],"pinTier":"none","pinOrder":0}
"@

Write-Host "PUT /api/v1/items/$id"
Invoke-RestMethod -Method Put -Uri "$base/api/v1/items/$id" `
  -ContentType "application/json; charset=utf-8" -Body $json | Out-Null

Write-Host "GET /api/v1/items/$id"
$item = Invoke-RestMethod "$base/api/v1/items/$id"
if ($item.title -ne "Smoke Test") { throw "title mismatch" }
if ($item.currentUnits -ne 3) { throw "currentUnits mismatch" }

Write-Host "GET /api/v1/library"
$lib = Invoke-RestMethod "$base/api/v1/library"
if ($lib.format -ne "acg_todo_backup") { throw "format mismatch" }
$found = @($lib.items | Where-Object { $_.id -eq $id })
if ($found.Count -lt 1) { throw "item missing from library" }

Write-Host "DELETE /api/v1/items/$id"
Invoke-RestMethod -Method Delete -Uri "$base/api/v1/items/$id" | Out-Null

Write-Host "PUT /api/v1/items:batch"
$batch = @"
{"items":[
  {"id":"batch_1","userId":"local_user","type":"anime","title":"B1","currentUnits":1,"unitLabel":"ep","status":"in_progress","sortOrder":0,"tags":[],"pinTier":"none","pinOrder":0},
  {"id":"batch_2","userId":"local_user","type":"manga","title":"B2","currentUnits":2,"unitLabel":"ep","status":"in_progress","sortOrder":1,"tags":[],"pinTier":"none","pinOrder":0}
]}
"@
$br = Invoke-RestMethod -Method Put -Uri "$base/api/v1/items:batch" `
  -ContentType "application/json; charset=utf-8" -Body $batch
if ($br.count -ne 2) { throw "batch count expected 2, got $($br.count)" }
Invoke-RestMethod -Method Delete -Uri "$base/api/v1/items/batch_1" | Out-Null
Invoke-RestMethod -Method Delete -Uri "$base/api/v1/items/batch_2" | Out-Null

Write-Host "PUT /api/v1/notifications"
$notifBody = @"
{"notifications":[
  {"id":"smoke_n1","itemId":"smoke_item","type":"stale_7day","scheduledAt":"2026-07-17T00:00:00.000Z","createdAt":"2026-07-17T00:00:00.000Z"}
]}
"@
$nr = Invoke-RestMethod -Method Put -Uri "$base/api/v1/notifications" `
  -ContentType "application/json; charset=utf-8" -Body $notifBody
if ($nr.count -ne 1) { throw "notif put count expected 1, got $($nr.count)" }

Write-Host "GET /api/v1/notifications"
$ng = Invoke-RestMethod "$base/api/v1/notifications"
$nf = @($ng.notifications | Where-Object { $_.id -eq "smoke_n1" })
if ($nf.Count -lt 1) { throw "notification missing after put" }

Write-Host "DELETE /api/v1/notifications"
Invoke-RestMethod -Method Delete -Uri "$base/api/v1/notifications" | Out-Null

Write-Host "SMOKE OK"
