Function Import-SPRListItem {
<#
.SYNOPSIS
    Imports all items from a file into a SharePoint list.

.DESCRIPTION
    Imports all items from a file into a SharePoint list.

    To import from any other types of objects, use Add-SPRListItem.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER List
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER Path
    The target dat (compressed xml) file location.

.PARAMETER AutoCreateList
    Autocreate the SharePoint list if it does not exist.
    
.PARAMETER AsUser
    Import the item as a specific user.
    
.PARAMETER Quiet
    Do not output new item. Makes imports faster; useful for automated imports.
 
.PARAMETER InputObject
    Allows piping from Get-ChildItem

.PARAMETER LogToList
    You can log imports and export results to a list. Note this has to be a list from Get-SPRList.
  
.PARAMETER WhatIf
    If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

.PARAMETER Confirm
    If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
 
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Import-SPRListItem -Site intranet.ad.local -List 'My List' -Path C:\temp\mylist.dat

    Imports all items from C:\temp\mylist.dat to My List on intranet.ad.local

.EXAMPLE
    Get-SPRListItem -Path C:\temp\mylist.dat | Import-SPRListItem -List 'My List' -Site intranet.ad.local

    Imports all items from C:\temp\mylist.dat to My List on intranet.ad.local
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Position = 0, Mandatory, HelpMessage = "Human-readble SharePoint list name")]
        [string]$List,
        [string[]]$Path,
        [switch]$AutoCreateList,
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [switch]$Quiet,
        [string]$AsUser,
        [Microsoft.SharePoint.Client.List]$LogToList,
        [parameter(ValueFromPipeline)]
        [System.IO.FileInfo[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Path) {
                try {
                    $InputObject = Get-ChildItem -Path $Path -ErrorAction Stop
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                    return
                }
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Path pipe in the results of Get-ChildItem"
                return
            }
        }
        foreach ($file in $InputObject) {
            try {
                try {
                    $datatypemap = Import-PSFClixml -Path $file | Select-Object -ExpandProperty SPReplicatorDataType
                }
                catch {
                    # Don't care because it may or may not exist
                }
                if ($file.length/1MB -gt 100) {
                    $items = Import-PSFClixml -Path $file | Select-Object -ExpandProperty Data | Add-SPRListItem -Site $Site -Credential $Credential -List $List -AutoCreateList:$AutoCreateList -AsUser $AsUser -Quiet:$Quiet -LogToList $LogToList -DataTypeMap $datatypemap
                }
                else {
                    $items = Import-PSFClixml -Path $file | Select-Object -ExpandProperty Data
                    Add-SPRListItem -Site $Site -Credential $Credential -List $List -AutoCreateList:$AutoCreateList -InputObject $items -AsUser $AsUser -Quiet:$Quiet -LogToList $LogToList -DataTypeMap $datatypemap
                }
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
            }
        }
    }
}