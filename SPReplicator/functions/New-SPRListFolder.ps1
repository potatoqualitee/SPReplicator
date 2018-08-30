Function New-SPRListFolder {
<#
.SYNOPSIS
    Creates a folder in a list.

.DESCRIPTION
    Creates a folder in a list.

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
    Piped input from a web
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    New-SPRListFolder -List 'My List' -Name Projects

    Creates a folder called Projects on My List
    
.EXAMPLE
    Get-SPRList -List 'My List' | New-SPRListFolder -Name '/First Folder/Second Folder/Third Folder'

    Creates three folders if they don't exist.

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
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($List) {
                $InputObject = Get-SprList -Site $Site -Credential $Credential -List $List -Web $Web
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and List or pipe in results from Get-SPRList"
                return
            }
        }
        try {
            foreach ($thislist in $InputObject) {
                foreach ($foldername in $name) {
                    Write-PSFMessage -Level Verbose -Message "Getting list RootFolder"
                    $folder = $thislist.RootFolder
                    $thislist.Context.Load($folder)
                    $thislist.Context.ExecuteQuery()
                    
                    $folders = $foldername -split "/"
                    foreach ($subfolder in $folders) {
                        if ($subfolder) {
                            Write-PSFMessage -Level Verbose -Message "Processing part $subfolder of $foldername"
                            $foldernames = $folder.Folders
                            $thislist.Context.Load($foldernames)
                            $thislist.Context.ExecuteQuery()
                            $exists = $foldernames | Where-Object Name -eq $subfolder
                            if ($exists) {
                                Write-PSFMessage -Level Verbose -Message "$subfolder already exists"
                                $folder = $thislist.Context.RootWeb.GetFolderByServerRelativeUrl($exists.ServerRelativeUrl)
                                $thislist.Context.Load($folder)
                                $thislist.Context.ExecuteQuery()
                            }
                            else {
                                $folder = $folder.Folders.Add($subfolder)
                                $thislist.Update()
                                $thislist.Context.ExecuteQuery()
                            }
                        }
                    }
                }
                $thislist | Get-SPRListFolder -Name $name | Sort-Object -Unique ServerRelativeUrl
            }
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
        }
    }
}