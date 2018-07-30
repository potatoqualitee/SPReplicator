Function Export-SPRListItem {
<#
.SYNOPSIS
    Exports all items from a SharePoint list to a file.

.DESCRIPTION
     Exports all items from a SharePoint list to a file.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER List
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER Path
    The target xml file location.

.PARAMETER LogToList
    You can log imports and export results to a list. Note this has to be a list from Get-SPRList.
  
.PARAMETER InputObject
    Allows piping from Get-SPRList or Get-SPRListItem

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Export-SPRListItem -Site intranet.ad.local -List 'My List' -Path C:\temp\mylist.xml

    Exports all items from My List on intranet.ad.local to C:\temp\mylist.xml

.EXAMPLE
    Get-SPRListItem -List 'My List' -Site intranet.ad.local |Export-SPRListItem -Path C:\temp\mylist.xml

    Exports all items from My List on intranet.ad.local to C:\temp\mylist.xml
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [string]$List,
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [Microsoft.SharePoint.Client.List]$LogToList,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    begin {
        $collection = @()
    }
    process {
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SPRListItem -Site $Site -Credential $Credential -List $List
            }
            elseif ($global:spsite) {
                $InputObject = Get-SPRListItem -List $List
            }
            else {
                $failure = $true
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and List pipe in results from Get-SPRList"
                return
            }
        }
        $collection += $InputObject
    }
    end {
        try {
            $columns = $collection | Select-Object -First 1 -ExpandProperty ListObject | Get-SPRColumnDetail |
            Where-Object {
                -not $psitem.Hidden -and -not $PSItem.ReadOnly -and $PSItem.Type -notin 'Computed', 'Lookup' -and $PSItem.Name -notin 'Created', 'Author', 'Editor', '_UIVersionString', 'Modified', 'Attachments'
            }
            $spdatatype = $columns| Select-SPRObject -Property Name, 'TypeAsString as Type'
            $columnsnames = $columns.Name | Select-Object -Unique
            $data = $collection | Select-Object -Property $columnsnames
            Add-Member -InputObject $data -NotePropertyName SPReplicatorDataType -NotePropertyValue $spdatatype
            Export-Clixml -InputObject $data -Path $Path -ErrorAction Stop
            Get-ChildItem -Path $Path -ErrorAction Stop
        }
        catch {
            $failure = $true
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
        }
        
        ###########################################################################
        if ($LogToList) {
            $thislist = $collection | Select-Object -First 1 -ExpandProperty ListObject
            if ($thislist) {
                $thislist.Context.Load($thislist)
                $thislist.Context.ExecuteQuery()
                $thislist.Context.Load($thislist.RootFolder)
                $thislist.Context.ExecuteQuery()
                $url = "$($thislist.Context.Url)$($thislist.RootFolder.ServerRelativeUrl)"
            }
            if ($failure) {
                $result = "Failed"
                $errormessage = Get-PSFMessage -Errors | Select-Object -Last 1 -ExpandProperty Message
            }
            else {
                $result = "Succeeded"
            }
            [pscustomobject]@{
                Title      = $thislist.Title
                ItemCount  = $data.Count
                Result     = $result
                Type       = "Export"
                URL        = $url
                FinishTime = Get-Date
                Message    = $errormessage
            } | Add-LogListItem -ListObject $LogToList -Quiet
        }
    }
}