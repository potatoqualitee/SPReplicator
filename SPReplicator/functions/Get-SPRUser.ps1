﻿Function Get-SPRUser {
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

.PARAMETER Identity
    The human readable user name. So 'Jon Deaux' as opposed to 'JonDeaux', unless you named it JonDeaux.

.PARAMETER EnsureUser
    Use the EnsureUser method of finding a user account. 
    
    "EnsureUser checks whether the specified login name belongs to a valid user of the Web site, and if the login name does not already exist, adds it to the Web site directly."

.PARAMETER InputObject
    Allows piping from Connect-SPRSite

.PARAMETER Force
    Repopulates the user cache, otherwise, it'll use the cache
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRUser -Site intranet.ad.local

    Gets all users on intranet.ad.local

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local | Get-SPRUser -Identity 'ad\user'

    Gets the ad\user SharePoint object on intranet.ad.local.

#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint user name")]
        [string[]]$Identity,
        [Parameter(Position = 1, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object[]]$InputObject,
        [switch]$EnsureUser,
        [switch]$Force,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $null = Connect-SPRSite -Site $Site -Credential $Credential
                $getsite = $script:spsite.get_site()
                $script:spsite.Load($getsite)
                $script:spsite.ExecuteQuery()
                $InputObject = $getsite.get_rootWeb()
            }
            elseif ($script:spweb) {
                $getsite = $script:spweb.Context.get_site()
                $script:spweb.Context.Load($getsite)
                $script:spweb.Context.ExecuteQuery()
                $InputObject = $getsite.get_rootWeb()
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site or run Connect-SPRSite"
                return
            }
        }
        else {
            if ($InputObject[0] -is [Microsoft.SharePoint.Client.User]) {
                $Identity = $InputObject.LoginName
                $getsite = $script:spweb.Context.get_site()
                $script:spweb.Context.Load($getsite)
                $script:spweb.Context.ExecuteQuery()
                $InputObject = $getsite.get_rootWeb()
            }
        }
        
        foreach ($web in $InputObject) {
            $script:spsite.Load($web)
            $script:spsite.ExecuteQuery()
            $webid = $web.Id
            
            if (-not $Identity) {
                try {
                    $users = $web.SiteUsers
                    $script:spsite.Load($users)
                    $script:spsite.ExecuteQuery()
                    # exclude: Groups, AadObjectId, IsEmailAuthenticationGuestUser, IsHiddenInUI, IsShareByEmailGuestUser, Path, ObjectVersion, ServerObjectIsNull, UserId, TypedObject, Tag
                    if ((Get-PSFConfigValue -FullName SPReplicator.Location) -ne "Online") {
                        $users = $users | Select-DefaultView -ExcludeProperty Alerts
                    }
                    $users | Select-DefaultView -Property Id, Title, LoginName, Email, IsSiteAdmin, PrincipalType
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                }
            }
            else {
                if (-not $global:SPReplicator.UserCache[$webid] -or $Force) {
                    $users = $web.SiteUsers
                    $script:spsite.Load($users)
                    $script:spsite.ExecuteQuery()
                    $global:SPReplicator.UserCache[$webid] = $users
                }
                else {
                    $users = $global:SPReplicator.UserCache[$webid]
                }
                
                foreach ($user in $Identity) {
                    try {
                        Write-PSFMessage -Level Verbose -Message "Getting $user from $($script:spsite.Url)"

                        if ($EnsureUser) {
                            $spuser = $script:spweb.EnsureUser($user)
                            $script:spsite.Load($spuser)
                            $script:spsite.ExecuteQuery()
                        }
                        else {
                            $spuser = $users | Where-Object { $psitem.LoginName -eq $user }
                            if (-not $spuser) {
                                $spuser = $users | Where-Object { $psitem.LoginName.EndsWith($user) }
                            }
                            if (-not $spuser) {
                                $spuser = $users | Where-Object { $psitem.Email -eq $user }
                            }
                            if (-not $spuser) {
                                $spuser = $users | Where-Object { $psitem.Title -eq $user }
                            }
                        }
                        Write-PSFMessage -Level Verbose -Message "Got $user from $($script:spsite.Url)"

                        if ($spuser) {
                            Add-Member -InputObject $spuser -MemberType ScriptMethod -Name ToString -Value { $this.LoginName } -Force
                            Add-Member -InputObject $spuser -MemberType NoteProperty -Name FormattedLogin -Value $("{0};#{1}" -f $spuser.Id, $spuser.LoginName) -Force
                            # exclude: Groups, AadObjectId, IsEmailAuthenticationGuestUser, IsHiddenInUI, IsShareByEmailGuestUser, Path, ObjectVersion, ServerObjectIsNull, UserId, TypedObject, Tag
                            if ((Get-PSFConfigValue -FullName SPReplicator.Location) -eq "Online") {
                                $spuser | Select-Object -ExcludeProperty Alerts | Select-DefaultView -Property Id, Title, LoginName, Email, IsSiteAdmin, PrincipalType
                            }
                            else {
                                $spuser | Select-DefaultView -Property Id, Title, LoginName, Email, IsSiteAdmin, PrincipalType
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