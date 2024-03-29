﻿Add-AppveyorTest -Name "appveyor.prep" -Framework NUnit -FileName "appveyor.prep.ps1" -Outcome Running
$sw = [system.diagnostics.stopwatch]::startNew()

#Get PSScriptAnalyzer (to check warnings)
Write-Host -Object "appveyor.prep: Install PSScriptAnalyzer" -ForegroundColor DarkGreen
Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck | Out-Null

#Get Pester (to run tests)
Write-Host -Object "appveyor.prep: Install Pester" -ForegroundColor DarkGreen
#choco install pester --version 4.10.1 | Out-Null
Install-Module -Name Pester -RequiredVersion 4.10.1 -Force -SkipPublisherCheck | Out-Null

#Get PSFramework
Write-Host -Object "appveyor.prep: Install PSFramework" -ForegroundColor DarkGreen
Install-Module -Name PSFramework | Out-Null

#Get PnP.PowerShell
Write-Host -Object "appveyor.prep: Install PnP.PowerShell" -ForegroundColor DarkGreen
Install-Module -Name PnP.PowerShell -RequiredVersion 1.7.0 | Out-Null

$sw.Stop()
Update-AppveyorTest -Name "appveyor.prep" -Framework NUnit -FileName "appveyor.prep.ps1" -Outcome Passed -Duration $sw.ElapsedMilliseconds