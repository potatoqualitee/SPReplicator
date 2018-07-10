Function New-SPRList {
<#
.SYNOPSIS
    Returns data from a SharePoint list using a Web service proxy object.
    
.DESCRIPTION
    Returns data from a SharePoint list using a Web service proxy object.
    
.PARAMETER Uri
    The address to the web application. You can also pass a hostname and it'll figure it out.

.PARAMETER ListName
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.
    
.PARAMETER RowLimit
    Limit the number of rows returned. The entire list is returned by default.
 
.PARAMETER Id
    Return only rows with specific IDs
 
.PARAMETER Credential
    Provide alternative credentials to the web service. Otherwise, it will use default credentials. 
 
.PARAMETER IntputObject
    Allows piping from New-SPRList 
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
 
.EXAMPLE
    New-SPRList -Uri intranet.ad.local -ListName 'My List'

    Gets data from My List on intranet.ad.local. Figures out the wsdl address automatically.
    
.EXAMPLE
    New-SPRList -ListName 'My List' -Uri intranet.ad.local | New-SPRList

     Gets data from My List on intranet.ad.local.
    
.EXAMPLE
    New-SPRList -Uri intranet.ad.local -ListName 'My List' -Credential (Get-Credential ad\user)

    Gets data from My List and logs into the webapp as ad\user.
    
.EXAMPLE    
    New-SPRList -Uri sharepoint2016 -ListName 'My List' -Id 100, 101, 105
    
    Gets list items with ID 100, 101 and 105
#>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Uri,
        [PSCredential]$Credential,
        [Parameter(HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [string]$Description,
        [string]$Template = "GenericList",
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$OnQuickLaunch,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Uri) {
                $InputObject = Connect-SPRSite -Uri $Uri -Credential $Credential
            }
            elseif ($global:server) {
                $InputObject = $global:server
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
                $List = $server.Web.Lists.Add($listinfo)
                $List.Description = $Description
                $List.Update()
                Write-PSFMessage -Level Verbose -Message "Executing query"
                $server.ExecuteQuery()
                
                $server | Get-SPRList -ListName $ListName | Select-DefaultView -Property Title, RootFolder, DefaultViewUrl, Created
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                return
            }
        }
    }
}