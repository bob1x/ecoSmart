#!/usr/bin/env pwsh
# build_and_bundle.ps1 — Build Flutter web and copy to backend/static/
# Usage: .\build_and_bundle.ps1

$ErrorActionPreference = "Stop"

$ROOT = Split-Path $PSScriptRoot -Parent
if (-not $ROOT) { $ROOT = (Get-Location).Path }

$FRONTEND = Join-Path $ROOT "frontend"
$BACKEND = Join-Path $ROOT "backend"
$STATIC = Join-Path $BACKEND "static"

Write-Host "`n=== Building Flutter Web ===" -ForegroundColor Cyan
Push-Location $FRONTEND
flutter build web --release
Pop-Location

Write-Host "`n=== Copying build to backend/static/ ===" -ForegroundColor Cyan
if (Test-Path $STATIC) { Remove-Item -Recurse -Force $STATIC }
Copy-Item -Recurse -Force (Join-Path $FRONTEND "build\web") $STATIC

Write-Host "`n=== Done! ===" -ForegroundColor Green
Write-Host "Static files at: $STATIC"
Write-Host "Files: $((Get-ChildItem -Recurse $STATIC -File).Count)"
Write-Host "`nTo test locally:"
Write-Host "  cd $BACKEND"
Write-Host "  uvicorn api.main:app --reload"
Write-Host "  Open http://localhost:8000"
