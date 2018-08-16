Function New-SPRListTemplate {
<#
.SYNOPSIS
    Creates a new list template. This doesn't seem to work yet, actually, though you may have different results.

.DESCRIPTION
    Creates a new list template.This doesn't seem to work yet, actually, though you may have different results.

.PARAMETER Name
    Name of the template. If no name is provided, the list title will be used.
    
.PARAMETER FileName
    The filename. If no filename is provided, the list title + ".stp" will be used.
 
.PARAMETER Description
    The description of the template.
    
.PARAMETER IncludeData
    Save the template with data.
   
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
    Get-SPRList -ListName 'My List' | New-SPRListTemplate

    Returns all templates and their corresponding numbers

#>
    [CmdletBinding()]
    param (
        [string]$Name,
        [string]$FileName,
        [string]$Description,
        [switch]$IncludeData,
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
                
                $title = $thislist.Title
                if (-not $Name) {
                    $Name = $title
                }
                if (-not $FileName) {
                    $FileName = "$title.stp"
                }
                if (Get-SPRListTemplate -Name $Name) {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Template $Name already exists" -Continue
                }
                
                Write-PSFMessage -Level Verbose -Message "Adding $Name as $FileName"
                # this command does not work yet, unsure whats up
                # i get Exception calling "ExecuteQuery" with "0" argument(s): "Method "SaveAsTemplate" does not exist."
                # savebinarydirect
                # https://docs.microsoft.com/en-us/previous-versions/office/developer/sharepoint-2010/ms466023(v=office.14)
                
                #ctl00$PlaceHolderMain$ctl00$ctl01$TxtSaveAsTemplateName: THIS IS FILENAME
                #ctl00$PlaceHolderMain$ctl01$ctl01$TxtSaveAsTemplateTitle: THIS IS NAME
                #ctl00$PlaceHolderMain$ctl01$ctl02$TxtSaveAsTemplateDescription: DECRIPTION
                #ctl00$PlaceHolderMain$ctl03$CbSaveData: on
                #https://blog.vossers.com/2012/02/04/use-jquery-to-submit-forms-on-remote-sharepoint-admin-pages/
                $thislist.SaveAsTemplate($FileName, $Name, $Description, $IncludeData)
                $thislist.Update()
                $thislist.Context.ExecuteQuery()
            }
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
        }
    }
}