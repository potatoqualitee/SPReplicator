Function Clear-SPRListItems {
<#
.SYNOPSIS
    Deletes all items from a SharePoint list.

.DESCRIPTION
     Deletes all items from a SharePoint list.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER List
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER InputObject
    Allows piping from Get-SPRList

.PARAMETER WhatIf
    If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

.PARAMETER Confirm
    If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Clear-SPRListItems -Site intranet.ad.local -List 'My List'

    Deletes all items from My List on intranet.ad.local. Prompts for confirmation.

.EXAMPLE
    Get-SPRList -List 'My List' -Site intranet.ad.local | Clear-SPRListItems -Confirm:$false

     Deletes all items from My List on intranet.ad.local. Does not prompt for confirmation.

.EXAMPLE
    Clear-SPRListItems -Site intranet.ad.local -List 'My List'

    No actions are performed but informational messages will be displayed about the items that would be deleted from the My List list.
#>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [string]$List,
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [Microsoft.SharePoint.Client.List[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject -and -not $List) {
            Stop-PSFFunction -EnableException:$EnableException -Message "Pipe in a list or specify -List"
            return
        }
        
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SPRList -Site $Site -Credential $Credential -List $List
            }
            elseif ($global:spsite) {
                $InputObject = Get-SPRList -List $List
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and List pipe in results from Get-SPRList"
                return
            }
        }
        
        if (-not $InputObject) {
            Stop-PSFFunction -EnableException:$EnableException -Message "Nothing to delete"
            return
        }
        
        foreach ($thislist in $InputObject) {
            $itemcount = $thislist.ItemCount
            if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $global:spsite.Url -Action "Removing $itemcount records from $($thislist.Title)")) {
                try {
                    $done = $false
                    while (-not $done) {
                        $query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery(100, "ID")
                        $listItems = $thislist.GetItems($query)
                        $thislist.Context.Load($listItems)
                        $thislist.Context.ExecuteQuery()
                        if ($listItems.Count -gt 0) {
                            for ($i = $listItems.Count - 1; $i -ge 0; $i--) {
                                $listItems[$i].DeleteObject()
                            }
                        }
                        else {
                            $done = $true
                        }
                    }
                    $thislist.Context.ExecuteQuery()
                    [pscustomobject]@{
                        Site = $thislist.Context.Url
                        List = $thislist.Title
                        ItemCount = $itemcount
                        Status = "All records deleted"
                    }
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                }
            }
        }
    }
}