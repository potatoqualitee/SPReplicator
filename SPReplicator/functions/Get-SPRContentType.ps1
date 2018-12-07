Function Get-SPRContentType {
<#
.SYNOPSIS
    Returns a SharePoint content type object.

.DESCRIPTION
    Returns a SharePoint content type object.

.PARAMETER ContentType
    The human readable content type name. So 'My Content Type' as opposed to 'MyList', unless you named it MyList.

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
        [string[]]$ContentType,
        [Parameter(Position = 1, HelpMessage = "Human-readble SharePoint web name")]
        [string[]]$Web,
        [Parameter(Position = 2, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $null = Connect-SPRSite -Site $Site -Credential $Credential
                $InputObject = $script:spweb
            }
            
            if ($Web) {
                $InputObject = Get-SPRWeb -Web $Web -Credential $Credential
            } elseif ($script:spweb) {
                $InputObject = $script:spweb
            }
            
            if (-not $InputObject) {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site, Web or run Connect-SPRSite"
                return
            }
        }
        
        foreach ($server in $InputObject.Context) {
            
            try {
                $server.Load($script:spweb)
                $server.ExecuteQuery()
                $cts = $script:spweb.ContentTypes
                $server.Load($cts)
                $server.ExecuteQuery()
                if ($ContentType) {
                    $cts = $cts | Where-Object Name -in $ContentType
                }
                foreach ($ct in $cts) {
                    $fs = $ct.Fields
                    $server.Load(($fs = $ct.Fields))
                    $server.ExecuteQuery()
                    Add-Member -InputObject $ct -MemberType ScriptMethod -Name ToString -Value {
                        $this.Name
                    } -Force
                    $ct | Select-DefaultView -Property Id, Name, Description, Fields, DisplayFormTemplateName, DisplayFormUrl, DocumentTemplate, DocumentTemplateUrl, EditFormTemplateName, EditFormUrl, Group, Hidden, JSLink, MobileDisplayFormUrl, MobileEditFormUrl, MobileNewFormUrl, NewFormTemplateName, NewFormUrl, ObjectVersion, ReadOnly, Scope, Sealed, ServerObjectIsNull, StringId, Tag
                }
            } catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
            }
        }
    }
}