$PSModulePath = $PSScriptRoot
Get-ChildItem "$PSScriptRoot\bin\" -Recurse | Unblock-File
Add-Type -Path "$PSScriptRoot\bin\Microsoft.SharePoint.Client.dll"
Add-Type -Path "$PSScriptRoot\bin\Microsoft.SharePoint.Client.Runtime.dll"

foreach ($function in (Get-ChildItem -Recurse "$PSScriptRoot\functions\*.ps1"))
{
	$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($function))), $null, $null)
}


# Register that script block
Register-PSFTeppScriptblock -Name Template -ScriptBlock { Get-SPRListTemplate | Where-Object Id -ne -1 | Select-Object -ExpandProperty Template }

# Register the actual auto completer
Register-PSFTeppArgumentCompleter -Command New-SPRList -Parameter Template -Name Template