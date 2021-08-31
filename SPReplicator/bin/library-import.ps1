# Help on-prem work in Core
if ($PSVersionTable.PSEdition -eq "Core") {
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.Runtime.Portable.dll" -Verbose
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.Portable.dll" -Verbose
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.UserProfiles.Portable.dll" -Verbose
}

Import-Module "$script:ModuleRoot\bin\PnP.PowerShell" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue