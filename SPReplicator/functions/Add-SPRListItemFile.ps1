Function Add-SPRListItemFile {
<#
.SYNOPSIS
    Saves items from a SharePoint list to a file.

.DESCRIPTION
     Saves items from a SharePoint list to a file.

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
    The target directory. The file will be saved with its filename on SharePoint

.PARAMETER LogToList
    You can log imports and export results to a list. Note this has to be a list from Get-SPRList.
  
.PARAMETER InputObject
    Allows piping from Get-ChildItem

 .PARAMETER Overwrite
   Overwrite destination file if it exists
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Save-SPRListItemFile -Site intranet.ad.local -List 'My List' -Path C:\temp

    Saves all files (attachments/documents) from My List on intranet.ad.local to C:\temp\

.EXAMPLE
    Get-SPRListItem -List 'My List' -Site intranet.ad.local | Where Title -match 'cupcake' | Save-SPRListItemFile -Path C:\temp\

    Saves files (attachments/documents) from My List matching cupcake from intranet.ad.local to C:\temp\
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
        [Microsoft.SharePoint.Client.List]$ListObject,
        [string[]]$Path,
        [Microsoft.SharePoint.Client.List]$LogToList,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$Overwrite,
        [switch]$EnableException
    )
    begin {
        $start = Get-Date
        $count = 0
    }
    process {
        if (-not $ListObject) {
            if ($Site) {
                $ListObject += Get-SPRList -Site $Site -Credential $Credential -List $List -Web $Web
            }
            elseif ($script:spsite) {
                $ListObject += Get-SPRList -List $List -Web $Web
            }
            else {
                $failure = $true
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify some kinda list"
                return
            }
        }
        
        if (-not $InputObject) {
            if ($Path) {
                $InputObject = Get-ChildItem -Path $Path
            }
            else {
                $failure = $true
                Stop-PSFFunction -EnableException:$EnableException -Message "No files to upload"
                return
            }
        }
        
        foreach ($thislist in $ListObject) {
            foreach ($file in $InputObject) {
                try {
                    $fileName = Split-Path "$file" -Leaf
                    [System.IO.FileStream]$filestream = [System.IO.File]::Open($file, [System.IO.FileMode]::Open)
                    $newfile = New-Object Microsoft.SharePoint.Client.FileCreationInformation
                    $newfile.Overwrite = $Overwrite
                    $newfile.ContentStream = $filestream
                    $newfile.URL = $fileName
                    $upload = $thislist.RootFolder.Files.Add($newfile)
                    $listItem = $upload.ListItemAllFields
                    $thislist.Context.Load($thislist)
                    $thislist.Context.ExecuteQuery()
                    $filestream.Close()
                    $filestream.Dispose()
                    $count++
                }
                catch {
                    $failure = $true
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                }
                
                $ListObject | Get-SPRListItem -Id $listItem.Id
            }
        }
    }
    end {
        if ($LogToList) {
            $thislist = $ListObject | Select-Object -First 1 -ExpandProperty ListObject
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
                ItemCount = $count
                Result = $result
                Type  = "Add"
                RunAs = $currentuser
                Duration = $duration
                URL   = $url
                FinishTime = Get-Date
                Message = $errormessage
            } | Add-LogListItem -ListObject $LogToList -Quiet
        }
    }
}