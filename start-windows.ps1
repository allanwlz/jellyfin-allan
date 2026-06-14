param(
    [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ComposeFile = Join-Path $RootDir "docker-compose.dev.yml"
$EnvPath = Join-Path $RootDir $EnvFile
$EnvExamplePath = Join-Path $RootDir ".env.windows.example"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "未检测到 docker。请先安装 Docker Desktop。"
}

if (-not (Test-Path $EnvPath)) {
    if (Test-Path $EnvExamplePath) {
        Copy-Item $EnvExamplePath $EnvPath
        Write-Host "已生成 $EnvFile，请按需修改其中路径后重新执行。" -ForegroundColor Yellow
        exit 0
    }

    throw "未找到 $EnvFile，也未找到 .env.windows.example。"
}

$jfDevDir = Join-Path $RootDir ".jf-dev"
$configDir = Join-Path $jfDevDir "config"
$cacheDir = Join-Path $jfDevDir "cache"
$nugetDir = Join-Path $jfDevDir "nuget"
$webNodeModulesDir = Join-Path $jfDevDir "jf-web-node_modules"
$mediaDir = Join-Path $jfDevDir "media"

New-Item -ItemType Directory -Force -Path $configDir, $cacheDir, $nugetDir, $webNodeModulesDir, $mediaDir | Out-Null

Write-Host "启动 Jellyfin 开发环境（Windows）..." -ForegroundColor Cyan
Write-Host "  根目录: $RootDir"
Write-Host "  环境文件: $EnvPath"

docker compose --env-file "$EnvPath" -f "$ComposeFile" up -d --build

Write-Host ""
Write-Host "容器已启动："
Write-Host "  后端: http://localhost:8096"
Write-Host "  前端: http://localhost:8083"
