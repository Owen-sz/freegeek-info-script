#!/usr/bin/env pwsh # This shebang is for testing purposes. Not needed on Windows hosts

#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Set-PSRepository PSGallery -InstallationPolicy Trusted; Install-PackageProvider NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -ForceBootstrap; Import-PackageProvider NuGet -Name NuGet -Force; Install-Module PSWindowsUpdate -Repository PSGallery -Scope AllUsers -Force -Confirm:$false -SkipPublisherCheck -AllowClobber -AcceptLicense; Import-Module PSWindowsUpdate

# colors for formatting

function red {
    param (
        [string]$Text
    )
    Write-Host $Text -ForegroundColor Red
}

function yellow {
    param (
        [string]$Text
    )
    Write-Host $Text -ForegroundColor Yellow
}

function blue {
    param (
        [string]$Text
    )
    Write-Host $Text -ForegroundColor Blue
}

# Module for Windows update powershell window

red "Installing PSWindowsUpdate and dependencies..."

Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-PackageProvider NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -ForceBootstrap
Import-PackageProvider NuGet -Force

Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -Command "Install-Module PSWindowsUpdate -Repository PSGallery -Scope AllUsers -Force -Confirm:$false -AllowClobber -SkipPublisherCheck"' -Wait

Import-Module PSWindowsUpdate

red "-----Opening windows for Windows update and package updates. Reboot when both are complete.-----"

Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -Command "winget install libreoffice crystaldiskinfo; winget upgrade --all --unknown --silent --force"' -Wait

start-process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -Command "Install-WindowsUpdate -MicrosoftUpdate -Install -AcceptAll"' -Wait

# Generate battery report in the same folder as script

red "Generating Battery Report..."

$reportPath = Join-Path $PSScriptRoot "batteryreport.xml"
powercfg /batteryreport /XML /OUTPUT $reportPath > $null
# Start-Sleep -Seconds 1

# CPUs

function cpu {
    Get-WmiObject -Class Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors
}

blue "CPU Information"

yellow "$(cpu)"

# GPUs

function gpu {
	Get-CimInstance Win32_VideoController | Format-List Name, @{Name="VRAM (GB)";Expression={[math]::Round($_.AdapterRAM / 1GB, 2)}}
}

blue "GPU Information"

yellow "$(gpu)"
# RAM

# Disk

# Port Stuff
# System Stuff

function system {
	Get-ComputerInfo | Select-Object @{Name="Manufacturer";Expression={$_.CsManufacturer}}, @{Name="Model";Expression={$_.CsModel}} | Format-List
}

blue "System Information"

yellow "$(system)"

# Battery stuff oh boy this is where the fun begins

$InfoAlertPercent = 70
$WarnAlertPercent = 50
$CritAlertPercent = 20

# Load XML
[xml]$b = Get-Content $reportPath

# Loop through battery entries
foreach ($battery in $b.BatteryReport.Batteries.Battery) {
    $design = [int64]$battery.DesignCapacity
    $full   = [int64]$battery.FullChargeCapacity

    if ($design -gt 0) {
        $healthPc = [math]::Floor(($full / $design) * 100)
    }
    else {
        $healthPc = 0
    }

    # Output object
    [PSCustomObject]@{
        DesignCapacity     = $design
        FullChargeCapacity = $full
        BatteryHealthPct   = $healthPc
        CycleCount         = $battery.CycleCount
        Id                 = $battery.Id
    }

    # Health category
    if ($healthPc -gt $InfoAlertPercent) {
        $BatteryHealth = "Great"
    }
    elseif ($healthPc -gt $WarnAlertPercent) {
        $BatteryHealth = "OK"
    }
    elseif ($healthPc -gt $CritAlertPercent) {
        $BatteryHealth = "Low"
    }
    else {
        $BatteryHealth = "Critical"
    }

    yellow "Battery Health: $BatteryHealth"
}


