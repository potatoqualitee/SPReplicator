Function Add-SPRUser {
<#
.SYNOPSIS
    Adds a SharePoint user.

.DESCRIPTION
    Adds a SharePoint user.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER UserName
    The Active Directory username to add to the website.

.PARAMETER InputObject
    Allows piping from Connect-SPRsite
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local
    Add-SPRUser -UserName 'ad\user'

    Adds the ad\user SharePoint object on intranet.ad.local

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
        
        if ($InputObject -is [Microsoft.SharePoint.Client.Site]) {
            $getsite = $script:spweb.Context.get_site()
            $script:spweb.Context.Load($getsite)
            $script:spweb.Context.ExecuteQuery()
            $InputObject = $getsite.get_rootWeb()
        }
        
        foreach ($web in $InputObject) {
            if ($web -isnot [Microsoft.SharePoint.Client.Web]) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Invalid inputobject"
                return
            }
            $script:spsite.Load($web)
            $script:spsite.ExecuteQuery()
            $webid = $web.Id
            
            foreach ($user in $UserName) {
                try {
                    $spuser = $web.EnsureUser($user)
                    $web.Context.Load($spuser)
                    $web.Context.ExecuteQuery()
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
                }
                
                if ($web.Context -eq "Online") {
                    $spuser | Select-Object -ExcludeProperty Alerts | Select-DefaultView -Property Id, Title, LoginName, Email, IsSiteAdmin, PrincipalType
                }
                else {
                    $spuser | Select-DefaultView -Property Id, Title, LoginName, Email, IsSiteAdmin, PrincipalType
                }
            }
        }
    }
}