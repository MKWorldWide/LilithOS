# Enhanced Nintendo Switch Firmware Analyzer
# Uses local switchOS directory structure for comprehensive analysis
# Optimized for SN hac-001(-01) with Tegra X1 chip

param(
    [string]$DriveLetter = "O:",
    [string]$LocalSwitchOS = "C:\Users\sunny\Saved Games\LilithOS\switchOS",
    [switch]$FullAnalysis,
    [switch]$ExtractFirmware,
    [switch]$GenerateReport
)

# Configuration
$SCRIPT_VERSION = "2.0.0"
$LATEST_FIRMWARE = "18.1.0"
$ATMOSPHERE_VERSION = "1.7.1"
$HEKATE_VERSION = "6.1.1"
$SWITCH_MODEL = "SN hac-001(-01)"
$TEGRA_CHIP = "Tegra X1"

# Color coding for output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    $validColors = @("Black","DarkBlue","DarkGreen","DarkCyan","DarkRed","DarkMagenta","DarkYellow","Gray","DarkGray","Blue","Green","Cyan","Red","Magenta","Yellow","White")
    if (-not $validColors -contains $Color) {
        $Color = "White"
    }
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-ColorOutput ("`n" + ("="*70)) "Magenta"
    Write-ColorOutput (" $Title") "Magenta"
    Write-ColorOutput ("="*70) "Magenta"
}

function Write-Section {
    param([string]$Title)
    Write-ColorOutput ("`n" + ("-"*50)) "Cyan"
    Write-ColorOutput (" $Title") "Cyan"
    Write-ColorOutput ("-"*50) "Cyan"
}

function Analyze-SwitchDrive {
    param([string]$Drive, [string]$LocalDir)
    
    Write-Header "Enhanced Nintendo Switch Analysis"
    Write-ColorOutput "🔍 Analyzing Switch SD Card: $Drive" "Cyan"
    Write-ColorOutput "📁 Local SwitchOS Directory: $LocalDir" "Cyan"
    Write-ColorOutput "📱 Switch Model: $SWITCH_MODEL" "Cyan"
    Write-ColorOutput "🔧 Tegra Chip: $TEGRA_CHIP" "Cyan"
    
    # Check drive accessibility
    if (-not (Test-Path $Drive)) {
        Write-ColorOutput "❌ Drive $Drive not accessible!" "Red"
        return $false
    }
    
    # Check local directory
    if (-not (Test-Path $LocalDir)) {
        Write-ColorOutput "❌ Local SwitchOS directory not found!" "Red"
        return $false
    }
    
    Write-ColorOutput "✅ Drive and local directory accessible" "Green"
    return $true
}

function Analyze-FirmwareStructure {
    param([string]$Drive)
    
    Write-Section "Firmware Structure Analysis"
    
    # Analyze Nintendo directory structure
    $nintendoPath = Join-Path $Drive "Nintendo"
    if (Test-Path $nintendoPath) {
        Write-ColorOutput "📁 Nintendo directory found" "Green"
        
        $contentsPath = Join-Path $nintendoPath "Contents"
        if (Test-Path $contentsPath) {
            Write-ColorOutput "📂 Contents directory found" "Green"
            
            # Analyze registered titles
            $registeredPath = Join-Path $contentsPath "registered"
            if (Test-Path $registeredPath) {
                $registeredCount = (Get-ChildItem $registeredPath -Directory | Measure-Object).Count
                Write-ColorOutput "📦 Registered titles: $registeredCount" "Cyan"
                
                # List some key titles
                $keyTitles = Get-ChildItem $registeredPath -Directory | Select-Object -First 5
                foreach ($title in $keyTitles) {
                    Write-ColorOutput "  ├── $($title.Name)" "White"
                }
            }
            
            # Check for other content types
            $contentTypes = @("placehld", "save", "title", "temp")
            foreach ($type in $contentTypes) {
                $typePath = Join-Path $contentsPath $type
                if (Test-Path $typePath) {
                    $itemCount = (Get-ChildItem $typePath -Recurse | Measure-Object).Count
                    Write-ColorOutput "📋 $type content: $itemCount items" "Cyan"
                }
            }
        }
    } else {
        Write-ColorOutput "❌ Nintendo directory not found" "Red"
    }
    
    # Analyze existing CFW structure
    Write-Section "Custom Firmware Analysis"
    
    $cfwPaths = @("atmosphere", "bootloader", "switch", "homebrew")
    foreach ($cfw in $cfwPaths) {
        $cfwPath = Join-Path $Drive $cfw
        if (Test-Path $cfwPath) {
            $itemCount = (Get-ChildItem $cfwPath -Recurse | Measure-Object).Count
            Write-ColorOutput "🔧 $cfw found: $itemCount items" "Green"
        } else {
            Write-ColorOutput "❌ $cfw not found" "Red"
        }
    }
}

function Extract-FirmwareData {
    param([string]$Drive, [string]$LocalDir)
    
    Write-Section "Firmware Data Extraction"
    
    # Create extraction directory in local SwitchOS
    $extractDir = Join-Path $LocalDir "firmware_analysis"
    if (-not (Test-Path $extractDir)) {
        New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
        Write-ColorOutput "📁 Created extraction directory" "Green"
    }
    
    # Extract key firmware data
    $extractionTargets = @{
        "Nintendo\Contents\registered" = "registered_titles"
        "Nintendo\Contents\placehld" = "placeholder_content"
        "Nintendo\Contents\save" = "save_data"
    }
    
    foreach ($target in $extractionTargets.GetEnumerator()) {
        $sourcePath = Join-Path $Drive $target.Key
        $destPath = Join-Path $extractDir $target.Value
        
        if (Test-Path $sourcePath) {
            Write-ColorOutput "📋 Extracting $($target.Key)..." "Cyan"
            
            if (-not (Test-Path $destPath)) {
                New-Item -ItemType Directory -Path $destPath -Force | Out-Null
            }
            
            try {
                # Copy with progress
                $items = Get-ChildItem $sourcePath -Recurse
                $totalItems = $items.Count
                $currentItem = 0
                
                foreach ($item in $items) {
                    $currentItem++
                    $progress = [math]::Round(($currentItem / $totalItems) * 100, 1)
                    Write-Progress -Activity "Extracting $($target.Key)" -Status "$currentItem of $totalItems" -PercentComplete $progress
                    
                    $relativePath = $item.FullName.Substring($sourcePath.Length + 1)
                    $destItemPath = Join-Path $destPath $relativePath
                    
                    if ($item.PSIsContainer) {
                        if (-not (Test-Path $destItemPath)) {
                            New-Item -ItemType Directory -Path $destItemPath -Force | Out-Null
                        }
                    } else {
                        $destDir = Split-Path $destItemPath -Parent
                        if (-not (Test-Path $destDir)) {
                            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                        }
                        Copy-Item -Path $item.FullName -Destination $destItemPath -Force
                    }
                }
                
                Write-ColorOutput "✅ Extracted $($target.Key) ($totalItems items)" "Green"
            } catch {
                Write-ColorOutput "⚠️ Partial extraction of $($target.Key): $($_.Exception.Message)" "Yellow"
            }
        } else {
            Write-ColorOutput "❌ $($target.Key) not found" "Red"
        }
    }
    
    Write-Progress -Activity "Extraction Complete" -Completed
}

function Generate-AnalysisReport {
    param([string]$Drive, [string]$LocalDir)
    
    Write-Section "Generating Analysis Report"
    
    $reportDir = Join-Path $LocalDir "analysis_reports"
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $reportPath = Join-Path $reportDir "switch_analysis_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    
    $report = @"
# Nintendo Switch Firmware Analysis Report
Generated by LilithOS Enhanced Switch Analyzer

## Analysis Information
- **Analysis Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Switch Model:** $SWITCH_MODEL
- **Tegra Chip:** $TEGRA_CHIP
- **Latest Firmware:** $LATEST_FIRMWARE
- **Atmosphere Version:** $ATMOSPHERE_VERSION
- **Hekate Version:** $HEKATE_VERSION
- **Target Drive:** $Drive
- **Local Directory:** $LocalDir

## Drive Analysis Results

### Firmware Structure
$(Get-FirmwareStructureReport $Drive)

### Custom Firmware Status
$(Get-CFWStatusReport $Drive)

### Storage Analysis
$(Get-StorageAnalysis $Drive)

## Recommendations

### For Atmosphere Installation
1. Ensure sufficient free space (minimum 2GB recommended)
2. Backup existing data before installation
3. Use latest Atmosphere version compatible with current firmware
4. Follow proper RCM boot procedure

### For LilithOS Integration
1. Install Atmosphere CFW first
2. Deploy LilithOS modules to appropriate directories
3. Configure bootloader for dual-boot capability
4. Test all functionality before production use

## Security Considerations
- This analysis is for educational purposes only
- Respect Nintendo's intellectual property rights
- Follow responsible disclosure practices
- Use only legitimate homebrew applications

## Technical Notes
- Tegra X1 chip requires specific payload optimization
- SN hac-001(-01) model has specific hardware characteristics
- Firmware extraction requires careful handling of system files
- Custom firmware installation requires proper boot sequence

---
*Report generated by LilithOS Enhanced Switch Analyzer v$SCRIPT_VERSION*
"@
    
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-ColorOutput "📄 Analysis report generated: $reportPath" "Green"
    
    return $reportPath
}

function Get-FirmwareStructureReport {
    param([string]$Drive)
    
    $report = @"
### Nintendo Directory Structure
"@
    
    $nintendoPath = Join-Path $Drive "Nintendo"
    if (Test-Path $nintendoPath) {
        $contentsPath = Join-Path $nintendoPath "Contents"
        if (Test-Path $contentsPath) {
            $registeredPath = Join-Path $contentsPath "registered"
            if (Test-Path $registeredPath) {
                $registeredCount = (Get-ChildItem $registeredPath -Directory | Measure-Object).Count
                $report += "`n- **Registered Titles:** $registeredCount found"
            }
            
            $contentTypes = @("placehld", "save", "title", "temp")
            foreach ($type in $contentTypes) {
                $typePath = Join-Path $contentsPath $type
                if (Test-Path $typePath) {
                    $itemCount = (Get-ChildItem $typePath -Recurse | Measure-Object).Count
                    $report += "`n- **$type Content:** $itemCount items"
                }
            }
        }
    } else {
        $report += "`n- **Nintendo Directory:** Not found"
    }
    
    return $report
}

function Get-CFWStatusReport {
    param([string]$Drive)
    
    $report = @"
### Custom Firmware Components
"@
    
    $cfwPaths = @("atmosphere", "bootloader", "switch", "homebrew")
    foreach ($cfw in $cfwPaths) {
        $cfwPath = Join-Path $Drive $cfw
        if (Test-Path $cfwPath) {
            $itemCount = (Get-ChildItem $cfwPath -Recurse | Measure-Object).Count
            $report += "`n- **$cfw:** Present ($itemCount items)"
        } else {
            $report += "`n- **$cfw:** Not installed"
        }
    }
    
    return $report
}

function Get-StorageAnalysis {
    param([string]$Drive)
    
    $driveLetter = $Drive.TrimEnd('\')
    $driveInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$driveLetter'"
    
    $totalSpace = [math]::Round($driveInfo.Size / 1GB, 2)
    $freeSpace = [math]::Round($driveInfo.FreeSpace / 1GB, 2)
    $usedSpace = [math]::Round(($driveInfo.Size - $driveInfo.FreeSpace) / 1GB, 2)
    $fileSystem = $driveInfo.FileSystem
    
    $report = @"
### Storage Information
- **Total Space:** $totalSpace GB
- **Free Space:** $freeSpace GB
- **Used Space:** $usedSpace GB
- **File System:** $fileSystem
"@
    
    return $report
}

# Main execution
Write-Header "LilithOS Enhanced Switch Analyzer v$SCRIPT_VERSION"

if (Analyze-SwitchDrive -Drive $DriveLetter -LocalDir $LocalSwitchOS) {
    
    if ($FullAnalysis -or $ExtractFirmware) {
        Analyze-FirmwareStructure -Drive $DriveLetter
        
        if ($ExtractFirmware) {
            Extract-FirmwareData -Drive $DriveLetter -LocalDir $LocalSwitchOS
        }
    }
    
    if ($GenerateReport -or $FullAnalysis) {
        $reportPath = Generate-AnalysisReport -Drive $DriveLetter -LocalDir $LocalSwitchOS
        Write-ColorOutput "`n📊 Analysis complete! Report saved to: $reportPath" "Green"
    }
    
    Write-Header "Analysis Summary"
    Write-ColorOutput "✅ Switch drive analysis completed successfully" "Green"
    Write-ColorOutput "📁 Local analysis data stored in: $LocalSwitchOS" "Cyan"
    Write-ColorOutput "🔧 Ready for Atmosphere installation and LilithOS integration" "Cyan"
    
} else {
    Write-ColorOutput "❌ Analysis failed - check drive accessibility and permissions" "Red"
}

Write-ColorOutput "`n🎮 Happy modding with LilithOS!" "Magenta" 