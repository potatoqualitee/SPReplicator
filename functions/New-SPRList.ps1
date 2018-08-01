Function New-SPRList {
<#
.SYNOPSIS
    Creates a new SharePoint list.

.DESCRIPTION
    Creates a new SharePoint list.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER Title
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER Description
    The description for the list

.PARAMETER Template
    The SharePoint list template that is used to build the new list. By default, SharePoint "GenericList".

    This parameter auto-completes for your convenience.

.PARAMETER OnQuickLaunch
    Adds list to Quick Launch

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
    New-SPRList -Site intranet.ad.local -List List1

    Creates a list called List1 on intranet.ad.local. Use Add-SPRColumn to add more columns.

.EXAMPLE
    $null = Connect-Site -Site intranet.ad.local
    New-SPRList -List 'My Announcements' -Template Announcements

    Creates a resuable connection to intranet.ad.local then uses that to create a new list called
    My Announcements using the Announcements. Use Get-SPRListTemplate to find out all templates
    or just tab through the options.

.EXAMPLE
    New-SPRList -Site intranet.ad.local -List 'My List' -Credential ad\user -OnQuickLaunch

    Creates a list called List1 on intranet.ad.local and logs into the webapp as ad\user.

    Adds list to Quick Launch
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint list name")]
        [Alias("List")]
        [string]$Title,
        [Parameter(Position = 1, HelpMessage = "Human-readble SharePoint web name")]
        [string[]]$Web,
        [Parameter(Position = 2, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [string]$Description,
        [string]$Template = "Custom List",
        [switch]$OnQuickLaunch,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Connect-SPRSite -Site $Site -Credential $Credential
            }
            elseif ($script:spsite) {
                $InputObject = $script:spsite
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site or run Connect-SPRSite"
                return
            }
        }

        foreach ($server in $InputObject) {
            try {
                Write-PSFMessage -Level Verbose -Message "Loading up all lists"
                $lists = $server.Web.Lists
                $server.Load($lists)
                $server.ExecuteQuery()

                if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $server.Url -Action "Adding list $Title")) {
                    $listinfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
                    $listinfo.Title = $Title
                    $templateid = (Get-SPRListTemplate -Name $Template).Id
                    Write-PSFMessage -Level Verbose -Message "Associating templateid $templateid"
                    $listinfo.TemplateType = $templateid
                    $newlist = $server.Web.Lists.Add($listinfo)
                    $newlist.Description = $Description
                    $newlist.Update()
                    Write-PSFMessage -Level Debug -Message "Executing query"
                    $server.ExecuteQuery()
                    Get-SPRList -List $Title
                }
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                return
            }
        }
    }
}