Import-Module "$script:ModuleRoot\bin\PnP.PowerShell" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
$pnpbin = Split-Path -Path (Get-Module -Name PnP.PowerShell).Path

if ($PSVersionTable.PSEdition -eq "Core") {
    $script:pnplibs = @("$pnpbin\Core\Microsoft.SharePoint.Client.Runtime.dll","$pnpbin\Core\Microsoft.SharePoint.Client.dll")
} else {
    $script:pnplibs = @("$pnpbin\Framework\Microsoft.SharePoint.Client.Runtime.dll","$pnpbin\Framework\Microsoft.SharePoint.Client.dll")
}