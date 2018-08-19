Function Remove-SPRListTemplate {
<#
.SYNOPSIS
    Get list of native and custom SharePoint templates.

.DESCRIPTION
    Get list of native and custom SharePoint templates.

.PARAMETER Id
    Return only templates with specific IDs

.PARAMETER Name
    Return only templates with specific names

.PARAMETER Web
    The human readable web name. So 'My Web' as opposed to 'MyWeb', unless you named it MyWeb.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER InputObject
    Piped input from a web
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Remove-SPRListTemplate -Site intranet.ad.local

    Returns all templates and their corresponding numbers

.EXAMPLE
    Remove-SPRListTemplate -Id 100, 118

    Returns all templates and their corresponding numbers that match 100 and 118

.EXAMPLE
    Remove-SPRListTemplate -Name AdminTasks, HealthReports

    Returns templates and their corresponding numbers that match the name AdminTasks and HealthReports
#>
    [CmdletBinding()]
    param (
        [int[]]$Id,
        [string[]]$Name,
        [Parameter(Position = 1, HelpMessage = "Human-readble SharePoint web name")]
        [string[]]$Web,
        [Parameter(Position = 2, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [Microsoft.SharePoint.Client.ListTemplate[]]$InputObject,
        [switch]$EnableException
    )
    process {
        try {
            if (-not $InputObject) {
                if ($Site -or $Web) {
                    $InputObject = Get-SPRListTemplate -Site $Site -Credential $Credential -Web $Web -Name $Name -Id $Id
                }
                if (-not $InputObject) {
                    Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site, Web or run Connect-SPRSite"
                    return
                }
            }
            foreach ($template in $InputObject) {
                if (-not $template.ListItem) {
                    Stop-PSFFunction -EnableException:$EnableException -Message "System Template, cannot delete." -Continue
                }
                else {
                    $template.ListItem | Remove-SPRListItem
                }
            }
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
        }
    }
}