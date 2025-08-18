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

start-process powershell {Install-WindowsUpdate -AcceptAll}

red "Opening new window to run Windows updates. Reboot when complete."

# CPUs

function cpu {
    Get-WmiObject -Class Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors
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
