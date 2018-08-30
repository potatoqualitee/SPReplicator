Function Get-SPRListFolder {
<#
.SYNOPSIS
    Gets a list of folders in a list.

.DESCRIPTION
    Gets a list of folders in a list.

.PARAMETER Name
    Name of the folder. If no name is provided, all folders will be returned.
   
.PARAMETER List
    The human readable list name. So 'My List' as opposed to 'My List', unless you named it MyList.

.PARAMETER Web
    The human readable web name. So 'My Web' as opposed to 'MyWeb', unless you named it MyWeb.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See New-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER InputObject
    Piped input from a list
  
.PARAMETER Recurse
    Recurse and display *all* folders in a library or list.
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRListFolder -Site sharepoint.ad.local -List 'My List'

    Gets a list of all folders in the root of
  
 .EXAMPLE
    Get-SPRListFolder -List 'My List' -Recurse

    Gets a list of all folders in My List
    
.EXAMPLE
    Get-SPRList -List 'My List' | Get-SPRListFolder -Name Sup

    Get a folder called Sup on My List
    
.EXAMPLE
    Get-SPRList -List 'My List' | Get-SPRListFolder -Name '/First Folder/Second Folder/Third Folder'

    Gets the folder called Third Folder, under Second Folder which is under the First Folder
#>
    [CmdletBinding()]
    param (
        [string[]]$Name,
        [Parameter(HelpMessage = "Human-readble SharePoint list name")]
        [string[]]$List,
        [Parameter(HelpMessage = "Human-readble SharePoint web name")]
        [string[]]$Web,
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [Parameter(ValueFromPipeline)]
        [Microsoft.SharePoint.Client.List[]]$InputObject,
        [switch]$Recurse,
        [switch]$EnableException
    )
    process {
        if ($Name -and $Recurse) {
            Stop-PSFFunction -Message "You must either specify Name or Recurse, but not both"
            return
        }
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SprList -Site $Site -Credential $Credential -List $List -Web $Web
            }
            elseif ($script:spsite) {
                $InputObject = Get-SPRList -List $List -Web $Web
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and List pipe in results from Get-SPRList"
                return
            }
        }
        try {
            foreach ($thislist in $InputObject) {
                Write-PSFMessage -Level Verbose -Message "Loading $($thislist.Title) root folder"
                $folder = $thislist.RootFolder
                $thislist.Context.Load($folder)
                $thislist.Context.ExecuteQuery()
                $rooturl = $folder.ServerRelativeUrl
                
                if ($Name) {
                    foreach ($foldername in $Name) {
                        $foldername = $foldername.Trim()
                        if (-not $foldername.StartsWith($rooturl)) {
                            $foldername = $foldername.TrimStart("/")
                            $foldername = "$rooturl/$foldername"
                        }
                        Write-PSFMessage -Level Verbose -Message "Searching for $foldername"
                        $searchfolder = $thislist.Context.RootWeb.GetFolderByServerRelativeUrl($foldername)
                        $thislist.Context.Load($searchfolder)
                        $thislist.Context.ExecuteQuery()
                        $rooturl = $folder.ServerRelativeUrl
                        if ($searchfolder.Name) {
                            $searchfolder | Select-SPRObject -Property Name, ServerRelativeUrl, TimeCreated, TimeLastModified
                        }
                    }
                }
                elseif ($Recurse) {
                    $folders = $thislist.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllFoldersQuery())
                    $thislist.Context.Load($folders)
                    $thislist.Context.ExecuteQuery()
                    
                    foreach ($subfolder in $folders) {
                        $thislist.Context.Load($subfolder.Folder)
                        $thislist.Context.ExecuteQuery()
                        $subfolder.Folder | Select-SPRObject -Property Name, ServerRelativeUrl, TimeCreated, TimeLastModified
                    }
                }
                else {
                    $folder | Select-SPRObject -Property Name, ServerRelativeUrl, TimeCreated, TimeLastModified
                }
            }
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
        }
    }
}