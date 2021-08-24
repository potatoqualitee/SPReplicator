Get-ChildItem "$script:ModuleRoot\bin\" -Recurse | Unblock-File -ErrorAction SilentlyContinue


if ($PSVersionTable.PSEdition -eq "Core") {
    Add-Type -Path "$script:ModuleRoot\bin\PnP.Framework.dll"
    Add-Type -Path "$script:ModuleRoot\bin\PnP.Core.dll"
    Add-Type -Path "$script:ModuleRoot\bin\PnP.Core.Auth.dll"
    Add-Type -Path "$script:ModuleRoot\bin\PnP.PowerShell.dll"
} else {
    Import-Module "$script:ModuleRoot\bin\PnP.Framework.dll"
    Import-Module "$script:ModuleRoot\bin\PnP.Core.dll"
    Import-Module "$script:ModuleRoot\bin\PnP.Core.Auth.dll"
    Add-Type -Path "$script:ModuleRoot\bin\PnP.PowerShell.dll"
}