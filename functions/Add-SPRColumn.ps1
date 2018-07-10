Function Add-SPRColumn {
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
    Allows piping from Add-SPRColumn 
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
 
.EXAMPLE
    Add-SPRColumn -Uri intranet.ad.local -ListName 'My List'

    Gets data from My List on intranet.ad.local. Figures out the wsdl address automatically.
    
.EXAMPLE
    Add-SPRColumn -ListName 'My List' -Uri intranet.ad.local | Add-SPRColumn

     Gets data from My List on intranet.ad.local.
    
.EXAMPLE
    Add-SPRColumn -Uri intranet.ad.local -ListName 'My List' -Credential (Get-Credential ad\user)

    Gets data from My List and logs into the webapp as ad\user.
    
.EXAMPLE    
    Add-SPRColumn -Uri sharepoint2016 -ListName 'My List' -Id 100, 101, 105
    
    Gets list items with ID 100, 101 and 105
#>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Uri,
        [PSCredential]$Credential,
        [Parameter(HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [Parameter(Mandatory)]
        [string]$ColumnName,
        [string]$DisplayName = $ColumnName,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Uri) {
                $InputObject = Get-SprList -Uri $Uri -Credential $Credential -ListName $ListName
            }
            elseif ($global:server) {
                $InputObject = $global:server | Get-SprList -ListName $ListName
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Uri and ListName pipe in results from Get-SPRList"
                return
            }
        }
        
        foreach ($list in $InputObject) {
            try {
                $server = $list.Context
                $server.Load($list.Fields)
                $server.ExecuteQuery()
                $xml = "<Field Type='Text' Name='$ColumnName' StaticName='$ColumnName' DisplayName='$DisplayName' />"
                $field = $list.Fields.AddFieldAsXml($xml, $true, "AddFieldInternalNameHint") # $true = addToDefaultView, "AddFieldInternalNameHint"
                $list.Update()
                $server.Load($list)
                $server.ExecuteQuery()
                $list.Update()
                $server.ExecuteQuery()
                
                Get-SPRList -Uri $server.Url -ListName $ListName | Select-DefaultView -Property Title, RootFolder, DefaultViewUrl, Created
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                return
            }
        }
    }
}

<#

#Retrieve site columns (fields)
                $sitecolumns = $server.Web.AvailableFields
                $server.Load($sitecolumns)
                $server.ExecuteQuery()
                
                #Grab city and company fields
                $City = $server.Web.AvailableFields | Where-Object { $_.Title -eq "City" }
                $Company = $server.Web.AvailableFields | Where-Object { $_.Title -eq "Company" }
                $server.Load($City)
                $server.Load($Company)
                $server.ExecuteQuery()
                
                #Add fields to the list
                $List.Fields.Add($City)
                $List.Fields.Add($Company)
                $List.Update()
                $server.ExecuteQuery()
                
                #Add fields to the default view
                $DefaultView = $List.DefaultView
                $DefaultView.ViewFields.Add("City")
                $DefaultView.ViewFields.Add("Company")
                $DefaultView.Update()
                $server.ExecuteQuery()
                
                #Adds an item to the list
                $ListItemInfo = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
                $Item = $List.AddItem($ListItemInfo)
                $Item["Title"] = "New Item"
                $Item["Company"] = "Contoso"
                $Item["WorkCity"] = "London"
                $Item.Update()
                $server.ExecuteQuery()

# Create Single List Item
$ListItemCreationInformation = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
$NewListItem = $List.AddItem($ListItemCreationInformation)
$NewListItem["Title"] = 'xxx'
$NewListItem.Update()
$ClientContext.ExecuteQuery()

# Loop Create List Item
for ($i=11; $i -le 20; $i++)
{
  $ListItemCreationInformation = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
  $NewListItem = $List.AddItem($ListItemCreationInformation)
  $NewListItem["Title"] = "abc$($i)"
  $NewListItem.Update()
  $ClientContext.ExecuteQuery()
}
#>