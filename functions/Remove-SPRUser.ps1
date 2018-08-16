Function Remove-SPRUser {
<#
.SYNOPSIS
    Removes a SharePoint user.

.DESCRIPTION
    Removes a SharePoint user.

.PARAMETER Site
    The Removeress to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER Identity
    The Active Directory Identity to Remove to the website.

.PARAMETER InputObject
    Allows piping from Connect-SPRsite
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local
    Remove-SPRUser -Identity 'ad\user'

    Removes the ad\user SharePoint object on intranet.ad.local

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
            $script:spsite.ExecuteQuery()
            $userid = $user.Id
            Write-Warning $userid
        }
    }
}