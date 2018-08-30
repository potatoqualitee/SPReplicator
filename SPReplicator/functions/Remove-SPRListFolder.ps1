Function Remove-SPRListFolder {
<#
.SYNOPSIS
    Removes folders from a list.

.DESCRIPTION
    Removes folders from a list.

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
  
.PARAMETER WhatIf
    If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

.PARAMETER Confirm
    If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
  
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Remove-SPRListFolder -Site sharepoint.ad.local -List 'My List'

    Removes a list of all folders in the root of
  
 .EXAMPLE
    Remove-SPRListFolder -List 'My List' -Recurse

    Removes a list of all folders in My List
    
.EXAMPLE
    Remove-SPRList -List 'My List' | Remove-SPRListFolder -Name Sup

    Remove a folder called Sup on My List
    
.EXAMPLE
    Remove-SPRList -List 'My List' | Remove-SPRListFolder -Name '/First Folder/Second Folder/Third Folder'

    Removes the folder called Third Folder, under Second Folder which is under the First Folder
#>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
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
        [Microsoft.SharePoint.Client.Folder[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            $InputObject = Get-SprListFolder -Site $Site -Credential $Credential -List $List -Web $Web -Name $Name
            
            if (-not $InputObject) {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and List pipe in results from Get-SPRListFolder"
                return
            }
        }
        try {
            foreach ($folder in $InputObject) {
                if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $folder.Context.Url -Action "Removing folder $($folder.Name)")) {
                    $folder.Context.Load($folder)
                    $folder.DeleteObject()
                    $folder.Context.ExecuteQuery()
                    [pscustomobject]@{
                        Site = $folder.Context
                        Folder = $folder.Name
                        ServerRelativeUrl = $folder.ServerRelativeUrl
                        Status = "Deleted"
                    }
                }
            }
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
        }
    }
}