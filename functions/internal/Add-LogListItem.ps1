Function Add-LogListItem {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(ValueFromPipeline)]
        [object[]]$InputObject,
        [switch]$Quiet,
        [string]$AsUser,
        [parameter(Mandatory)]
        [Microsoft.SharePoint.Client.List]$ListObject,
        [switch]$EnableException
    )
    begin {
        if ($AsUser) {
            Write-PSFMessage -Level Output -Message "Validating user. This may take a moment."
            $userobject = Get-SPRUser -Site $Site -UserName $AsUser
        }
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
                        Write-PSFMessage -Level Debug -Message "Adding $fieldname to row"
                        $newItem.set_item($fieldname, $value)
                    }
                    else {
                        Write-PSFMessage -Level Debug -Message "Not adding $fieldname to row (reserved name)"
                    }
                }
            }
            $newItem
        }
    }
    process {
        foreach ($row in $InputObject) {
            if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target LogList -Action "Adding log entry")) {
                try {
                    $itemCreateInfo = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
                    $newItem = $ListObject.AddItem($itemCreateInfo)
                    $newItem = Add-Row -Row $row -ColumnInfo $columns
                    $newItem.Update()
                    $ListObject.Context.Load($newItem)
                    
                    Write-PSFMessage -Level Verbose -Message "Adding log entry"
                    $ListObject.Context.ExecuteQuery()
                    
                    if ($AsUser) {
                        Write-PSFMessage -Level Verbose -Message "Getting that $($newItem.Id)"
                        Get-SPRListItem -List $List -Id $newItem.Id | Update-SPRListItemAuthorEditor -UserObject $userobject -Quiet:$Quet -Confirm:$false
                    }
                    elseif (-not $Quiet) {
                        Write-PSFMessage -Level Verbose -Message "Getting that $($newItem.Id)"
                        Get-SPRListItem -List $List -Id $newItem.Id
                    }
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                    return
                }
            }
        }
    }
}