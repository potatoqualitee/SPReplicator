Function Add-SPRListItem {
 <#
.SYNOPSIS
    Adds items to a SharePoint list.

.DESCRIPTION
    Adds items to a SharePoint list.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.
.PARAMETER ListName
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER AutoCreateList
    If a Sharepoint list does not exist, one will be created based off of the guessed column types.

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
    $csv = Import-Csv -Path C:\temp\listitems.csv
    Add-SPRListItem -Site intranet.ad.local -ListName 'My List' -InputObject $mycsv

    Adds data from listitems.csv into the My List SharePoint list, so long as there are matching columns.

.EXAMPLE
    Import-Csv -Path C:\temp\listitems.csv | Add-SPRListItem -Site intranet.ad.local -ListName 'My List'

    Adds data from listitems.csv into the My List SharePoint list, so long as there are matching columns.

.EXAMPLE
    $object = @()
    $object += [pscustomobject]@{ Title = 'Hello'; TestColumn = 'Sample Data'; }
    $object += [pscustomobject]@{ Title = 'Hello2'; TestColumn = 'Sample Data2'; }
    $object += [pscustomobject]@{ Title = 'Hello3'; TestColumn = 'Sample Data3'; }
    Add-SPRListData -Site intranet.ad.local -ListName 'My List' -InputObject $object

    Adds data from a custom object $object into the My List SharePoint list, so long as there are matching columns (Title and TestColumn).
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Position = 0, Mandatory, HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [parameter(ValueFromPipeline)]
        [object[]]$InputObject,
        [switch]$AutoCreateList,
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    begin {
        function Add-Row {
            [cmdletbinding()]
            param (
                [object[]]$Row,
                [object[]]$ColumnInfo
            )
            foreach ($currentrow in $row) {
                $columns = $currentrow.PsObject.Members | Where-Object MemberType -eq NoteProperty | Select-Object -ExpandProperty Name

                if (-not $columns) {
                    $columns = $currentrow.PsObject.Members | Where-Object MemberType -eq Property | Select-Object -ExpandProperty Name |
                    Where-Object { $_ -notin 'RowError', 'RowState', 'Table', 'ItemArray', 'HasErrors' }
                }

                foreach ($fieldname in $columns) {
                    $datatype = ($ColumnInfo | Where-Object Name -eq $fieldname).Type
                    if ($type -eq 'DateTime') {
                        $value = (($currentrow.$fieldname).ToUniversalTime()).ToString("yyyy-MM-ddTHH:mm:ssZ")
                    }
                    else {
                        $value = [System.Security.SecurityElement]::Escape($currentrow.$fieldname)
                    }

                    # Skip reserved words, so far is only ID
                    if ($fieldname -notin 'ID') {
                        Write-PSFMessage -Level Verbose -Message "Adding $fieldname to row"
                        $newItem.set_item($fieldname, $value)
                    }
                    else {
                        Write-PSFMessage -Level Verbose -Message "Not adding $fieldname to row (reserved name)"
                    }
                }
            }
            $newItem
        }
    }
    process {
        $list = Get-SPRList -Site $Site -Credential $Credential -ListName $ListName
        
        if (-not $list) {
            if (-not $AutoCreateList) {
                Stop-PSFFunction -EnableException:$EnableException -Message "List does not exist. To auto-create, use -AutoCreateList"
                return
            } else {
                $list = New-SPRList -Site $Site -Credential $Credential -ListName $ListName

                $datatable = $InputObject | Select-Object -First 1 | ConvertTo-DataTable
                $columns = ($list | Get-SPRColumnDetail).Title
                $newcolumns = $datatable.Columns | Where-Object ColumnName -NotIn $columns

                Write-PSFMessage -Level Debug -Message "All columns: $columns"
                Write-PSFMessage -Level Verbose -Message "New columns: $newcolumns"

                foreach ($column in $newcolumns) {
                    $type = switch ($column.DataType.Name) {
                        "Double" { "Number" }
                        "Int16" { "Number" }
                        "Int32" { "Number" }
                        "Int64" { "Number" }
                        "Single" { "Number" }
                        "UInt16" { "Number" }
                        "UInt32" { "Number" }
                        "UInt64" { "Number" }
                        "Text" { "Text" }
                        "Note" { "Note" }
                        "DateTime" { "DateTime" }
                        "Boolean" { "Boolean" }
                        "Number" { "Number" }
                        "Decimal" { "Currency" }
                        "Guid" { "Guid" }
                        default { "Text" }
                    }
                    $cname = $column.ColumnName
                    $null = $list | Add-SPRColumn -ColumnName $cname -Type $type
                }
            }
        }

        $columns = $list | Get-SPRColumnDetail | Where-Object Type -ne Computed | Sort-Object Listname, DisplayName

        foreach ($row in $InputObject) {
            try {
            $itemCreateInfo = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
            $newItem = $list.addItem($itemCreateInfo)
            $newItem = Add-Row -Row $row -ColumnInfo $columns
            $newItem.update()
            $list.Context.Load($newItem)
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
            }

            Write-PSFMessage -Level Verbose -Message "Queued row for $listname"
            if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $listname -Action "Adding Batch")) {
                try {
                    # Do batch
                    $list.Context.ExecuteQuery()
                    Write-PSFMessage -Level Verbose -Message "Getting that $($newItem.Id)"
                    Get-SPRListData -ListName $listname -Id $newItem.Id
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                }
            }
        }
    }
}