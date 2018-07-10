Function Disconnect-SPRSite {
<#
.SYNOPSIS
    Disconnects a SharePoint Client Context object that lets you use and manage the site collection in Windows PowerShell.
    
.DESCRIPTION
    Disconnects a SharePoint Client Context object that lets you use and manage the site collection in Windows PowerShell.
    
.PARAMETER Uri
    The address to the site collection. You can also pass a hostname and it'll figure it out.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials. 
    
.PARAMETER InputObject
    Allows piping of server/spsite objects
  
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
 
.EXAMPLE
    Disconnect-SPRSite -Uri intranet.ad.local

    Creates a web service object for intranet.ad.local. Figures out the wsdl address automatically.
    
.EXAMPLE
    Disconnect-SPRSite -Uri https://intranet.ad.local/

    Creates a web service object for intranet.ad.local using the formal and complete address.
    
.EXAMPLE
    Disconnect-SPRSite -Uri intranet.ad.local -Credential (Get-Credential ad\user)

    Creates a web service object and logs into the webapp as ad\user.
            
#>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Uri,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Uri) {
                Write-PSFMessage -Level Verbose -Message "Connecting to the SharePoint service at $Uri"
                $InputObject = Connect-SPRSite -Uri $Uri -Credential $Credential
            }
            elseif ($global:server) {
                $InputObject = $global:server
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Uri or run Connect-SPRSite"
                return
            }
        }
        try {
            Write-PSFMessage -Level Verbose -Message "Disconnecting to the SharePoint service at $($InputObject.Url)"
            $InputObject.Dispose()
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
        }
    }
}