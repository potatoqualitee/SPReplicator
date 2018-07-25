Function Export-SPRListData {
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

.PARAMETER InputObject
    Allows piping from Get-SPRList or Get-SPRListData

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Export-SPRListData -Site intranet.ad.local -List 'My List' -Path C:\temp\mylist.xml

    Exports all items from My List on intranet.ad.local to C:\temp\mylist.xml

.EXAMPLE
    Get-SPRListData -List 'My List' -Site intranet.ad.local |Export-SPRListData -Path C:\temp\mylist.xml

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
                $InputObject = Get-SprListData -Site $Site -Credential $Credential -List $List
            }
            elseif ($global:spsite) {
                $InputObject = Get-SprListData -List $List
            }
            else {
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
            $columnsnames = $columns.Name | Select-Object -Unique
            $data = $collection | Select-Object -Property $columnsnames
            Export-Clixml -InputObject $data -Path $Path -ErrorAction Stop
            Get-ChildItem -Path $Path -ErrorAction Stop
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
        }
    }
}