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

.PARAMETER AuthenticationMode
    Specifies the authentication modes of the client Web request.

.PARAMETER Location
    Onprem or Online
    
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
        [ValidateSet("Default", "FormsAuthentication", "Authentication")]
        [string]$AuthenticationMode = "Default",
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
                    $global:spsite.Credentials = $Credential.GetNetworkCredential()
                    Add-Member -InputObject $global:spsite.Credentials -MemberType ScriptMethod -Name ToString -Value { $Credential.UserName } -Force
                    
                }
                else {
                    if ($PSVersionTable.PSEdition -eq "Core") {
                        Stop-PSFFunction -Message "Core works with Onprem but not yet SharePoint online, waiting for working DLL :("
                        return
                    }
                    else {
                        $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credential.UserName, $Credential.Password)
                        $global:spsite.Credentials = $credentials
                        Add-Member -InputObject $global:spsite.Credentials -MemberType ScriptMethod -Name ToString -Value { $this.UserName } -Force
                    }
                }
            }
            
            if ($global:spsite.HasPendingRequest) {
                $global:spsite.ExecuteQueryAsync().Wait()
            }
            
            Add-Member -InputObject $global:spsite -MemberType ScriptMethod -Name ToString -Value { $this.Url } -Force
            
            if (-not $global:spsite.ExecuteQuery) {
                # ty https://rajujoseph.com/getting-net-core-and-sharepoint-csom-play-nice/
                Add-Member -InputObject $global:spsite -MemberType ScriptMethod -Name ExecuteQuery -Value {
                    if ($global:spsite.HasPendingRequest) {
                        $global:spsite.ExecuteQueryAsync().Wait()
                    }
                } -Force
            }
            $global:spsite.AuthenticationMode = $AuthenticationMode
            $global:spsite.ExecuteQuery()
            $global:spweb = $global:spsite.Web
            
            if ($global:spsite.Credentials) {
                $loginname = Get-SPRUser -UserName $global:spsite.Credentials.UserName
            }
            else {
                $username = whoami
                $loginname = Get-SPRUser -UserName $username
            }
            
            Add-Member -InputObject $global:spsite -MemberType NoteProperty -Name CurrentUser -Value $loginname -Force
            
            $global:spsite | Select-DefaultView -Property Url, ServerVersion, AuthenticationMode, Credentials, RequestTimeout, CurrentUser
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
        }
    }
}