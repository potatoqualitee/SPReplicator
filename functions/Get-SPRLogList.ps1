Function Get-SPRLogList {
<#
.SYNOPSIS
    Gets the default logging SharePoint list, if one is set.
    
.DESCRIPTION
    Gets the default logging SharePoint list, if one is set.

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRLogList

    Gets the default logging SharePoint list, if one is set.
#>
    [CmdletBinding()]
    param (
        [switch]$EnableException
    )
    process {
        #(Get-Variable -Name PSDefaultParameterValues -Scope 2 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value)['*-SPR*:LogToList']
        $global:SPReplicator.LogList
    }
}