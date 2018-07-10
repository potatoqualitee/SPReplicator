Function Connect-SPRSite {
<#
.SYNOPSIS
    Creates a SharePoint Client Context object that lets you use and manage the site collection in Windows PowerShell.
    
.DESCRIPTION
    Creates a SharePoint Client Context object that lets you use and manage the site collection in Windows PowerShell.
    
.PARAMETER Uri
    The address to the site collection. You can also pass a hostname and it'll figure it out.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials. 
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
 
.EXAMPLE
    Connect-SPRSite -Uri intranet.ad.local

    Creates a web service object for intranet.ad.local. Figures out the wsdl address automatically.
    
.EXAMPLE
    Connect-SPRSite -Uri https://intranet.ad.local/

    Creates a web service object for intranet.ad.local using the formal and complete address.
    
.EXAMPLE
    Connect-SPRSite -Uri intranet.ad.local -Credential (Get-Credential ad\user)

    Creates a web service object and logs into the webapp as ad\user.
            
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage = "SharePoint Site Collection")]
        [string]$Uri,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    begin {
        if ($Uri -notmatch 'http') {
            $Uri = "https://$Uri"
        }    
    }
    process {
        Write-PSFMessage -Level Verbose -Message "Connecting to the SharePoint service at $Uri"
        try {
            $global:spsite = New-Object Microsoft.SharePoint.Client.ClientContext($Uri)
            if ($Credential) {
                $global:spsite.Credentials
            }
            $global:spsite.ExecuteQuery()
            
            Add-Member -InputObject $global:spsite -MemberType ScriptMethod -Name ToString -Value { $this.Url } -Force -PassThru
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
        }
    }
}