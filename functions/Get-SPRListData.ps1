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
 
.PARAMETER Id
    Return only rows with specific IDs
 
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
    
.EXAMPLE    
    Get-SPRListData -Uri sharepoint2016 -ListName 'My List' -Id 100, 101, 105
    
    Gets list items with ID 100, 101 and 105
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
        [int[]]$Id,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Uri -and $ListName) {
                $InputObject = Get-SPRList -Uri $Uri -Credential $Credential -ListName $ListName
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Uri and ListName or pipe in the results of Get-SPRList"
                return
            }
        }
        
        foreach ($list in $InputObject) {
            try {
                $service = $list.Service
                $listname = $list.ListName
                
                $xmlDoc = $list.XmlDoc
                $xmlquery = $list.XmlQuery
                $viewFields = $list.ViewFields
                $queryOptions = $list.QueryOptions
                $batchelement = $list.BatchElement
                
                if ($Id) {
                    $combotext = @()
                    foreach ($number in $id) {
                        $combotext += "<Value Type='Counter'>$number</Value>"
                    }
                    $combotext = $combotext -join ""
                    $xmlquery.InnerXml = "<Where><In><FieldRef Name='ID'/><Values>$combotext</Values></In></Where>"
                }
                
                # listName, viewName, XmlNode query, XmlNode viewFields, rowLimit, XmlNode queryOptions, string webID
                Write-PSFMessage -Level Verbose -Message "Performing GetListItems"
                $listdata = ($service.GetListItems($listName, $null, $xmlquery, $viewFields, $RowLimit, $queryOptions, $null)).data.row
                
                if ($listdata.ows_ID) {
                    Write-PSFMessage -Level Verbose -Message "Massaging results"
                    # Get name attribute values (guids) for list and view
                    $ndlistview = $service.GetListAndView($listname, $null)
                    $listidname = $ndlistview.ChildNodes.Item(0).Name
                    $viewidname = $ndlistview.ChildNodes.Item(1).Name
                    
                    
                    # Note that an empty viewname parameter causes the method to use the default view
                    $batchelement = $list.BatchElement
                    $batchelement.SetAttribute("onerror", "continue")
                    $batchelement.SetAttribute("listversion", "1")
                    $batchelement.SetAttribute("viewname", $viewidname)
                    
                    Write-PSFMessage -Level Verbose -Message "Adding extra fields"
                    $listdata | Add-Member -MemberType NoteProperty -Name Service -Value $service
                    $listdata | Add-Member -MemberType NoteProperty -Name ListName -Value $ListName
                    $listdata | Add-Member -MemberType NoteProperty -Name BatchElement -Value $batchelement
                    
                    Write-PSFMessage -Level Verbose -Message "Selecting data"
                    $listdata | Select-Object -ExcludeProperty OuterXml, InnerXml, HasAttributes, PreviousText, BaseURI, HasChildNodes, LastChild, FirstChild, ChildNodes, SchemaInfo, InnerText, NextSibling, PreviousSibling, Item, Name, LocalName, NamespaceURI, Prefix, NodeType, ParentNode, OwnerDocument, Attributes
                }
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
            }
        }
    }
}