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
    Onprem or Online, this only needs to be set once, then it's cached. See Get-SPRConfig for more information.
    
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
    Connect-SPRSite -Site intranet.ad.local -Credential ad\user

    Creates a web service object and logs into the webapp as ad\user.

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local -Credential me@mycorp.onmicrosoft.com -Location Online

    Creates a connection to SharePoint Online using the credential me@mycorp.onmicrosoft.com
    
    By default, this module is set to On-Premises. To change this use: Set-SPRConfig -Name Location -Value Online 
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [string]$Location,
        [ValidateSet("Default", "FormsAuthentication", "Authentication")]
        [string]$AuthenticationMode = "Default",
        [switch]$EnableException
    )
    begin {
        if ($Site -notmatch 'http') {
            $Site = "https://$Site"
        }
        
        # handle online vs onprem
        $hostname = ([System.Uri]$Site).Host
        $hash = Get-PSFConfigValue -FullName SPReplicator.SiteMapper
        
        if (-not $Location) {
            $hash = Get-PSFConfigValue -FullName SPReplicator.SiteMapper
            $Location = $hash[$hostname]
            if (-not $Location) {
                $Location = Get-PSFConfigValue -FullName SPReplicator.Location
            }
        }
        if ($hash[$hostname]) {
            $hash[$hostname] = $Location
        }
        else {
            $hash.Add($hostname, $Location)
        }
        
        Set-PSFConfig -FullName SPReplicator.SiteMapper -Value $hash -Description "Hosts and locations"
    }
    process {
        Write-PSFMessage -Level Verbose -Message "Connecting to the SharePoint service at $Site"
        try {
            $script:spsite = New-Object Microsoft.SharePoint.Client.ClientContext($Site)
            
            if ($Credential) {
                if ($Location -eq "Onprem") {
                    $script:spsite.Credentials = $Credential.GetNetworkCredential()
                    Add-Member -InputObject $script:spsite.Credentials -MemberType ScriptMethod -Name ToString -Value { $Credential.UserName } -Force
                }
                else {
                    if ($PSVersionTable.PSEdition -eq "Core") {
                        Stop-PSFFunction -Message "Core works with Onprem but not yet SharePoint online, waiting for working DLL :("
                        return
                    }
                    else {
                        $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credential.UserName, $Credential.Password)
                        $script:spsite.Credentials = $credentials
                        Add-Member -InputObject $script:spsite.Credentials -MemberType ScriptMethod -Name ToString -Value { $this.UserName } -Force
                    }
                }
            }
            
            if ($script:spsite.HasPendingRequest) {
                $script:spsite.ExecuteQueryAsync().Wait()
            }
            
            Add-Member -InputObject $script:spsite -MemberType ScriptMethod -Name ToString -Value { $this.Url } -Force
            
            if (-not $script:spsite.ExecuteQuery) {
                # ty https://rajujoseph.com/getting-net-core-and-sharepoint-csom-play-nice/
                Add-Member -InputObject $script:spsite -MemberType ScriptMethod -Name ExecuteQuery -Value {
                    if ($script:spsite.HasPendingRequest) {
                        $script:spsite.ExecuteQueryAsync().Wait()
                    }
                } -Force
            }
            $script:spsite.AuthenticationMode = $AuthenticationMode
            $script:spsite.ExecuteQuery()
            $script:spweb = $script:spsite.Web
            
            if ($script:spsite.Credentials) {
                $loginname = Get-SPRUser -UserName $script:spsite.Credentials.UserName
            }
            else {
                $username = whoami
                $loginname = Get-SPRUser -UserName $username
            }
            
            $script:spsite.Load($script:spweb)
            $script:spsite.ExecuteQuery()
            $script:spsite.Load($script:spweb.Lists)
            $script:spsite.ExecuteQuery()
            
            Register-PSFTeppScriptblock -Name List -ScriptBlock { $script:spweb.Lists.Title }
            Register-PSFTeppArgumentCompleter -Command (Get-Command -Module SPReplicator).Name -Parameter List -Name List
            
            Add-Member -InputObject $script:spsite -MemberType NoteProperty -Name CurrentUser -Value $loginname -Force
            $global:SPReplicator = [pscustomobject]@{
                Web     = $script:spweb
                Site    = $script:spsite
                LogList = $global:SPReplicator.LogList
            }
            $script:spsite | Select-DefaultView -Property Url, ServerVersion, AuthenticationMode, Credentials, RequestTimeout, CurrentUser
            
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
        }
    }
}