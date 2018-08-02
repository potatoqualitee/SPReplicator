Function Get-SPRColumnDetail {
 <#
.SYNOPSIS
    Returns information (Name, DisplayName, Data type) about columns in a SharePoint list.

.DESCRIPTION
    Returns information (Name, DisplayName, Data type) about columns in a SharePoint list.

.PARAMETER List
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER Web
    The human readable web name. So 'My Web' as opposed to 'MyWeb', unless you named it MyWeb.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER InputObject
    Allows piping from Get-SPRList

.PARAMETER Simple
    Just shows columns that were created by the user
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRColumnDetail -Site intranet.ad.local -List 'My List'

    Gets column information from My List on intranet.ad.local.

.EXAMPLE
    Get-SPRList -List 'My List' -Site intranet.ad.local | Get-SPRColumnDetail

     Gets column information from My List on intranet.ad.local
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [string[]]$List,
        [Parameter(Position = 1, HelpMessage = "Human-readble SharePoint web name")]
        [string[]]$Web,
        [Parameter(Position = 2, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [switch]$Simple,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SPRList -Site $Site -Credential $Credential -List $List -Web $Web
            }
            elseif ($script:spsite) {
                $InputObject = Get-SPRList -List $List -Web $Web
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and List pipe in results from Get-SPRList"
                return
            }
        }
        
        foreach ($thislist in $InputObject) {
            try {
                $thislist.Context.Load($thislist.Fields)
                $thislist.Context.ExecuteQuery()
                foreach ($column in $thislist.Fields) {
                    if ($Simple -and -not ($column.CanBeDeleted -and $column.DisplayName -eq 'Title')) { continue }
                    $title = $column.Title
                    Add-Member -InputObject $column -MemberType NoteProperty -Name List -Value $thislist.Title
                    Add-Member -InputObject $column -MemberType NoteProperty -Name OwsName -Value "ows_$title"
                    Select-DefaultView -InputObject $column -Property List, 'Title as DisplayName', 'StaticName as Name', 'TypeDisplayName as Type', FromBaseType
                }
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -ErrorRecord $_ -Message "Failure"
            }
        }
    }
}