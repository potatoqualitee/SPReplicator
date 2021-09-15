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
    Specifies the authentication mode. Default is "Default". Other options are WebLogin and AppOnly

.PARAMETER Location
    Onprem or Online, this only needs to be set once, then it's cached. See Get-SPRConfig for more information.

.PARAMETER AccessToken
    The access token used when AuthenticationMode is AccessToken.

.PARAMETER Tenant
    The Azure AD Tenant name,e.g. mycompany.onmicrosoft.com

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

.EXAMPLE
    Connect-SPRSite -Site https://corp.sharepoint.com -AuthenticationMode WebLogin

    Pops open a browser and logs into SharePoint Online using a token that you paste into the browser

.EXAMPLE
    Connect-SPRSite -Site https://corp.sharepoint.com -AuthenticationMode AppOnly -Credential 1e36c5cc-5281-4235-a84f-c94dc2de8800

    Logs into SharePoint Online using the AppOnly token. Please ensure you've followed all of the steps at https://docs.microsoft.com/en-us/sharepoint/dev/solution-guidance/security-apponly-azureacs

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [PsfValidateSet(TabCompletion = 'SPReplicator-Location')]
        [string]$Location = (Get-PSFConfigValue -FullName SPReplicator.Location),
        [ValidateSet("Default", "WebLogin", "AppOnly", "ManagedIdentity", "AccessToken")]
        [string]$AuthenticationMode = "Default",
        [string]$Tenant,
        [string]$AccessToken,
        [switch]$EnableException
    )
    begin {
        $PSDefaultParameterValues['Connect-PnPOnline:ReturnConnection'] = $true
        $PSDefaultParameterValues['Connect-PnPOnline:Site'] = $Site

        if ($Tenant) {
            $PSDefaultParameterValues['Connect-PnPOnline:Tenant'] = $Tenant
        }
        if ($Site -notmatch 'http') {
            $Site = "https://$Site"
        }
        # handle online vs onprem
        $hostname = ([System.Uri]$Site).Host
        $hash = Get-PSFConfigValue -FullName SPReplicator.SiteMapper

        if (-not $Location) {
            $hash = Get-PSFConfigValue -FullName SPReplicator.SiteMapper
            if ($hash[$hostname]) {
                $Location = $hash[$hostname]
            } else {
                $Location = Get-PSFConfigValue -FullName SPReplicator.Location
            }
        }
        if ($hash[$hostname]) {
            $hash[$hostname] = $Location
        } else {
            $hash.Add($hostname, $Location)
        }

        Set-PSFConfig -FullName SPReplicator.SiteMapper -Value $hash -Description "Hosts and locations"
    }
    process {
        Write-PSFMessage -Level Verbose -Message "Connecting to the SharePoint service at $Site"
        Write-PSFMessage -Level Verbose -Message "Site is set as $Location"

        if ($AuthenticationMode -eq "AccessToken" -and -not $AccessToken) {
            Stop-PSFFunction -Message "AccessToken authentication mode requires an AccessToken"
            return
        }

        try {
            switch ($AuthenticationMode) {
                "WebLogin" {
                    Write-PSFMessage -Level Verbose -Message "Proceeding with WebLogin mode"
                    try {
                        $script:spsite = (Connect-PnPOnline -LaunchBrowser -PnPManagementShell).Context
                        $script:spsite.Load($script:spsite.Web)
                        $script:spsite.ExecuteQuery()
                    } catch {
                        Stop-PSFFunction -Message "Could not connect to $Site" -ErrorRecord $_
                        return
                    }
                }

                "ManagedIdentity" {
                    Write-PSFMessage -Level Verbose -Message "Proceeding with ManagedIdentity mode"
                    try {
                        $script:spsite = (Connect-PnPOnline -ManagedIdentity -WarningAction Ignore).Context
                        $script:spsite.Load($script:spsite.Web)
                        $script:spsite.ExecuteQuery()
                    } catch {
                        Stop-PSFFunction -Message "Could not connect to $Site" -ErrorRecord $_
                        return
                    }
                }

                "AccessToken" {
                    Write-PSFMessage -Level Verbose -Message "Proceeding with AccessToken mode"
                    try {
                        $script:spsite = (Connect-PnPOnline -AccessToken $AccessToken).Context
                        $script:spsite.Load($script:spsite.Web)
                        $script:spsite.ExecuteQuery()
                    } catch {
                        Stop-PSFFunction -Message "Could not connect to $Site" -ErrorRecord $_
                        return
                    }
                }

                "AppOnly" {
                    Write-PSFMessage -Level Verbose -Message "Proceeding with AppOnly mode"
                    try {
                        $script:spsite = (Connect-PnPOnline -ClientSecret $Credential.GetNetworkCredential().Password -ClientId $Credential.UserName -WarningAction Ignore).Context
                        $script:spsite.Load($script:spsite.Web)
                        $script:spsite.ExecuteQuery()
                    } catch {
                        Stop-PSFFunction -Message "Could not connect to $Site. Please check that you've followed all the steps at https://docs.microsoft.com/en-us/sharepoint/dev/solution-guidance/security-apponly-azureacs" -ErrorRecord $_
                        return
                    }
                }

                default {
                    #Setup Authentication Manager
                    Write-PSFMessage -Level Verbose -Message "Proceeding with default login mode"
                    if ($Credential) {
                        Write-PSFMessage -Level Verbose -Message "Credential detected"
                        if ($Location -eq "Onprem") {
                            Write-PSFMessage -Level Verbose -Message "Connecting to OnPrem"
                            $script:spsite = (Connect-PnPOnline -Credential $Credential -TransformationOnPrem).Context
                            if ($script:spsite.Credentials) {
                                Add-Member -InputObject $script:spsite.Credentials -MemberType ScriptMethod -Name ToString -Value { $this.UserName } -Force
                            }
                        } else {
                            Write-PSFMessage -Level Verbose -Message "Connecting to SharePoint online"
                            $script:spsite = (Connect-PnPOnline -Credential $Credential).Context
                            if ($script:spsite.Credentials) {
                                Add-Member -InputObject $script:spsite.Credentials -MemberType ScriptMethod -Name ToString -Value { $this.UserName } -Force
                            }
                        }
                    } else {
                        if ($PSVersionTable.PSEdition -eq "Core") {
                            Write-PSFMessage -Level Verbose -Message "No credential detected, connecting using PS Core"
                            $script:spsite = (Connect-PnPOnline -TransformationOnPrem -CurrentCredential -WarningAction Ignore).Context
                        } else {
                            # This is required for non-core ¯\_(ツ)_/¯
                            Write-PSFMessage -Level Verbose -Message "No credential detected, connecting using Windows PowerShell"
                            $script:spsite = New-Object Microsoft.SharePoint.Client.ClientContext($Site)
                        }
                    }
                }
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

            $script:spweb = $script:spsite.Web
            Add-Member -InputObject $script:spweb -MemberType ScriptMethod -Name ToString -Value { $this.Title } -Force

            $script:spsite.Load($script:spweb.CurrentUser)
            $script:spsite.ExecuteQuery()
            $loginname = $script:spweb.CurrentUser.LoginName

            $script:spsite.Load($script:spweb)
            $script:spsite.ExecuteQuery()
            $script:spsite.Load($script:spweb.Lists)
            $script:spsite.ExecuteQuery()

            $global:SPReplicator.Web = $script:spweb
            $global:SPReplicator.Site = $script:spsite
            $global:SPReplicator.LogList = $global:SPReplicator.LogList
            $global:SPReplicator.ListNames = $script:spweb.Lists.Title

            Register-PSFTeppScriptblock -Name List -ScriptBlock {
                $global:SPReplicator.ListNames
            }
            Register-PSFTeppArgumentCompleter -Command (Get-Command -Module SPReplicator).Name -Parameter List -Name List

            if ($credentials) {
                $thislocation = "Online"
            } else {
                $thislocation = "Onprem"
            }

            $getsite = $script:spsite.get_site()
            $script:spsite.Load($getsite)
            $script:spsite.ExecuteQuery()
            $rootweb = $getsite.get_rootWeb()

            Add-Member -InputObject $rootweb -MemberType ScriptMethod -Name ToString -Value { $this.Title } -Force
            Add-Member -InputObject $script:spsite -MemberType NoteProperty -Name RootWeb -Value $rootweb -Force
            Add-Member -InputObject $script:spsite -MemberType NoteProperty -Name Location -Value $thislocation -Force
            Add-Member -InputObject $script:spsite -MemberType NoteProperty -Name CurrentUser -Value $loginname -Force
            $script:spsite | Select-DefaultView -Property Url, ServerVersion, RequestTimeout, RootWeb, CurrentUser
        } catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
        }
    }
}