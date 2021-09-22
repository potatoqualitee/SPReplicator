﻿Function Get-SPRWeb {
    <#
.SYNOPSIS
    Returns a SharePoint web object.

.DESCRIPTION
    Returns a SharePoint web object.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER Web
    The human readable web name. So 'My Web' as opposed to 'MyWeb', unless you named it MyWeb.

.PARAMETER InputObject
    Allows piping from Connect-SPRSite

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRWeb -Site intranet.ad.local

    Gets all webs on intranet.ad.local

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local | Get-SPRWeb -Web 'My Web'

    Gets a SharePoint web object for My Web on intranet.ad.local.

.EXAMPLE
    Get-SPRWeb -Site intranet.ad.local -Web 'My Web' -Credential ad\user

    Creates a web service object for My Web and logs into the webapp as ad\user.
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint web name")]
        [string[]]$Web,
        [Parameter(Position = 1, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Connect-SPRSite -Site $Site -Credential $Credential
            } elseif ($script:spsite) {
                $InputObject = $script:spsite
            } else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site or run Connect-SPRSite"
                return
            }
        }

        foreach ($server in $InputObject) {
            if (-not $Web) {
                try {
                    $script:spweb = $server.Web
                    $server.Load($script:spweb)
                    $server.ExecuteQuery()

                    $script:spweb | Select-DefaultView -Property Context, Title, Description, Url, MasterUrl, RecycleBinEnabled, WebTemplate, Created, LastItemModifiedDate
                    Add-Member -InputObject $script:spweb -MemberType ScriptMethod -Name ToString -Value { $this.Title } -Force
                    $global:SPReplicator.Web = $script:spweb
                } catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                }
            } else {
                foreach ($currentweb in $Web) {
                    try {
                        $web = $server.Web | Where-Object Title -eq $currentweb
                        if ($web) {
                            $script:spweb = $web
                            $server.Load($script:spweb)
                            $server.ExecuteQuery()
                            Add-Member -InputObject $script:spweb -MemberType ScriptMethod -Name ToString -Value { $this.Title } -Force

                            $script:spweb | Select-DefaultView -Property Context, Title, Description, Url, MasterUrl, RecycleBinEnabled, WebTemplate, Created, LastItemModifiedDate
                        }
                    } catch {
                        Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                    }
                }
            }
        }
    }
}