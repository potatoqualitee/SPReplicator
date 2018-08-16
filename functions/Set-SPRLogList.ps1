Function Set-SPRLogList {
<#
.SYNOPSIS
    Sets the default logging SharePoint list. Must be a list created by New-SPRLogList.

.DESCRIPTION
    Sets the default logging SharePoint list. Must be a list created by New-SPRLogList.
    
    It sets this for all commands capable of logging, by setting the session's $PSDefaultParameterValues.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER List
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.
   
.PARAMETER Web
    The human readable web name. So 'My Web' as opposed to 'MyWeb', unless you named it MyWeb.
    
.PARAMETER InputObject
    Allows piping from Get-SPRList

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Set-SPRLogList -Site intranet.ad.local -Web Whatever -List SPReplicator

    Sets the logging list to SPReplicator in the Whatever web
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [string]$List,
        [Parameter(Position = 1, HelpMessage = "Human-readble SharePoint web name")]
        [string[]]$Web,
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SprList -Site $Site -Credential $Credential -List $List -Web $Web
            }
            elseif ($script:spsite) {
                $InputObject = Get-SPRList -List $List -Web $Web
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and List pipe in results from Get-SPRList"
                return
            }
        }
        try {
            
            $columns = $InputObject | Get-SPRColumnDetail | Select-Object -ExpandProperty Name
            
            if ($columns -notcontains 'FinishTime' -and $columns -notcontains 'RunAs') {
                Stop-PSFFunction -EnableException:$EnableException -Message "List is not an SPReplicator Log list. Use New-SPRLogList to create a new logging list."
                return
            }
            
            $PSDefaultParameterValues = Get-Variable -Name PSDefaultParameterValues -Scope 2 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value
            
            $command = '*-SPR*:LogToList'
            
            if ($PSDefaultParameterValues[$command]) {
                $PSDefaultParameterValues.Remove($command)
            }
            $PSDefaultParameterValues.Add($command, $InputObject)
            $global:SPReplicator.LogList = $PSDefaultParameterValues['*-SPR*:LogToList']
            Set-Variable -Name PSDefaultParameterValues -Scope 2 -Value $PSDefaultParameterValues -ErrorAction SilentlyContinue
            Get-SPRLogList
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
        }
    }
}