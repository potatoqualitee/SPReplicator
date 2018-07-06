Function Get-SPRListData {
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
  
.PARAMETER Credential
    Provide alternative credentials to the web service. Otherwise, it will use default credentials. 
 
.PARAMETER IntputObject
    Allows piping from Get-SPRList 
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
 
.EXAMPLE
    Get-SPRListData -Uri intranet.ad.local -ListName 'My List'

    Gets data from My List on intranet.ad.local. Figures out the wsdl address automatically.
    
.EXAMPLE
    Get-SPRList -ListName 'My List' -Uri intranet.ad.local | Get-SPRListData

     Gets data from My List on intranet.ad.local.
    
.EXAMPLE
    Get-SPRListData -Uri intranet.ad.local -ListName 'My List' -Credential (Get-Credential ad\user)

    Gets data from My List and logs into the webapp as ad\user.
#>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "SharePoint lists.asmx?wsdl location")]
        [string]$Uri,
        [Parameter(HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [int]$RowLimit = 0,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Uri -and $ListName) {
                $InputObject = Get-SPRList -Uri $Uri -Credential $Credential -ListName $ListName
            }
            else {
                Stop-PSFFunction -Message "You must specify Uri and ListName or pipe in the results of Get-SPRList"
                return
            }
        }
        
        foreach ($list in $InputObject) {
            try {
                # Get the list (usually $list)
                $service = $list.Service
                $listname = $list.ListName
                
                $listdata = ($service.GetListItems($listName, $null, $query, $viewFields, $RowLimit, $queryOptions, $null)).data.row
                
                if ($listdata.Count -gt 0) {
                    # Get name attribute values (guids) for list and view
                    $ndlistview = $service.GetListAndView($listname, $null)
                    $listidname = $ndlistview.ChildNodes.Item(0).Name
                    $viewidname = $ndlistview.ChildNodes.Item(1).Name
                    
                    
                    # Note that an empty viewname parameter causes the method to use the default view
                    $batchelement = $list.BatchElement
                    $batchelement.SetAttribute("onerror", "continue")
                    $batchelement.SetAttribute("listversion", "1")
                    $batchelement.SetAttribute("viewname", $viewidname)
                    
                    $listdata | Add-Member -MemberType NoteProperty -Name Service -Value $service
                    $listdata | Add-Member -MemberType NoteProperty -Name ListName -Value $ListName
                    $listdata | Add-Member -MemberType NoteProperty -Name BatchElement -Value $batchelement -Passthru
                }
            }
            catch {
                Stop-PSFFunction -Message "Failure" -ErrorRecord $_
            }
        }
    }
}