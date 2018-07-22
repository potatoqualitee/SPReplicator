Function Get-SPRUser {
<#
.SYNOPSIS
    Returns a SharePoint user object.

.DESCRIPTION
    Returns a SharePoint user object.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER UserName
    The human readable user name. So 'My User' as opposed to 'MyUser', unless you named it MyUser.

.PARAMETER InputObject
    Allows piping from Connect-SPRSite

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRUser -Site intranet.ad.local -UserName 'My User'

    Creates a web service object for My User on intranet.ad.local. Figures out the wsdl address automatically.

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local | Get-SPRUser -UserName 'My User'

    Creates a web service object for My User on intranet.ad.local. Figures out the wsdl address automatically.

.EXAMPLE
    Get-SPRUser -Site intranet.ad.local -UserName 'My User' -Credential (Get-Credential ad\user)

    Creates a web service object for My User and logs into the webapp as ad\user.
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint user name")]
        [string[]]$UserName,
        [Parameter(Position = 1, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $null = Connect-SPRSite -Site $Site -Credential $Credential
                $InputObject = Get-SPRWeb
            }
            elseif ($global:spweb) {
                $InputObject = $global:spweb
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site or run Connect-SPRSite"
                return
            }
        }
        else {
            if ($InputObject[0] -is [Microsoft.SharePoint.Client.User]) {
                $UserName = $InputObject.LoginName
                $InputObject = $global:spweb
            }
        }
        
        foreach ($web in $InputObject) {
            if (-not $UserName) {
                try {
                    $global:spsite.Load($web)
                    $global:spsite.ExecuteQuery()
                    $users = $web.SiteUsers
                    $global:spsite.Load($users)
                    $global:spsite.ExecuteQuery()
                    # exclude: Groups, AadObjectId, IsEmailAuthenticationGuestUser, IsHiddenInUI, IsShareByEmailGuestUser, Path, ObjectVersion, ServerObjectIsNull, UserId, TypedObject, Tag 
                    if ((Get-PSFConfigValue -FullName SPReplicator.Location) -ne "Online") {
                        $users = $users | Select-Object -ExcludeProperty Alerts
                    }
                    $users | Select-DefaultView -Property Id, Title, LoginName, Email, IsSiteAdmin, PrincipalType
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                }
            }
            else {
                foreach ($user in $UserName) {
                    try {
                        $users = $web.SiteUsers
                        $global:spsite.Load($users)
                        $global:spsite.ExecuteQuery()
                        $user = $users | Where-Object { $_.LoginName -contains $username -or $_.Title -contains $username -or $_.Email -contains $username }
                        
                        if ($user) {
                            Write-PSFMessage -Level Verbose -Message "Getting $($user.Title) from $($global:spsite.Url)"
                            Add-Member -InputObject $user -MemberType ScriptMethod -Name ToString -Value { $this.LoginName } -Force
                            
                            # exclude: Groups, AadObjectId, IsEmailAuthenticationGuestUser, IsHiddenInUI, IsShareByEmailGuestUser, Path, ObjectVersion, ServerObjectIsNull, UserId, TypedObject, Tag 
                            if ((Get-PSFConfigValue -FullName SPReplicator.Location) -eq "Online") {
                                $user | Select-Object -ExcludeProperty Alerts | Select-DefaultView -Property Id, Title, LoginName, Email, IsSiteAdmin, PrincipalType
                            }
                            else {
                                $user | Select-DefaultView -Property Id, Title, LoginName, Email, IsSiteAdmin, PrincipalType
                            }
                        }
                    }
                    catch {
                        Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                    }
                }
            }
        }
    }
}