Function Get-SPRContentTypeField {
<#
.SYNOPSIS
    Returns a SharePoint content type field object.

.DESCRIPTION
    Returns a SharePoint content type field object.

.PARAMETER Field
    The human readable content type field name. So 'My Content Type' as opposed to 'MyContentType', unless you named it MyContentType.

.PARAMETER ContentType
    The human readable content type field name. So 'My Content Type' as opposed to 'MyContentType', unless you named it MyContentType.

.PARAMETER Web
    The human readable web name. So 'My Web' as opposed to 'MyWeb', unless you named it MyWeb.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER InputObject
    Allows piping from Connect-SPRSite
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRContentType -Site intranet.ad.local -Content Type 'My Content Type'

    Creates a web service object for My Content Type on intranet.ad.local. Figures out the wsdl address automatically.

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local | Get-SPRContentType -Content Type 'My Content Type'

    Creates a web service object for My Content Type on intranet.ad.local. Figures out the wsdl address automatically.

.EXAMPLE
    Get-SPRContentType -Site intranet.ad.local -Content Type 'My Content Type' -Credential ad\user

    Creates a web service object for My Content Type and logs into the webapp as ad\user.
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint content type name")]
        [string]$ContentType,
        [int[]]$Id,
        [Parameter(Position = 1, HelpMessage = "Human-readble SharePoint web name")]
        [string[]]$Web,
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SPRContentType -Site $Site -Credential $Credential -ContentType $ContentType -Web $Web
            }
            elseif ($script:spsite) {
                $InputObject = Get-SPRContentType -ContentType $ContentType -Web $Web
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and ContentType pipe in results from Get-SPRContentType"
                return
            }
        }
        foreach ($ct in $InputObject) {
            try {
                $fields = $ct.Fields
                if ($Id) {
                    $fields = $fields | Where-Object Id -in $id
                }
                $fields
            } catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
            }
        }
    }
}