Function Update-SPRListItem {
<#
.SYNOPSIS
    Updates items from a SharePoint list.

.DESCRIPTION
    Updates items from a SharePoint list.

.PARAMETER List
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

.PARAMETER Quiet
    Do not output new item. Makes imports faster; useful for automated imports.
    
.PARAMETER InputObject
    Allows piping from Get-SPRListItem.

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
    Get-SPRListItem -List 'My List' -Site intranet.ad.local | Update-SPRListItem -UpdateObject $updates

    Update 'My List' from modified rows contained within C:\temp\mylist-updated.xml Prompts for confirmation.
    
    Uses ID to compare items.

.EXAMPLE
    $updates = Import-CliXml -Path C:\temp\mylist-updated.xml
    Get-SPRListItem -List 'My List' -Site intranet.ad.local | Update-SPRListItem -UpdateObject $updates -KeyColumn SSN -Confirm:$false

    Update 'My List' from modified rows contained within C:\temp\mylist-updated.xml Does not prompt for confirmation.
    
    Uses SSN to compare items.
#>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [string]$List,
        [string[]]$Column,
        [object[]]$UpdateObject,
        [string]$KeyColumn = 'ID',
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object[]]$InputObject,
        [switch]$Quiet,
        [switch]$EnableException
    )
    begin {
        $script:updates = @()
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
                        
                        if (($currentrow.ListItem[$fieldname]) -ne $fieldupdate) {
                            if ($fieldname -in "Author", "Editor") {
                                Write-PSFMessage -Level Warning -Message "Please use Update-SPRListItemAuthorEditor to update Author or Editor"
                            }
                            else {
                                $runupdate = $true
                                $currentrow.ListItem[$fieldname] = $fieldupdate
                                $currentrow.ListItem.Update()
                            }
                            Write-PSFMessage -Level Debug -Message "Updating $fieldname setting to $fieldupdate"
                        }
                    }
                    else {
                        Write-PSFMessage -Level Debug -Message "Not updating $fieldname (reserved name)"
                    }
                }
                if ($runupdate) {
                    $script:updates += $currentrow
                }
            }
        }
    }
    process {
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SPRListItem -Site $Site -Credential $Credential -List $List -Id $Id
            }
            elseif ($script:spsite) {
                $InputObject = Get-SPRListItem -List $List -Id $Id
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and List pipe in results from Get-SPRList"
                return
            }
        }
        
        if (-not $InputObject) {
            Stop-PSFFunction -EnableException:$EnableException -Message "No records to update."
            return
        }
        
        if ($InputObject -is [Microsoft.SharePoint.Client.List]) {
            $InputObject = $InputObject | Get-SPRListItem
        }
        
        foreach ($item in $InputObject) {
            if (-not $item.ListObject) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Invalid InputObject" -Continue
            }
            $thislist = $item.ListObject
            $updateitem = $UpdateObject | Where-Object $KeyColumn -eq $item.ListItem.$KeyColumn
            
            if (-not $updateitem) {
                Write-PSFMessage -Level Verbose -Message "No matches for ID $($item.ListItem.Id)"
                continue
            }
            if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $thislist.Context.Url -Action "Updating record $($item.Id) on $($thislist.Title)")) {
                try {
                    if (-not $Column) {
                        $listcolumns = $thislist | Get-SPRColumnDetail | Where-Object { $_.Type -notin 'Computed', 'Attachments' -and -not $_.ReadOnlyField -and $_.Name -notin 'FileLeafRef', 'MetaInfo', 'Order' } | Sort-Object List, DisplayName
                        $listcolumns += 'Author', 'Editor'
                        Write-PSFMessage -Level Debug -Message "List columns: $($listcolumns.Title)"
                        $updatecolumns = $updateitem | Get-Member -MemberType *property*
                        Write-PSFMessage -Level Debug -Message "Update columns: $($updatecolumns.Name)"
                        $Column = ($listcolumns.Name | Where-Object { $_ -in $updatecolumns.Name })
                        Write-PSFMessage -Level Verbose -Message "Column = $Column"
                    }
                    
                    Update-Row -Row $item -ColumnNames $Column -UpdateItem $updateitem
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                }
            }
        }
    }
    end {
        if ($script:updates.Id) {
            Write-PSFMessage -Level Debug -Message "Executing ExecuteQuery"
            $script:spsite.ExecuteQuery()
            if (-not $Quiet) {
                foreach ($listitem in $script:updates) {
                    Get-SPRListItem -List $listitem.ListObject.Title -Id $listitem.ListItem.Id
                }
            }
        }
        else {
            Write-PSFMessage -Level Verbose -Message "Nothing to update"
        }
    }
}