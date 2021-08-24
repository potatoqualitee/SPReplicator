Get-ChildItem "$script:ModuleRoot\bin\" -Recurse | Unblock-File -ErrorAction SilentlyContinue
Add-Type -Path "$script:ModuleRoot\bin\PnP.Framework.dll"
Add-Type -Path "$script:ModuleRoot\bin\PnP.Core.dll"

if ($PSVersionTable.PSEdition -eq "Core") {
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.Runtime.Portable.dll"
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.Portable.dll"
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.UserProfiles.Portable.dll"
} else {
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.dll"
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.Runtime.dll"
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.UserProfiles.dll"
}