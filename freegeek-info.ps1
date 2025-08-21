#!/usr/bin/env pwsh # This shebang is for testing purposes. Not needed on Windows hosts

#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Set-PSRepository PSGallery -InstallationPolicy Trusted; Install-PackageProvider NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -ForceBootstrap; Import-PackageProvider NuGet -Name NuGet -Force; Install-Module PSWindowsUpdate -Repository PSGallery -Scope AllUsers -Force -Confirm:$false -SkipPublisherCheck -AllowClobber -AcceptLicense; Import-Module PSWindowsUpdate


# colors wowee

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

# Module for Windows update powershell window

red "Installing PSWindowsUpdate and dependencies…"

Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-PackageProvider NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -ForceBootstrap
Import-PackageProvider NuGet -Force

Install-Module PSWindowsUpdate -Repository PSGallery -Scope AllUsers -Force -Confirm:$false -AllowClobber -SkipPublisherCheck
Import-Module PSWindowsUpdate

red "-----Opening windows for Windows update and package updates. Reboot when both are complete.-----"

Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -Command "winget install libreoffice crystaldiskinfo; winget upgrade --all --include --unknown --silent --force"' -Wait

start-process PowerShell -Verb RunAs -ArgumentList 'NoProfile -ExecutionPolicy Bypass -NoExit -Command "Install-WindowsUpdate -MicrosoftUpdate -Install -AcceptAll"' -Wait

# CPUs

function cpu {
    Get-WmiObject -Class Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors
		# possibly use this: Get-CmiInstance Win32_Processor | Select-Object Name, NumberOfCores, ThreadCount
}

yellow "CPU: cpu"
# yellow Cores:
# yellow Threads:

# GPUs

function gpu {
    Get-WmiObject win32_VideoController | Format-List Name
}

yellow "GPU: gpu"
# RAM

# Disk

# Battery

# Port Stuff
