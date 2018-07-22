<#
.SYNOPSIS
This script will invoke Pester tests, then serialize XML results and pull them in appveyor.yml

.DESCRIPTION
This script will invoke Pester tests, then serialize XML results and pull them in appveyor.yml

.PARAMETER Finalize
If Finalize is specified, we collect XML output, upload tests, and indicate build errors

.PARAMETER PSVersion
The version of PS

.PARAMETER TestFile
The output file

.PARAMETER ProjectRoot
The appveyor project root

.PARAMETER ModuleBase
The location of the module

.EXAMPLE
.\appveyor.pester.ps1
Executes the test

.EXAMPLE
.\appveyor.pester.ps1 -Finalize
Finalizes the tests
#>
param (
    [switch]$Finalize,
    $PSVersion = $PSVersionTable.PSVersion.Major,
    $TestFile = "PesterResults$PSVersion.xml",
    $ProjectRoot = $ENV:APPVEYOR_BUILD_FOLDER,
    $ModuleBase = $ProjectRoot
)

# Move to the project root
Set-Location $ModuleBase
Import-Module "$ModuleBase\SPReplicator.psd1"

$alltests = @()
#$alltests += Get-ChildItem "$ModuleBase\tests\InModule.Help.Tests.ps1"
$alltests += Get-ChildItem "$ModuleBase\tests\Integration.Online.Tests.ps1"
$results = Invoke-Pester $alltests -PassThru

#$totalcount = $results | Select-Object -ExpandProperty TotalCount | Measure-Object -Sum | Select-Object -ExpandProperty Sum
$failedcount = $results | Select-Object -ExpandProperty FailedCount | Measure-Object -Sum | Select-Object -ExpandProperty Sum
if ($failedcount -gt 0) {
    $faileditems = $results | Select-Object -ExpandProperty TestResult | Where-Object { $_.Passed -notlike $True }
    if ($faileditems) {
        Write-Warning "Failed tests summary:"
        $faileditems | ForEach-Object {
            $name = $_.Name
            [pscustomobject]@{
                Describe = $_.Describe
                Context  = $_.Context
                Name     = "It $name"
                Result   = $_.Result
                Message  = $_.FailureMessage
            }
        } | Sort-Object Describe, Context, Name, Result, Message | Format-List
        throw "$failedcount tests failed."
    }
}