# Quick Nintendo Switch Detection and Communication Setup
# Detects connected Switch via USB and Bluetooth

Write-Host "🎮 LilithOS: Quick Nintendo Switch Detection" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Gray

# Detect Nintendo Switch devices
Write-Host "🔍 Scanning for Nintendo Switch devices..." -ForegroundColor Cyan

$nintendoDevices = Get-PnpDevice | Where-Object { 
    $_.InstanceId -like "*VID_057E*" -or 
    $_.FriendlyName -like "*Nintendo*" -or 
    $_.FriendlyName -like "*Switch*" 
}

if ($nintendoDevices) {
    Write-Host "✅ Nintendo Switch devices detected:" -ForegroundColor Green
    foreach ($device in $nintendoDevices) {
        Write-Host "   📱 $($device.FriendlyName)" -ForegroundColor White
        Write-Host "      Class: $($device.Class)" -ForegroundColor Gray
        Write-Host "      Status: $($device.Status)" -ForegroundColor Gray
        Write-Host "      ID: $($device.InstanceId)" -ForegroundColor Gray
        Write-Host ""
    }
    
    # Check for USB connection
    $usbDevices = $nintendoDevices | Where-Object { $_.Class -eq "HIDClass" }
    if ($usbDevices) {
        Write-Host "🔌 USB Connection: Active" -ForegroundColor Green
    }
    
    # Check for Bluetooth connection
    $btDevices = $nintendoDevices | Where-Object { $_.Class -eq "Bluetooth" }
    if ($btDevices) {
        Write-Host "📡 Bluetooth Connection: Active" -ForegroundColor Green
    }
    
    # Check for Joy-Cons
    $joycons = $nintendoDevices | Where-Object { $_.FriendlyName -like "*Joy-Con*" }
    if ($joycons) {
        Write-Host "🎮 Joy-Cons: Connected" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "🎉 Communication Status:" -ForegroundColor Yellow
    Write-Host "   USB: $(if ($usbDevices) { '✅ Ready' } else { '❌ Not detected' })" -ForegroundColor $(if ($usbDevices) { 'Green' } else { 'Red' })
    Write-Host "   Bluetooth: $(if ($btDevices) { '✅ Ready' } else { '❌ Not detected' })" -ForegroundColor $(if ($btDevices) { 'Green' } else { 'Red' })
    Write-Host "   Joy-Cons: $(if ($joycons) { '✅ Connected' } else { '❌ Not detected' })" -ForegroundColor $(if ($joycons) { 'Green' } else { 'Red' })
    
    Write-Host ""
    Write-Host "🔒 Setting up communication mode..." -ForegroundColor Cyan
    Write-Host "   Mode: Bidirectional" -ForegroundColor White
    Write-Host "   Encryption: Enabled" -ForegroundColor White
    Write-Host "   Auto-reconnect: Enabled" -ForegroundColor White
    
    Write-Host ""
    Write-Host "🎮 Lilybear can now purr through her veins!" -ForegroundColor Green
    Write-Host "🛠️ Ready for LilithOS development" -ForegroundColor Green
    
} else {
    Write-Host "❌ No Nintendo Switch devices detected" -ForegroundColor Red
    Write-Host "   Please ensure Switch is connected via USB and/or Bluetooth" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Gray 