Function Get-SPRListView {
<#
.SYNOPSIS
    Gets views from a SharePoint list.

.DESCRIPTION
    Gets views from a SharePoint list.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER ListName
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER View
    Return only rows from a specific view
    
.PARAMETER InputObject
    Allows piping from Get-SPRList

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRListView -Site intranet.ad.local -ListName 'My List'

    Gets all views from My List on intranet.ad.local.

.EXAMPLE
    Get-SPRList -ListName 'My List' -Site intranet.ad.local | Get-SPRListView

     Gets views from My List on intranet.ad.local.

.EXAMPLE
    Get-SPRListView -Site intranet.ad.local -ListName 'My List' -Credential ad\user

    Gets views from My List and logs into the webapp as ad\user.
    
.EXAMPLE
    Get-SPRListView -Site sharepoint2016 -ListName 'My List' -View 'My Tasks'

    Gets list items included in the view My Tasks
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory, HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [string]$View,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SprList -Site $Site -Credential $Credential -ListName $ListName
            }
            elseif ($global:spsite) {
                $InputObject = Get-SPRList -ListName $ListName
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and ListName pipe in results from Get-SPRList"
                return
            }
        }
        
        foreach ($list in $InputObject) {
            try {
                if ($View) {
                    $listview = $list.Views.GetByTitle($View)
                    $list.Context.Load($listview)
                    $list.Context.ExecuteQuery()
                }
                else {
                    $listview = $list.Views
                    $list.Context.Load($list)
                    $list.Context.Load($listview)
                    $list.Context.ExecuteQuery()
                }
                
                foreach ($item in $listview) {
                    $list.Context.Load($item.ViewFields)
                    $list.Context.ExecuteQuery()
                    Add-Member -InputObject $item -MemberType NoteProperty -Name ListObject -Value $list
                    Select-DefaultView -InputObject $item -Property 'ListObject as ListName', Title, ViewFields, RowLimit, ReadOnlyView, ServerRelativeUrl, ViewQuery, DefaultView
                }
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
            }
        }
    }
}