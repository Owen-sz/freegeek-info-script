#!/usr/bin/env pwsh # This shebang is for testing purposes. Not needed on Windows hosts

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

red "Installing Windows Update Module..."

Install-Module PSWindowsUpdate -Force
Import-Module PSWindowsUpdate

red "-----Opening windows for Windows update and package updates. Reboot when both are complete.-----"

start-process powershell {winget install libreoffice crystaldiskinfo; winget upgrade --all --include --unknown --silent --force}
start-process powershell {Install-WindowsUpdate -MicrosoftUpdate -Install -AcceptAll}

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
