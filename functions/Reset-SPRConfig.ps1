function Reset-SPRConfig {
<#
.SYNOPSIS
    Resets all SPReplicator configuration elements.

.DESCRIPTION
    Resets all SPReplicator configuration elements.

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
    
.EXAMPLE
    Reset-SPRConfig
    
    Resets all SPReplicator configuration elements.
#>
    [CmdletBinding()]
    param (
        [switch]$EnableException
    )
    process {
        # doing two times to ensure it works
        Set-PSFConfig -Module SPReplicator -Name Location -Value Onprem -Description "Specifies primary location: SharePoint Online (Online) or On-Premises (Onprem)" -Initialize
        Set-PSFConfig -Module SPReplicator -Name Location -Value Onprem -Description "Specifies primary location: SharePoint Online (Online) or On-Premises (Onprem)"
        Set-PSFConfig -Module SPReplicator -Name SiteMapper -Value @{ } -Description "Hosts and locations (online vs onprem)" -Initialize
        Set-PSFConfig -Module SPReplicator -Name SiteMapper -Value @{ } -Description "Hosts and locations (online vs onprem)"
        Get-SPRConfig
    }
}
