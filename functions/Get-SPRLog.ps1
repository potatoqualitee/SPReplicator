Function Get-SPRLog {
<#
.SYNOPSIS
    Get list of SharePoint templates.

.DESCRIPTION
    Get list of SharePoint templates.

.PARAMETER Id
    Return only templates with specific IDs

.PARAMETER Name
    Return only templates with specific names
    
.PARAMETER Level
    The message level. Valid values include: 'Critical', 'Debug', 'Host', 'Important', 'InternalComment', 'Output', 'Significant', 'SomewhatVerbose', 'System', 'Verbose', 'VeryVerbose', and 'Warning'
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRLog

    Gets all SPReplicator logs
#>
    [CmdletBinding()]
    param (
        [ValidateSet('Critical', 'Debug', 'Host', 'Important', 'InternalComment', 'Output', 'Significant', 'SomewhatVerbose', 'System', 'Verbose', 'VeryVerbose', 'Warning')]
        [string[]]$Level = "Verbose",
        [switch]$EnableException
    )
    process {
        Get-PSFMessage -ModuleName SPReplicator -Level $Level
    }
}