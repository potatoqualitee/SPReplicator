﻿Function Update-SPRListItem {
<#
.SYNOPSIS
    Updates items from a SharePoint list.

.DESCRIPTION
    Updates items from a SharePoint list.

.PARAMETER ListName
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER Column
    List of specific column(s) to be updated. If no columns are specified, we'll try to figure out which fields to update.

.PARAMETER UpdateObject
    An object that contains updated fields. This object must have an ID or an alternative KeyColumn.

.PARAMETER KeyColumn
    The column used for update comparisons - similar to a Primary Key in a SQL database. ID by default.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

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
    $updates = Import-CliXml -Path C:\temp\mylist-updated.xml
    Get-SPRListData -ListName 'My List' -Site intranet.ad.local | Update-SPRListItem -UpdateObject $updates

    Update 'My List' from modified rows contained within C:\temp\mylist-updated.xml Prompts for confirmation.
    
    Uses ID to compare items.

.EXAMPLE
    $updates = Import-CliXml -Path C:\temp\mylist-updated.xml
    Get-SPRListData -ListName 'My List' -Site intranet.ad.local | Update-SPRListItem -UpdateObject $updates -KeyColumn SSN -Confirm:$false

    Update 'My List' from modified rows contained within C:\temp\mylist-updated.xml Does not prompt for confirmation.
    
    Uses SSN to compare items.
#>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [string[]]$Column,
        [object[]]$UpdateObject,
        [string]$KeyColumn = 'ID',
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object[]]$InputObject,
        [switch]$EnableException
    )
    begin {
        function Update-Row {
            [cmdletbinding()]
            param (
                [object[]]$Row,
                [string[]]$ColumnNames,
                [object[]]$UpdateItem
            )
            foreach ($currentrow in $row) {
                $runupdate = $false
                foreach ($fieldname in $ColumnNames) {
                    # Skip reserved words, so far is only ID
                    if ($fieldname -notin 'ID') {
                        $fieldupdate = $UpdateItem.$fieldname
                        if (-not $fieldupdate) {
                            $fieldupdate = $UpdateItem[$fieldname]
                        }
                        
                        if (($item.ListItem[$fieldname]) -ne $fieldupdate) {
                            Write-PSFMessage -Level Verbose -Message "Updating $fieldname setting to $fieldupdate"
                            $runupdate = $true
                            $item.ListItem[$fieldname] = $fieldupdate
                        }
                    }
                    else {
                        Write-PSFMessage -Level Verbose -Message "Not updating $fieldname (reserved name)"
                    }
                }
                if ($runupdate) {
                    $item.ListItem.Update()
                    $global:spsite.ExecuteQuery()
                    $item.ListObject | Get-SPRListData -Id $item.Id
                }
                else {
                    Write-PSFMessage -Level Verbose -Message "Nothing to update for row with id $($item.Id)"
                }
            }
        }
    }
    process {
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SPRListData -Site $Site -Credential $Credential -ListName $ListName -Id $Id
            }
            elseif ($global:spsite) {
                $InputObject = Get-SPRListData -ListName $ListName -Id $Id
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and ListName pipe in results from Get-SPRList"
                return
            }
        }
        
        if (-not $InputObject) {
            Stop-PSFFunction -EnableException:$EnableException -Message "No records to update."
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
            $updateitem = $UpdateObject | Where-Object $KeyColumn -eq $item.ListItem.$KeyColumn
            
            if (-not $updateitem) {
                Write-PSFMessage -Level Verbose -Message "No matches for ID $($item.ListItem.Id)"
                continue
            }
            if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $list.Context.Url -Action "Updating record $($item.Id) from $($list.Title)")) {
                try {
                    if (-not $Column) {
                        $Column = $list | Get-SPRColumnDetail | Where-Object { $_.Type -notin 'Computed', 'Attachments' -and -not $_.ReadOnlyField -and $_.Name -notin 'FileLeafRef', 'MetaInfo','Order' } | Sort-Object Listname, DisplayName | Select-Object -ExpandProperty Name
                    }
                    
                    Write-PSFMessage -Level Verbose -Message "Updating $($item.Id) from $($list.Title)"
                    Update-Row -Row $item -ColumnNames $Column -UpdateItem $updateitem
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                }
            }
        }
    }
}