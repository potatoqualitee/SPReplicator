Function New-SPRLogList {
<#
.SYNOPSIS
    Creates a new SharePoint list for SPRelicate Logs.

.DESCRIPTION
    Creates a new SharePoint list for SPRelicate Logs.

.PARAMETER Title
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER Web
    The human readable web name. So 'My Web' as opposed to 'MyWeb', unless you named it MyWeb.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER Description
    The description for the list.

.PARAMETER InputObject
    Allows piping from Connect-SPRSite

.PARAMETER WhatIf
    If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

.PARAMETER Confirm
    If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    New-SPRLogList -Site intranet.ad.local -List List1

    Creates a list called List1 on intranet.ad.local. Use Add-SPRColumn to add more columns.

.EXAMPLE
    $null = Connect-Site -Site intranet.ad.local
    New-SPRLogList -List 'My Announcements' -Template Announcements

    Creates a resuable connection to intranet.ad.local then uses that to create a new list called
    My Announcements using the Announcements. Use Get-SPRListTemplate to find out all templates
    or just tab through the options.

.EXAMPLE
    New-SPRLogList -Site intranet.ad.local -List 'My List' -Credential ad\user -OnQuickLaunch

    Creates a list called List1 on intranet.ad.local and logs into the webapp as ad\user.

    Adds list to Quick Launch
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [Alias("List")]
        [string]$Title = "SPReplicator",
        [Parameter(Position = 1, HelpMessage = "Human-readble SharePoint web name")]
        [string[]]$Web,
        [Parameter(Position = 2, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [string]$Description = "Table to log results from imports, exports and clears",
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $null = Connect-SPRSite -Site $Site -Credential $Credential
                $InputObject = $script:spweb
            }
            
            if ($Web) {
                $InputObject = Get-SPRWeb -Web $Web -Credential $Credential
            }
            elseif ($script:spweb) {
                $InputObject = $script:spweb
            }
            
            if (-not $InputObject) {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site, Web or run Connect-SPRSite"
                return
            }
        }
        
        foreach ($server in $InputObject.Context) {
            if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $script:spsite.Url -Action "Adding List $Title")) {
                try {
                    $loglist = New-SPRList -Title $Title -Description $Description -Web $Web
                    $null = $loglist | Add-SPRColumn -ColumnName FinishTime -Type DateTime -Description "Time of action"
                    $null = $loglist | Add-SPRColumn -ColumnName ItemCount -Type Integer -Description "Count of all items"
                    $null = $loglist | Add-SPRColumn -ColumnName Result -Description "Success or Failure"
                    $null = $loglist | Add-SPRColumn -ColumnName Type -Description "Import, Export or Clear"
                    $null = $loglist | Add-SPRColumn -ColumnName Duration -Type Note -Description "The duration of the task"
                    $null = $loglist | Add-SPRColumn -ColumnName RunAs -Type Note -Description "The executing user"
                    $null = $loglist | Add-SPRColumn -ColumnName Message -Type Note -Description "Failure messages"
                    $null = $loglist | Add-SPRColumn -ColumnName URL -Xml "<Field Type='URL' Name='URL' StaticName='URL' DisplayName='URL' Format='Hyperlink'/>"
                    $view = $loglist | Get-SPRListView
                    $view.ViewQuery = '<OrderBy><FieldRef Name="ID" Ascending="FALSE" /></OrderBy>'
                    $view.Update()
                    $server.ExecuteQuery()
                    Get-SPRList -List $Title -Web $Web
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                    return
                }
            }
        }
    }
}