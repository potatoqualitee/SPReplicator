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
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
    param (
        [switch]$EnableException
    )
    process {
        Reset-PSFConfig -Module SPReplicator -Name *
        Get-SPRConfig
    }
}
