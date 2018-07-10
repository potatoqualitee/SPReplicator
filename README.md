# SPReplicator
PowerShell module to replicate SharePoint list data

## Add-SPRColumn
Adds a column to a SharePoint list.

## Add-SPRListItem
Adds items to a SharePoint list.

## Clear-SPRListData
Deletes all items from a SharePoint list.

## Connect-SPRSite
Creates a reusable SharePoint Client Context object that lets you use and manage the site collection in Windows PowerShell.

## Disconnect-SPRSite
Disconnects a SharePoint Client Context object that lets you use and manage the site collection in Windows PowerShell.

## Export-SPRListData
Exports all items from a SharePoint list to a file.

## Get-SPRColumnDetail
Returns information (Name, DisplayName, Data type) about columns in a SharePoint list.

## Get-SPRList
Returns a SharePoint list object.

## Get-SPRListData
Returns data from a SharePoint list.

## Get-SPRListTemplate
Get list of SharePoint templates.

## Import-SPRListData
Imports all items from a file into a SharePoint list.

## New-SPRList
Creates a new SharePoint list.

## Remove-SPRList
 Deletes lists from a SharePoint site collection.

## Remove-SPRListData
Deletes items from a SharePoint list.

<!---
Connect-SPRSite -Uri sharepoint2016
Get-SPRList -Uri sharepoint2016 -ListName 'My List'
Get-SPRListData -Uri sharepoint2016 -ListName 'My List'
Get-SPRColumnDetail -Uri sharepoint2016 -ListName 'My List'

$object = @()
    $object += [pscustomobject]@{ Title = 'Hello'; TestColumn = 'Sample Data'; }
    $object += [pscustomobject]@{ Title = 'Hello2'; TestColumn = 'Sample Data2'; }
    $object += [pscustomobject]@{ Title = 'Hello3'; TestColumn = 'Sample Data3'; }
Add-SPRListItem -Uri sharepoint2016 -ListName 'My List' -InputObject $object

Invoke-DbaSqlQuery -SqlInstance sql2017 -Query "Select Title = 'Hello SQL', TestColumn = 'Sample SQL Data'" | 
Add-SPRListItem -Uri sharepoint2016 -ListName 'My List' 

$item = Invoke-DbaSqlQuery -SqlInstance sql2017 -Query "Select Title = 'Hello SQL', TestColumn = 'Sample SQL Data'" | 
Add-SPRListItem -Uri sharepoint2016 -ListName 'My List' 

Get-SPRListData -Uri sharepoint2016 -ListName 'My List' -Id $item.Id

rm C:\temp\mylist.xml
Export-SPRListData -Uri sharepoint2016 -ListName 'My List' -Path C:\temp\mylist.xml

Import-CliXml -Path C:\temp\mylist.xml | Add-SPRListItem -Uri sharepoint2016 -ListName 'My List'
Import-SPRListData -Uri sharepoint2016  -ListName 'My List' -Path C:\temp\mylist.xml

Clear-SPRListData -Uri sharepoint2016 -ListName 'My List' -Confirm:$false

New-SPRList -ListName 'My List'
New-SPRList -ListName 'My List2'
Add-SPRColumn -ListName 'My List'

Get-SPRList -Uri sharepoint2016 -ListName 'My List2' | Remove-SPRList -Confirm:$false
Get-SPRListData -ListName 'My List' | Where-Object Id -in $item.Id | Remove-SPRListData

$server = Connect-SPRSite -Uri sharepoint2016
$lists = $server.Web.Lists
$server.Load($lists)
$server.ExecuteQuery()
foreach ($list in $server.Web.Lists) {
    $List = $server.web.Lists.GetByTitle($List.Title)
    $server.Load($List)
    $List.DeleteObject()
    $server.ExecuteQuery()
}


-->