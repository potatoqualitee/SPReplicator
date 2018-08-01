Function Get-SPRListItem {
<#
.SYNOPSIS
    Returns data from a SharePoint list.

.DESCRIPTION
    Returns data from a SharePoint list.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER List
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.
    
.PARAMETER Id
    Return only rows with specific IDs

.PARAMETER View
    Return only rows from a specific view
    
.PARAMETER Since
    Show only files modified since a specific date.
    
.PARAMETER InputObject
    Allows piping from Get-SPRList

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRListItem -Site intranet.ad.local -List 'My List'

    Gets data from My List on intranet.ad.local. Figures out the wsdl address automatically.

.EXAMPLE
    Get-SPRList -List 'My List' -Site intranet.ad.local | Get-SPRListItem

     Gets data from My List on intranet.ad.local.

.EXAMPLE
    Get-SPRListItem -Site intranet.ad.local -List 'My List' -Credential ad\user

    Gets data from My List and logs into the webapp as ad\user.

.EXAMPLE
    Get-SPRListItem -Site sharepoint2016 -List 'My List' -Id 100, 101, 105

    Gets list items with ID 100, 101 and 105
    
.EXAMPLE
    Get-SPRListItem -Site sharepoint2016 -List 'My List' -View 'My Tasks'

    Gets list items included in the view My Tasks
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [string]$List,
        [int[]]$Id,
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [string]$View,
        [datetime]$Since,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if ($View -and $Since) {
            Stop-PSFFunction -Message "Please specify either View or Since, not both"
            return
        }
        
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SprList -Site $Site -Credential $Credential -List $List
            }
            elseif ($script:spsite) {
                $InputObject = Get-SPRList -List $List
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and List pipe in results from Get-SPRList"
                return
            }
        }
        
        foreach ($thislist in $InputObject) {
            if ($thislist -is [Microsoft.SharePoint.Client.View]) {
                $listview = $thislist.ListObject.Views.GetByTitle($thislist.Title)
                $thislist = $thislist.ListObject
                $thislist.Context.Load($listview)
                $thislist.Context.ExecuteQuery()
                $caml = New-Object Microsoft.SharePoint.Client.CamlQuery
                $caml.ViewXml = "<View><Query>$($listview.ViewQuery)</Query></View>"
                $listItems = $thislist.GetItems($caml)
                $thislist.Context.Load($listItems)
                $thislist.Context.ExecuteQuery()
            }
            
            try {
                Write-PSFMessage -Level Verbose -Message "Performing GetItems"
                if ($Id) {
                    $listItems = @()
                    foreach ($number in $Id) {
                        Write-PSFMessage -Level Verbose -Message "Getting item by ID $number"
                        $single = $thislist.GetItemById($number)
                        $thislist.Context.Load($single)
                        $thislist.Context.ExecuteQuery()
                        $listItems += $thislist.GetItemById($number)
                    }
                }
                elseif ($View) {
                    $listview = $thislist.Views.GetByTitle($View)
                    $thislist.Context.Load($listview)
                    $thislist.Context.ExecuteQuery()
                    $caml = New-Object Microsoft.SharePoint.Client.CamlQuery
                    $caml.ViewXml = "<View><Query>$($listview.ViewQuery)</Query></View>"
                    $listItems = $thislist.GetItems($caml)
                    $thislist.Context.Load($listItems)
                    $thislist.Context.ExecuteQuery()
                }
                elseif ($Since) {
                    $modifiedsince = $Since.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                    $caml = New-Object Microsoft.SharePoint.Client.CamlQuery
                    $caml.ViewXml = "<View><Query><Where><Gt><FieldRef Name='Modified' /><Value IncludeTimeValue='TRUE' Type='DateTime'>$modifiedsince</Value></Gt></Where></Query></View>"
                    $listItems = $thislist.GetItems($caml)
                    $thislist.Context.Load($listItems)
                    $thislist.Context.ExecuteQuery()
                }
                elseif (-not $listview) {
                    $listItems = $thislist.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
                    $thislist.Context.Load($listItems)
                    $thislist.Context.ExecuteQuery()
                }
                
                $fields = $listItems | Select-Object -First 1 -ExpandProperty FieldValues
                $baseobject = [pscustomobject]@{ }
                
                foreach ($column in $fields.Keys) {
                    Add-Member -InputObject $baseobject -NotePropertyName $column -NotePropertyValue $null
                }
                Add-Member -InputObject $baseobject -NotePropertyName ListObject -NotePropertyValue $null
                Add-Member -InputObject $baseobject -NotePropertyName ListItem -NotePropertyValue $null
                
                foreach ($item in $listItems) {
                    $object = $baseobject.PSObject.Copy()
                    $object.ListObject = $thislist
                    $object.ListItem = $item
                    foreach ($fieldName in $item.FieldValues.Keys) {
                        $value = $item.FieldValues[$fieldName]
                        if ($value -match 'Microsoft\.SharePoint\.Client.') {
                            $object.$fieldName = $item.FieldValues[$fieldName].LookupValue
                        }
                        elseif ($value -is [array]) {
                            $object.$fieldName = ($value -join ", ")
                        }
                        else {
                            $object.$fieldName = $value
                        }
                    }
                    Select-DefaultView -InputObject $object -ExcludeProperty Order, ListObject, ListItem, ContentTypeId, _HasCopyDestinations, _CopySource, owshiddenversion, WorkflowVersion, _UIVersion, _UIVersionString, _ModerationStatus, _ModerationComments, InstanceID, WorkflowInstanceID, Last_x0020_Modified, Created_x0020_Date, FSObjType, SortBehavior, FileLeafRef, UniqueId, SyncClientId, ProgId, ScopeId, File_x0020_Type, MetaInfo, _Level, _IsCurrentVersion, ItemChildCount, FolderChildCount, Restricted, AppAuthor, AppEditor
                }
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
            }
        }
    }
}