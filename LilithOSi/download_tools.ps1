# PowerShell script to download and setup libimobiledevice tools

Write-Host "[*] Setting up LilithOS tools..." -ForegroundColor Cyan

# Create tools directory if it doesn't exist
if (-not (Test-Path "tools")) {
    New-Item -ItemType Directory -Path "tools"
}

# Download URL
$url = "https://github.com/libimobiledevice/win32/releases/download/1.2.1/libimobiledevice-1.2.1-win32.zip"
$output = "tools\libimobiledevice.zip"

Write-Host "[*] Downloading libimobiledevice..." -ForegroundColor Yellow
try {
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $output)
    Write-Host "[+] Download completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "[!] Failed to download automatically. Please download manually from:" -ForegroundColor Red
    Write-Host $url -ForegroundColor Yellow
    Write-Host "and extract the contents to the tools folder." -ForegroundColor Yellow
    exit 1
}

# Extract the zip file
Write-Host "[*] Extracting libimobiledevice..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $output -DestinationPath "tools" -Force
    Write-Host "[+] Extraction completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "[!] Failed to extract the zip file. Please extract manually." -ForegroundColor Red
    exit 1
}

# Add tools to PATH
Write-Host "[*] Adding tools to PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$toolsPath = Join-Path $PWD.Path "tools"
if (-not $currentPath.Contains($toolsPath)) {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$toolsPath", "User")
    Write-Host "[+] Tools added to PATH successfully!" -ForegroundColor Green
}

Write-Host "`n[*] Setup completed!" -ForegroundColor Cyan
Write-Host "[*] Please restart your terminal and run install_lilithos.bat" -ForegroundColor Yellow 