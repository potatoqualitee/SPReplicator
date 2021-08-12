param (
	$Show = "None"
)

Write-Host "Starting Tests" -ForegroundColor Green
if ($env:BUILD_BUILDURI -like "vstfs*") {
	Write-Host "Installing Pester" -ForegroundColor Cyan
	Install-Module Pester -RequiredVersion 4.10.1 -Force -SkipPublisherCheck
	Write-Host "Installing PSFramework" -ForegroundColor Cyan
	Invoke-WebRequest "https://raw.githubusercontent.com/PowershellFrameworkCollective/psframework/master/install.ps1" -UseBasicParsing | Invoke-Expression
}

Write-PSFMessage -Level Important -Message "Loading constants"
. "$PSScriptRoot\constants.ps1"

Write-PSFMessage -Level Important -Message "Importing Module"

Remove-Module SPReplicator -ErrorAction Ignore
Import-Module "$PSScriptRoot\..\SPReplicator.psd1"
Import-Module "$PSScriptRoot\..\SPReplicator.psm1" -Force

$totalFailed = 0
$totalRun = 0

$testresults = @()
<#
Write-PSFMessage -Level Important -Message "Modules imported, proceeding with general tests"
foreach ($file in (Get-ChildItem "$PSScriptRoot\general" -Filter "*.Tests.ps1"))
{
	Write-PSFMessage -Level Significant -Message "  Executing <c='em'>$($file.Name)</c>"
	$results = Invoke-Pester -Script $file.FullName -Show $Show -PassThru
	foreach ($result in $results)
	{
		$totalRun += $result.TotalCount
		$totalFailed += $result.FailedCount
		$result.TestResult | Where-Object { -not $_.Passed } | ForEach-Object {
			$name = $_.Name
			$testresults += [pscustomobject]@{
				Describe  = $_.Describe
				Context   = $_.Context
				Name	  = "It $name"
				Result    = $_.Result
				Message   = $_.FailureMessage
			}
		}
	}
}
#>

Write-PSFMessage -Level Important -Message "Proceeding with individual tests"
foreach ($file in (Get-ChildItem "$PSScriptRoot\functions" -Recurse -File -Filter "*Online.Tests.ps1")) {
	Write-PSFMessage -Level Significant -Message "  Executing $($file.Name)"
	$results = Invoke-Pester -Script $file.FullName -PassThru
	foreach ($result in $results) {
		$totalRun += $result.TotalCount
		$totalFailed += $result.FailedCount
		$result.TestResult | Where-Object { -not $_.Passed } | ForEach-Object {
			$name = $_.Name
			$testresults += [pscustomobject]@{
				Describe = $_.Describe
				Context  = $_.Context
				Name     = "It $name"
				Result   = $_.Result
				Message  = $_.FailureMessage
			}
		}
	}
}

$testresults | Sort-Object Describe, Context, Name, Result, Message | Format-List

if ($totalFailed -eq 0) { Write-PSFMessage -Level Critical -Message "All <c='em'>$totalRun</c> tests executed without failure" }
else { Write-PSFMessage -Level Critical -Message "<c='em'>$totalFailed tests</c> out of <c='sub'>$totalRun</c> tests failed" }

if ($totalFailed -gt 0) {
	throw "$totalFailed / $totalRun tests failed"
}