Function Connect-SPRSite {
<#
.SYNOPSIS
    Creates a reusable SharePoint Client Context object that lets you use and
    manage the site collection in Windows PowerShell.

.DESCRIPTION
    Creates a reusable SharePoint Client Context object that lets you use
    and manage the site collection in Windows PowerShell.

    If you Connect-SPRSite, you no longer need to specify -Site and -Credential.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local

    Creates a web service object for intranet.ad.local. Figures out the wsdl address automatically.

.EXAMPLE
    Connect-SPRSite -Site https://intranet.ad.local/

    Creates a web service object for intranet.ad.local using the formal and complete address.

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local -Credential (Get-Credential ad\user)

    Creates a web service object and logs into the webapp as ad\user.

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local -Credential (Get-Credential me@mycorp.onmicrosoft.com) -Location Online

    Creates a connection to SharePoint Online using the credential me@mycorp.onmicrosoft.com
    
    By default, this module is set to On-Premises. To change this use: Set-SPRConfig -Name Location -Value Online 
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [ValidateSet("OnPrem", "Online")]
        [string]$Location,
        [switch]$EnableException
    )
    begin {
        if ($Site -notmatch 'http') {
            $Site = "https://$Site"
        }
    }
    process {
        Write-PSFMessage -Level Verbose -Message "Connecting to the SharePoint service at $Site"
        try {
            $global:spsite = New-Object Microsoft.SharePoint.Client.ClientContext($Site)
            
            if ($Credential) {
                if (-not $Location) {
                    $Location = Get-PSFConfigValue -FullName SPReplicator.Location
                }
                
                if ($Location -eq "Onprem") {
                    $global:spsite.Credentials
                }
                else {
                    $username = $Credential.UserName
                    $password = $Credential.Password
                    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $password)
                    $global:spsite.Credentials = $credentials
                }
            }
            
            $global:spsite.ExecuteQuery()
            
            Add-Member -InputObject $global:spsite -MemberType ScriptMethod -Name ToString -Value { $this.Url } -Force
            $global:spsite | Select-DefaultView -Property Url, ServerVersion, AuthenticationMode, Credential, RequestTimeout
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
        }
    }
}