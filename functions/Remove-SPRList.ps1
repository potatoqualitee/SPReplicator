Function Remove-SPRList {
<#
.SYNOPSIS
    Deletes lists from a SharePoint site collection.

.DESCRIPTION
    Deletes lists items from a SharePoint  site collection.

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
    Remove-SPRList -Site intranet.ad.local -List 'My List'

    Removes the list "My List" on intranet.ad.local. Prompts for confirmation.

.EXAMPLE
    Get-SPRList -List 'My List' -Site intranet.ad.local | Remove-SPRList -Confirm:$false

    Removes the list "My List" on intranet.ad.local. Does not prompt for confirmation.

.EXAMPLE
    Get-SPRListItem -Site intranet.ad.local -List 'My List' -Credential ad\user | Remove-SPRList -Confirm:$false

    Deletes all items from My List by logging into the webapp as ad\user.

.EXAMPLE
    Remove-SPRList -Site intranet.ad.local -List 'My List' -WhatIf

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
        [object[]]$InputObject,
        [switch]$EnableException
    )
    process {
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
            Stop-PSFFunction -EnableException:$EnableException -Message "No list to delete."
            return
        }
        
        foreach ($thislist in $InputObject) {
            if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $thislist.Context.Url -Action "Removing list $($thislist.Title)")) {
                try {
                    Write-PSFMessage -Level Verbose -Message "Deleting $($list.Title) from $($list.Context)"
                    $dellist = $global:spsite.Web.Lists.GetByTitle($thislist.Title)
                    $global:spsite.Load($dellist)
                    $dellist.DeleteObject()
                    $global:spsite.ExecuteQuery()
                    [pscustomobject]@{
                        Site = $thislist.Context
                        List = $thislist.Title
                        ItemId = $thislist.Id
                        Status = "Deleted"
                    }
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                }
            }
        }
    }
}