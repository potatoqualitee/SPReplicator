Function Export-SPRListItem {
<#
.SYNOPSIS
    Exports all items from a SharePoint list to a file.

.DESCRIPTION
     Exports all items from a SharePoint list to a file.


.PARAMETER List
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER Web
    The human readable web name. So 'My Web' as opposed to 'MyWeb', unless you named it MyWeb.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER Path
    The target dat (compressed xml) file location.

.PARAMETER LogToList
    You can log imports and export results to a list. Note this has to be a list from Get-SPRList.
  
.PARAMETER InputObject
    Allows piping from Get-SPRList or Get-SPRListItem

.PARAMETER EnableUserField
    Only relevant when using -AutoCreateList for Imports or Adds.
    
    By default, User fields will be exported as string fields. Use this to keep the User field datatype.

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Export-SPRListItem -Site intranet.ad.local -List 'My List' -Path C:\temp\mylist.dat

    Exports all items from My List on intranet.ad.local to C:\temp\mylist.dat

.EXAMPLE
    Get-SPRListItem -List 'My List' -Site intranet.ad.local |Export-SPRListItem -Path C:\temp\mylist.dat

    Exports all items from My List on intranet.ad.local to C:\temp\mylist.dat
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [string[]]$List,
        [Parameter(Position = 1, HelpMessage = "Human-readble SharePoint web name")]
        [string[]]$Web,
        [Parameter(Position = 2, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [Parameter(Mandatory)]
        [string]$Path,
        [Microsoft.SharePoint.Client.List]$LogToList,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableUserField,
        [switch]$EnableException
    )
    begin {
        $collection = @()
        $start = Get-Date
    }
    process {
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SPRListItem -Site $Site -Credential $Credential -List $List -Web $Web
            }
            elseif ($script:spsite) {
                $InputObject = Get-SPRListItem -List $List -Web $Web
            }
            else {
                $failure = $true
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and List pipe in results from Get-SPRList"
                return
            }
        }
        
        if ($InputObject -is [Microsoft.SharePoint.Client.List]) {
            $InputObject = $InputObject | Get-SPRListItem
        }
        
        $collection += $InputObject
    }
    end {
        try {
            $columns = $collection | Select-Object -First 1 -ExpandProperty ListObject | Get-SPRColumnDetail |
            Where-Object {
                -not $psitem.Hidden -and -not $PSItem.ReadOnly -and $PSItem.Type -notin 'Computed', 'Lookup' -and $PSItem.Name -notin 'Created', 'Author', 'Editor', '_UIVersionString', 'Modified', 'Attachments'
            }
            $spdatatype = $columns | Select-SPRObject -Property Name, 'TypeAsString as Type'
            
            if (-not $EnableUserField) {
                $tempdatatype = @()
                foreach ($dt in $spdatatype) {
                    $name = $dt.Name
                    $type = $dt.Type
                    if ($type -eq 'User') {
                        $type = 'Text'
                    }
                    $tempdatatype += [pscustomobject]@{
                        Name = $name
                        Type = $type
                    }
                }
                $spdatatype = $tempdatatype
            }
            
            $columnsnames = $columns.Name | Select-Object -Unique
            [PSCustomObject]@{
                SPReplicatorDataType = $spdatatype
                Data                 = $collection | Select-Object -Property $columnsnames
            } | Export-PSFClixml -Path $Path
            Get-ChildItem -Path $Path -ErrorAction Stop
        }
        catch {
            $failure = $true
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
        }
        
        if ($LogToList) {
            $thislist = $InputObject | Select-Object -First 1 -ExpandProperty ListObject
            if ($thislist) {
                $thislist.Context.Load($thislist)
                $thislist.Context.ExecuteQuery()
                $thislist.Context.Load($thislist.RootFolder)
                $thislist.Context.ExecuteQuery()
                $url = "$($thislist.Context.Url)$($thislist.RootFolder.ServerRelativeUrl)"
                $currentuser = $thislist.Context.CurrentUser.ToString()
            }
            else {
                $currentuser = $script:spsite.CurrentUser.ToString()
            }
            if ($failure) {
                $result = "Failed"
                $errormessage = Get-PSFMessage -Errors | Select-Object -Last 1 -ExpandProperty Message
            }
            else {
                $result = "Succeeded"
            }
            $elapsed = (Get-Date) - $start
            $duration = "{0:HH:mm:ss}" -f ([datetime]$elapsed.Ticks)
            [pscustomobject]@{
                Title = $thislist.Title
                ItemCount = ($collection).Count
                Result = $result
                Type  = "Export"
                RunAs = $currentuser
                Duration = $duration
                URL   = $url
                FinishTime = Get-Date
                Message = $errormessage
            } | Add-LogListItem -ListObject $LogToList -Quiet
        }
    }
}