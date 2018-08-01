Function Save-SPRListItemFile {
<#
.SYNOPSIS
    Saves items from a SharePoint list to a file.

.DESCRIPTION
     Saves items from a SharePoint list to a file.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER List
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER Path
    The target directory. The file will be saved with its filename on SharePoint

.PARAMETER LogToList
    You can log imports and export results to a list. Note this has to be a list from Get-SPRList.
  
.PARAMETER InputObject
    Allows piping from Get-SPRList or Get-SPRListItem

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Save-SPRListItemFile -Site intranet.ad.local -List 'My List' -Path C:\temp

    Saves items from My List on intranet.ad.local to C:\temp\

.EXAMPLE
    Get-SPRListItem -List 'My List' -Site intranet.ad.local | Where Title -match 'cupcake' | Save-SPRListItemFile -Path C:\temp\

    Saves items from My List matching cupcake from intranet.ad.local to C:\temp\
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
        $start = Get-Date
        $count = 0
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
        
        if ($InputObject -is [Microsoft.SharePoint.Client.List]) {
            $InputObject = $InputObject | Get-SPRListItem
        }
        
        foreach ($item in $InputObject) {
            try {
                $thislist = $item.ListObject
                $file = $item.ListItem.File
                $thislist.Context.Load($item.ListItem)
                $thislist.Context.Load($file)
                $thislist.Context.ExecuteQuery()
                $fileName = Join-Path $Path $file.Name
                
                if (-not $file.Name) {
                    $failure = $true
                    Stop-PSFFunction -EnableException:$EnableException -Message "$($item.Title) does not have an associated file" -Continue
                }
                
                # this is some crazy stuff, thx https://stackoverflow.com/a/20257788/2610398
                [Microsoft.SharePoint.Client.FileInformation]$fileInfo = [Microsoft.SharePoint.Client.File]::OpenBinaryDirect($thislist.Context, $file.ServerRelativeUrl)
                [System.IO.FileStream]$writeStream = [System.IO.File]::Open($fileName, [System.IO.FileMode]::Create)
                $fileInfo.Stream.CopyTo($writeStream)
                $writeStream.Close()
                Get-ChildItem $fileName
                $count++
            }
            catch {
                $failure = $true
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
            }
        }
    }
    end {
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
                $currentuser = $global:spsite.CurrentUser.ToString()
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
                ItemCount = $count
                Result = $result
                Type  = "Save"
                RunAs = $currentuser
                Duration = $duration
                URL   = $url
                FinishTime = Get-Date
                Message = $errormessage
            } | Add-LogListItem -ListObject $LogToList -Quiet
        }
    }
}