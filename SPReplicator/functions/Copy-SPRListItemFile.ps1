Function Copy-SPRListItemFile {
<#
.SYNOPSIS
    Copies items from a SharePoint list to another SharePoint list.

.DESCRIPTION
     Copies items from a SharePoint list to another SharePoint list.

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
    Allows piping from Get-SPRList or Get-SPRListItem

.PARAMETER Overwrite
    Overwrite destination file if it exists
  
.PARAMETER Quiet
    Do not output new item. Makes imports faster; useful for automated imports.
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRListItem -Site sharepoint2016 -List Sup | Copy-SPRListItemFile -List sup2

    Copies all documents from Sup to sup2, including metadata and the author/editor.
    If the file exists on the destination, it will be skipped.
 
.EXAMPLE
    Get-SPRListItem -Site sharepoint2016 -List Sup | Copy-SPRListItemFile -List sup2 -Overwrite

    Copies all documents from Sup to sup2, including metadata and the author/editor.
    If the file exists on the destination, it will be overwritten.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [string[]]$List,
        [Parameter(Position = 1, HelpMessage = "Human-readble SharePoint web name")]
        [string[]]$Web,
        [Parameter(Position = 2, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [Microsoft.SharePoint.Client.List]$LogToList,
        [parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,
        [switch]$Overwrite,
        [switch]$Quiet,
        [switch]$EnableException
    )
    begin {
        $start = Get-Date
        $count = 0
    }
    process {
        $ListObject = Get-SPRList -Site $Site -Credential $Credential -List $List -Web $Web
        
        if (-not $ListObject) {
            $failure = $true
            Stop-PSFFunction -EnableException:$EnableException -Message "List not found"
            return
        }
        
        if ($InputObject -is [Microsoft.SharePoint.Client.List]) {
            $InputObject = $InputObject | Get-SPRListItem
        }
        
        foreach ($item in $InputObject) {
            foreach ($thislist in $ListObject) {
                try {
                    $file = $item.ListItem.File
                    $item.ListObject.Context.Load($item.ListItem)
                    $item.ListObject.Context.Load($file)
                    $item.ListObject.Context.ExecuteQuery()
                    $fileName = $file.Name
                    
                    if (-not $fileName) {
                        $failure = $true
                        Stop-PSFFunction -EnableException:$EnableException -Message "$($item.Title) does not have an associated file" -Continue
                    }
                    
                    # upload
                    [Microsoft.SharePoint.Client.FileInformation]$fileInfo = [Microsoft.SharePoint.Client.File]::OpenBinaryDirect($item.ListObject.Context, $file.ServerRelativeUrl)
                    $newfile = New-Object Microsoft.SharePoint.Client.FileCreationInformation
                    $newfile.Overwrite = $Overwrite
                    $newfile.Content = $fileInfo.Stream.ReadByte()
                    $newfile.URL = $fileName
                    $upload = $thislist.RootFolder.Files.Add($newfile)
                    $listItem = @{
                        ListItem = $upload.ListItemAllFields
                        ListObject = $thislist
                    }
                    $listItem.ListItem['Created'] = $item.Created
                    $thislist.Context.Load($thislist)
                    $thislist.Context.ExecuteQuery()
                    $count++
                }
                catch {
                    $failure = $true
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
                }
                
                # updates
                $null = $listItem | Update-SPRListItem -UpdateObject $item -KeyColumn Title -Confirm:$false
                $userobject = Get-SPRUser -Identity $item.Author
                if ($userobject) {
                    $null = $listItem | Update-SPRListItemAuthorEditor -UserObject $userobject -Confirm:$false
                }
                if (-not $Quiet) {
                    $thislist | Get-SPRListItem -Id $listItem.Id
                }
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
                Type  = "Copy"
                RunAs = $currentuser
                Duration = $duration
                URL   = $url
                FinishTime = Get-Date
                Message = $errormessage
            } | Add-LogListItem -ListObject $LogToList -Quiet
        }
    }
}