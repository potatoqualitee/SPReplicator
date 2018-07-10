Function Remove-SPRListData {
<#
.SYNOPSIS
    Deletes items from a SharePoint list.

.DESCRIPTION
    Deletes items from a SharePoint list.

.PARAMETER Uri
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Uri or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER ListName
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER Id
    Removes only rows with specific IDs.

.PARAMETER InputObject
    Allows piping from Get-SPRListData.

.PARAMETER WhatIf
    If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

.PARAMETER Confirm
    If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Remove-SPRListData -Uri intranet.ad.local -ListName 'My List'

    Deletes all items from My List on intranet.ad.local. Prompts for confirmation.

.EXAMPLE
    Get-SPRList -ListName 'My List' -Uri intranet.ad.local | Remove-SPRListData -Confirm:$false

    Deletes all items from My List on intranet.ad.local. Does not prompt for confirmation.

.EXAMPLE
    Get-SPRListData -Uri intranet.ad.local -ListName 'My List' -Credential (Get-Credential ad\user) | Remove-SPRListData -Confirm:$false

    Deletes all items from My List by logging into the webapp as ad\user.

.EXAMPLE
    Remove-SPRListData -Uri intranet.ad.local -ListName 'My List'

    No actions are performed but informational messages will be displayed about the items that would be deleted from the My List list.
#>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Uri,
        [PSCredential]$Credential,
        [Parameter(HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [int[]]$Id,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Uri) {
                $InputObject = Get-SPRListData -Uri $Uri -Credential $Credential -ListName $ListName -Id $Id
            }
            elseif ($global:spsite) {
                $InputObject = $global:spsite | Get-SPRListData -ListName $ListName -Id $Id
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Uri and ListName pipe in results from Get-SPRList"
                return
            }
        }

        if (-not $InputObject) {
            Stop-PSFFunction -EnableException:$EnableException -Message "No records to delete."
            return
        }

        if ($InputObject -is [Microsoft.SharePoint.Client.List]) {
            $InputObject = $InputObject | Get-SPRListData
        }

        foreach ($item in $InputObject) {
            if (-not $item.ListObject) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Invalid InputObject" -Continue
            }
            $list = $item.ListObject
            if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $list.Context.Url -Action "Removing record $($item.Id) from $($item.ListObject.Title)")) {
                try {
                    Write-PSFMessage -Level Verbose -Message "Removing $($item.Id) from $($list.Title)"
                    $list.GetItemById($item.Id).DeleteObject()
                    $global:spsite.ExecuteQuery()
                    [pscustomobject]@{
                        Site = $list.Context
                        ListName = $list.Title
                        ItemId   = $item.Id
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