﻿Function Remove-SPRUser {
<#
.SYNOPSIS
    Removes a SharePoint user.

.DESCRIPTION
    Removes a SharePoint user.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER Identity
    The Active Directory Identity to remove from the web.

.PARAMETER InputObject
    Allows piping from Get-SPRUser
  
.PARAMETER WhatIf
    If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

.PARAMETER Confirm
    If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local
    Remove-SPRUser -Identity 'ad\user'

    Removes the ad\user SharePoint object on intranet.ad.local

.EXAMPLE
    Remove-SPRUser  -Site intranet.ad.local -Identity 'ad\user'

    Removes the ad\user SharePoint object on intranet.ad.local
#>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint user name")]
        [string[]]$Identity,
        [Parameter(Position = 1, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [Microsoft.SharePoint.Client.User[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $null = Connect-SPRSite -Site $Site -Credential $Credential
                $InputObject = Get-SPRUser -Identity $Identity
            }
            elseif ($script:spweb) {
                $InputObject = Get-SPRUser -Identity $Identity
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site or run Connect-SPRSite"
                return
            }
        }
        
        if (-not $InputObject) {
            Stop-PSFFunction -EnableException:$EnableException -Message "$Identity not found in $spsite"
            return
        }
        
        foreach ($user in $InputObject) {
            if ($user -isnot [Microsoft.SharePoint.Client.User]) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Invalid inputobject"
                return
            }
            $script:spsite.Load($user)
            $login = $user.LoginName
            $script:spsite.ExecuteQuery()
            
            
            if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $script:spsite.Url -Action "Removing user $login")) {
                $script:spsite.RootWeb.SiteUsers.Remove($user)
                $script:spsite.ExecuteQuery()
                
                [pscustomobject]@{
                    Site = $script:spsite
                    Web  = $script:spsite.RootWeb
                    Identity = $login
                    Status = "Deleted"
                }
            }
        }
    }
}