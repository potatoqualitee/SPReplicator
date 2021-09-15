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
        Specifies the authentication mode. Options include Default, WebLogin (pops up a browser), AppOnly, ManagedIdentity and AccessToken

        For AppOnly authentication, please ensure you've followed all of the steps at https://docs.microsoft.com/en-us/sharepoint/dev/solution-guidance/security-apponly-azureacs

    .PARAMETER Location
        Onprem or Online, this only needs to be set once, then it's cached. See Get-SPRConfig for more information.

        If you don't specify Location, SPReplicator will try to determine it based on the Site URL.

    .PARAMETER AccessToken
        This method assumes you have acquired a valid OAuth2 access token from Azure AD with the correct audience and permissions set. Using this method PnP PowerShell will not acquire tokens dynamically and if the token expires (typically after 1 hour), commands will fail to work using this method.

    .PARAMETER Tenant
        The Azure AD Tenant name, For example mycompany.onmicrosoft.com

    .PARAMETER Thumbprint
        The thumbprint of the certificate containing the private key registered with the application in Azure Active Directory.

        Connects to SharePoint using app-only tokens via an app's declared permission scopes. Ensure you have imported the private key certificate, typically the .pfx file, into the Windows Certificate Store for the certificate with the provided thumbprint.

    .PARAMETER ClientId
        The Client ID of the Azure AD Application. Required when Thumbprint is used.

    .PARAMETER CertificateBase64Encoded
        Switch that specifies whether the credential password is a certificate in Base64 encoded format.

        See examples for usage

    .PARAMETER AzureEnvironment
        The Azure environment to use for authentication. Options include Production, PPE, China, Germany, USGovernment, USGovernmentHigh, and USGovernmentDoD

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
        Connect-SPRSite -Site contoso.sharepoint.com -Credential me@mycorp.onmicrosoft.com

        Creates a connection to SharePoint Online using the credential me@mycorp.onmicrosoft.com

    .EXAMPLE
        Connect-SPRSite -Site https://corp.sharepoint.com -AuthenticationMode WebLogin

        Pops open a browser and logs into SharePoint Online using a token that you paste into the browser. This enables MFA, including smartcards.

    .EXAMPLE
        Connect-SPRSite -Site https://corp.sharepoint.com -AuthenticationMode AppOnly -Credential 1e36c5cc-5281-4235-a84f-c94dc2de8800

        Logs into SharePoint Online using the AppOnly token -- use your client secret as the credential password.

    .EXAMPLE
        Connect-SPRSite -Site "https://contoso.sharepoint.de" -AuthenticationMode AppOnly -Credential 344b8aab-389c-4e4a-8fa1-4c1ae2c0a60d

        This will authenticate you to contoso.sharepoint.de using Legacy ACS authentication. Your client secret is the credential password.

    .EXAMPLE
        $cred = Get-Credential usernamedoesntmatter
        Connect-SPRSite -Site https://contoso.sharepoint.de -ClientId 344b8aab-389c-4e4a-8fa1-4c1ae2c0a60d -Credential $cred

        This will authenticate you to contoso.sharepoint.de using Legacy ACS authentication. Use the client secret for the credential password. As suggested, the credential username is not used.

    .EXAMPLE
        Connect-SPRSite -Site https://contoso.sharepoint.com -Credential 6c5c98c7-e05a-4a0f-bcfa-0cfc65aa1f28 -CertificatePath /tmp/mycertificate.pfx  -Tenant contoso.onmicrosoft.com

        Connects using an Azure Active Directory registered application using a locally available certificate containing a private key. Use the certificate secret as the credential password.

    .EXAMPLE
        Connect-SPRSite -Site https://contoso.sharepoint.com -ClientId 6c5c98c7-e05a-4a0f-bcfa-0cfc65aa1f28 -CertificateBase64Encoded -Tenant contoso.onmicrosoft.com

        Connects using an Azure Active Directory registered application using a certificate with a private key that has been base64 encoded. Use the base64 encoded certificate as the credential password.

    .EXAMPLE
        Connect-SPRSite -Site https://contoso.sharepoint.com -ClientId 6c5c98c7-e05a-4a0f-bcfa-0cfc65aa1f28 -Tenant contoso.onmicrosoft.com -Thumbprint 34CFAA860E5FB8C44335A38A097C1E41EEA206AA

        Connects to SharePoint using app-only tokens via an app's declared permission scopes. Ensure you have imported the private key certificate, typically the .pfx file, into the Windows Certificate Store for the certificate with the provided thumbprint.

    .EXAMPLE
        Connect-SPRSite -Site "https://contoso.sharepoint.de" -AuthenticationMode ManagedIdentity

        Using this way of connecting only works with environments that support managed identies: Azure Functions and the Azure Cloud Shell.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [PsfValidateSet(TabCompletion = 'SPReplicator-Location')]
        [string]$Location,
        [ValidateSet("Default", "WebLogin", "AppOnly", "ManagedIdentity", "AccessToken")]
        [string]$AuthenticationMode = "Default",
        [string]$Tenant,
        [string]$Thumbprint,
        [string]$ClientId,
        [string]$AccessToken,
        [ValidateSet("Production", "PPE", "China", "Germany", "USGovernment", "USGovernmentHigh", "USGovernmentDoD")]
        [string]$AzureEnvironment,
        [string]$CertificatePath,
        [switch]$CertificateBase64Encoded,
        [switch]$EnableException
    )
    begin {
        $PSDefaultParameterValues['Connect-PnPOnline:ReturnConnection'] = $true
        $PSDefaultParameterValues['Connect-PnPOnline:Url'] = $Site
        $PSDefaultParameterValues['Connect-PnPOnline:WarningAction'] = "Ignore"

        if ($AzureEnvironment) {
            $PSDefaultParameterValues['Connect-PnPOnline:AzureEnvironment'] = $AzureEnvironment
        }

        if ($Tenant) {
            $PSDefaultParameterValues['Connect-PnPOnline:Tenant'] = $Tenant
        } else {

        }

        if ($Thumbprint -or $ClientId -or $CertificatePath) {
            Write-PSFMessage -Level Verbose -Message "Setting AuthenticationMode to AppOnly"
            $AuthenticationMode = "AppOnly"
        }

        if ($AccessToken) {
            Write-PSFMessage -Level Verbose -Message "Setting AuthenticationMode to AccessToken"
            $AuthenticationMode = "AccessToken"
        }

        if ($Site -notmatch 'http') {
            $Site = "https://$Site"
        }

        # handle online vs onprem
        $hostname = ([System.Uri]$Site).Host
        $hash = Get-PSFConfigValue -FullName SPReplicator.SiteMapper

        if (-not $Location) {
            $hash = Get-PSFConfigValue -FullName SPReplicator.SiteMapper
            if ($AzureEnvironment -or $Tenant -or $AuthenticationMode -in "AppOnly", "ManagedIdentity", "AccessToken" -or $Site -match "\.sharepoint\.") {
                $Location = "Online"
            } elseif ($hash[$hostname]) {
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

        if ($Thumbprint -and -not $ClientId) {
            Stop-PSFFunction -Message "Thumbprint requires a corresponding ClientId"
            return
        }

        if ($Thumbprint -and ($IsLinux -or $IsMacOS)) {
            Stop-PSFFunction -Message "Thumbprint is only supported on Windows. Use CertificateBase64Encoded instead."
            return
        }

        try {
            switch ($AuthenticationMode) {
                "WebLogin" {
                    Write-PSFMessage -Level Verbose -Message "Proceeding with WebLogin mode"
                    $script:spsite = Connect-PnPOnline -LaunchBrowser -PnPManagementShell
                }

                "ManagedIdentity" {
                    Write-PSFMessage -Level Verbose -Message "Proceeding with ManagedIdentity mode"
                    $script:spsite = Connect-PnPOnline -ManagedIdentity
                }

                "AccessToken" {
                    Write-PSFMessage -Level Verbose -Message "Proceeding with AccessToken mode"
                    $script:spsite = Connect-PnPOnline -AccessToken $AccessToken
                }

                "AppOnly" {
                    Write-PSFMessage -Level Verbose -Message "Proceeding with AppOnly mode"
                    if (-not $ClientId) {
                        $ClientId = $Credential.UserName
                        Write-PSFMessage -Level Verbose -Message "Setting ClientId from Credential username ($ClientId)"
                    }

                    if ($Thumbprint) {
                        Write-PSFMessage -Level Verbose -Message "Using Thumbprint"
                        $script:spsite = Connect-PnPOnline -ClientId $ClientId -Thumbprint $Thumbprint
                    } elseif ($CertificateBase64Encoded) {
                        Write-PSFMessage -Level Verbose -Message "Using CertificateBase64Encoded from Credential password"
                        $script:spsite = Connect-PnPOnline -ClientId $ClientId -CertificateBase64Encoded $Credential.GetNetworkCredential().Password
                    } elseif ($CertificatePath) {
                        Write-PSFMessage -Level Verbose -Message "Using CertificatePassword from Credential password for CertificatePath"
                        $script:spsite = Connect-PnPOnline -ClientId $ClientId -CertificatePath $CertificatePath -CertificatePassword $Credential.GetNetworkCredential().Password
                    } else {
                        $script:spsite = Connect-PnPOnline -ClientId $ClientId -ClientSecret $Credential.GetNetworkCredential().Password
                    }
                }

                default {
                    Write-PSFMessage -Level Verbose -Message "Proceeding with default login mode"
                    if ($Credential) {
                        Write-PSFMessage -Level Verbose -Message "Credential detected"
                        if ($Location -eq "Onprem") {
                            Write-PSFMessage -Level Verbose -Message "Connecting to OnPrem"
                            $script:spsite = Connect-PnPOnline -Credential $Credential -TransformationOnPrem
                        } else {
                            Write-PSFMessage -Level Verbose -Message "Connecting to SharePoint online"
                            $script:spsite = Connect-PnPOnline -Credential $Credential
                        }
                    } else {
                        if ($PSVersionTable.PSEdition -eq "Core") {
                            Write-PSFMessage -Level Verbose -Message "No credential detected, connecting using PS Core"
                            $script:spsite = Connect-PnPOnline -TransformationOnPrem -CurrentCredential
                        } else {
                            # This is required for non-core ¯\_(ツ)_/¯
                            Write-PSFMessage -Level Verbose -Message "No credential detected, connecting using Windows PowerShell"
                            $script:spsite = New-Object Microsoft.SharePoint.Client.ClientContext($Site)
                            # This doesn't really work, but maybe it will at some point
                            $null = Set-PnPContext -Context $script:spsite
                        }
                    }
                }
            }

            # Get Context from Connect-PnpOnline
            if ($script:spsite.Context) {
                $script:spsite = $script:spsite.Context
            }

            # Add ExecuteQuery to Core
            if (-not $script:spsite.ExecuteQuery) {
                # ty https://rajujoseph.com/getting-net-core-and-sharepoint-csom-play-nice/
                Add-Member -InputObject $script:spsite -MemberType ScriptMethod -Name ExecuteQuery -Value {
                    if ($script:spsite.HasPendingRequest) {
                        $script:spsite.ExecuteQueryAsync().Wait()
                    }
                } -Force
            }

            # Grab web and lists
            try {
                Write-PSFMessage -Level Verbose -Message "Loading up webs and lists"
                $script:spsite.Load($script:spsite.Web)
                $script:spsite.ExecuteQuery()
                $script:spweb = $script:spsite.Web
                $script:spsite.Load($script:spweb)
                $script:spsite.ExecuteQuery()
                $script:spsite.Load($script:spweb.Lists)
                $script:spsite.ExecuteQuery()
            } catch {
                if ($AuthenticationMode -eq "AppOnly") {
                    $msg = "Could not connect to $Site. Please check that you've followed all the steps at https://docs.microsoft.com/en-us/sharepoint/dev/solution-guidance/security-apponly-azureacs"
                } else {
                    $msg = "Could not connect to $Site"
                }
                Stop-PSFFunction -Message $msg -ErrorRecord $_
                return
            }

            # Make output pretty
            Write-PSFMessage -Level Verbose -Message "Making output pretty"
            Add-Member -InputObject $script:spsite -MemberType ScriptMethod -Name ToString -Value { $this.Url } -Force
            Add-Member -InputObject $script:spweb -MemberType ScriptMethod -Name ToString -Value { $this.Title } -Force
            if ($script:spsite.Credentials) {
                Add-Member -InputObject $script:spsite.Credentials -MemberType ScriptMethod -Name ToString -Value { $this.UserName } -Force
            }

            # Grab curent login name
            Write-PSFMessage -Level Verbose -Message "Getting loginname"
            $script:spsite.Load($script:spweb.CurrentUser)
            $script:spsite.ExecuteQuery()
            $loginname = $script:spweb.CurrentUser.LoginName

            # Add glboal connection that persists between module reloads
            Write-PSFMessage -Level Verbose -Message "Setting globals to global:SPReplicator"
            $global:SPReplicator.Web = $script:spweb
            $global:SPReplicator.Site = $script:spsite
            $global:SPReplicator.LogList = $global:SPReplicator.LogList
            $global:SPReplicator.ListNames = $script:spweb.Lists.Title

            # auto-populate list names!
            Register-PSFTeppScriptblock -Name List -ScriptBlock {
                $global:SPReplicator.ListNames
            }
            Register-PSFTeppArgumentCompleter -Command (Get-Command -Module SPReplicator).Name -Parameter List -Name List

            # unsure, actually
            $getsite = $script:spsite.get_site()
            $script:spsite.Load($getsite)
            $script:spsite.ExecuteQuery()
            $rootweb = $getsite.get_rootWeb()
            $script:spsite.ExecuteQuery()

            Add-Member -InputObject $rootweb -MemberType ScriptMethod -Name ToString -Value { $this.Title } -Force
            Add-Member -InputObject $script:spsite -MemberType NoteProperty -Name RootWeb -Value $rootweb -Force
            Add-Member -InputObject $script:spsite -MemberType NoteProperty -Name Location -Value $Location -Force
            Add-Member -InputObject $script:spsite -MemberType NoteProperty -Name CurrentUser -Value $loginname -Force
            $script:spsite | Select-DefaultView -Property Url, ServerVersion, RequestTimeout, RootWeb, CurrentUser, Location
        } catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
        }
    }
}