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

.PARAMETER Id
    Return only rows with specific IDs

.PARAMETER View
    Return only rows from a specific view
    
.PARAMETER Since
    Show only files modified since a specific date.
    
.PARAMETER InputObject
    Allows piping from Get-SPRList

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Set-SPRLogList -Site intranet.ad.local -List 'My List'

    Gets data from My List on intranet.ad.local. Figures out the wsdl address automatically.
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [string]$List,
        [int[]]$Id,
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
            
            $columns = $InputObject | Get-SPRColumnDetail
            
            $command = '*-SPR*:LogToList'
            if ($PSDefaultParameterValues[$command]) {
                $PSDefaultParameterValues.Remove($command)
            }
            $PSDefaultParameterValues.Add($command, $InputObject)
            $PSDefaultParameterValues[$command]
            
            $global:SPReplicator = [pscustomobject]@{
                Web     = $script:spweb
                Site    = $script:spsite
                LogList = $PSDefaultParameterValues['*-SPR*:LogToList']
            }
            
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
        }
    }
}