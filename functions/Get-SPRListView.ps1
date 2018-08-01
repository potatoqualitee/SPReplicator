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

.PARAMETER List
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
    Get-SPRListView -Site intranet.ad.local -List 'My List'

    Gets all views from My List on intranet.ad.local.

.EXAMPLE
    Get-SPRList -List 'My List' -Site intranet.ad.local | Get-SPRListView

     Gets views from My List on intranet.ad.local.

.EXAMPLE
    Get-SPRListView -Site intranet.ad.local -List 'My List' -Credential ad\user

    Gets views from My List and logs into the webapp as ad\user.
    
.EXAMPLE
    Get-SPRListView -Site sharepoint2016 -List 'My List' -View 'My Tasks'

    Gets list items included in the view My Tasks
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [string]$List,
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [string]$View,
        [parameter(ValueFromPipeline)]
        [Microsoft.SharePoint.Client.List[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SprList -Site $Site -Credential $Credential -List $List
            }
            elseif ($global:spsite) {
                $InputObject = Get-SPRList -List $List
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and List pipe in results from Get-SPRList"
                return
            }
        }
        
        foreach ($thislist in $InputObject) {
            try {
                if ($View) {
                    $listview = $thislist.Views.GetByTitle($View)
                    $thislist.Context.Load($listview)
                    $thislist.Context.ExecuteQuery()
                }
                else {
                    $listview = $thislist.Views
                    $thislist.Context.Load($thislist)
                    $thislist.Context.Load($listview)
                    $thislist.Context.ExecuteQuery()
                }
                
                foreach ($item in $listview) {
                    $thislist.Context.Load($item.ViewFields)
                    $thislist.Context.ExecuteQuery()
                    Add-Member -InputObject $item -MemberType NoteProperty -Name ListObject -Value $thislist
                    Select-DefaultView -InputObject $item -Property 'ListObject as List', Title, ViewFields, RowLimit, ReadOnlyView, ServerRelativeUrl, ViewQuery, DefaultView
                }
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
            }
        }
    }
}