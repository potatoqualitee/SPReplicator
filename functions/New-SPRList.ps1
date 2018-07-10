Function New-SPRList {
<#
.SYNOPSIS
    Creates a new SharePoint list.

.DESCRIPTION
    Creates a new SharePoint list.

.PARAMETER Uri
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Uri or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER ListName
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
    New-SPRList -Uri intranet.ad.local -ListName List1

    Creates a list called List1 on intranet.ad.local. Use Add-SPRColumn to add more columns.

.EXAMPLE
    $null = Connect-Uri -Uri intranet.ad.local
    New-SPRList -ListName 'My Announcements' -Template Announcements

    Creates a resuable connection to intranet.ad.local then uses that to create a new list called
    My Announcements using the Announcements. Use Get-SPRListTemplate to find out all templates
    or just tab through the options.

.EXAMPLE
    New-SPRList -Uri intranet.ad.local -ListName 'My List' -Credential (Get-Credential ad\user) -OnQuickLaunch

    Creates a list called List1 on intranet.ad.local and logs into the webapp as ad\user.

    Adds list to Quick Launch
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Uri,
        [PSCredential]$Credential,
        [Parameter(HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [string]$Description,
        [string]$Template = "GenericList",
        [switch]$OnQuickLaunch,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Uri) {
                $InputObject = Connect-SPRSite -Uri $Uri -Credential $Credential
            }
            elseif ($global:spsite) {
                $InputObject = $global:spsite
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Uri or run Connect-SPRSite"
                return
            }
        }

        foreach ($server in $InputObject) {
            try {
                Write-PSFMessage -Level Verbose -Message "Loading up all lists"
                $lists = $server.Web.Lists
                $server.Load($lists)
                $server.ExecuteQuery()

                Write-PSFMessage -Level Verbose -Message "Creating list"
                $listinfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
                $listinfo.Title = $ListName
                $templateid = (Get-SPRListTemplate -Name $Template).Id
                Write-PSFMessage -Level Verbose -Message "Associating templateid $templateid"
                $listinfo.TemplateType = $templateid
                if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $server.Url -Action "Adding list $ListName")) {
                    $List = $server.Web.Lists.Add($listinfo)
                    $List.Description = $Description
                    $List.Update()
                    Write-PSFMessage -Level Verbose -Message "Executing query"
                    $server.ExecuteQuery()
                    $global:spsite | Get-SPRList -ListName $ListName | Select-DefaultView -Property Id, Title, Description, ItemCount, BaseType, Created
                }
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                return
            }
        }
    }
}