Get-ChildItem "$script:ModuleRoot\bin\" -Recurse | Unblock-File -ErrorAction SilentlyContinue

if ($PSVersionTable.PSEdition -eq "Core") {
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.Runtime.Portable.dll"
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.Portable.dll"
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.UserProfiles.Portable.dll"
    Add-Type -Path "$script:ModuleRoot\bin\OfficeDevPnP.Core.dll"
} else {
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.dll"
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.Runtime.dll"
    Add-Type -Path "$script:ModuleRoot\bin\Microsoft.SharePoint.Client.UserProfiles.dll"
    Add-Type -Path "$script:ModuleRoot\bin\OfficeDevPnP.Core.dll"

}