Function Export-SPRListData {
<#
.SYNOPSIS
    Exports all items to a file from a SharePoint list using a Web service proxy object.
    
.DESCRIPTION
     Exports all items to a file from a SharePoint list using a Web service proxy object.
    
.PARAMETER Uri
    The address to the web application. You can also pass a hostname and it'll figure it out.

.PARAMETER ListName
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.
   
.PARAMETER Credential
    Provide alternative credentials to the web service. Otherwise, it will use default credentials. 
 
.PARAMETER IntputObject
    Allows piping from Get-SPRList or Get-SPRListData
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Export-SPRListData -Uri intranet.ad.local -ListName 'My List' -Path C:\temp\mylist.xml

    Exports all items from My List on intranet.ad.local to C:\temp\mylist.xml
    
.EXAMPLE
    Get-SPRListData -ListName 'My List' -Uri intranet.ad.local |Export-SPRListData -Path C:\temp\mylist.xml

    Exports all items from My List on intranet.ad.local to C:\temp\mylist.xml
#>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "SharePoint lists.asmx?wsdl location")]
        [string]$Uri,
        [Parameter(HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [Parameter(Mandatory)]
        [string]$Path,
        [switch]$EnableException
    )
    begin {
        $xml = $collection = @()
    }
    process {
        if (-not $InputObject) {
            if ($Uri -and $ListName) {
                $InputObject = Get-SPRListData -Uri $Uri -Credential $Credential -ListName $ListName
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Uri and ListName or pipe in the results of Get-SPRService"
                return
            }
        }
        
        if ($InputObject) {
            if (-not $InputObject[0].ows_ID) {
                $InputObject = $InputObject | Get-SPRListData
            }
        }
        $collection += $InputObject
    }
    end {
        $columns = Get-SPRColumnDetail -Uri $collection[0].Service.Uri -ListName $collection[0].ListName |
        Where-Object { -not $psitem.Hidden -and -not $PSItem.ReadOnly -and $PSItem.Type -ne 'Computed' }
        
        $data = $collection | Select-Object -Property $columns.OwsName
        Export-Clixml -InputObject $data -Path $Path
        Get-ChildItem -Path $Path
    }
}