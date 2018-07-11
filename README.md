# SPReplicator

<img align="left" src=https://user-images.githubusercontent.com/8278033/42554599-39b769a6-8481-11e8-8b6a-379f4a3e54e6.png alt="SPReplicator logo">SPReplicator is a PowerShell module that helps replicate SharePoint list data. This module uses the SharePoint Client Side Object Model (CSOM) and all required libraries and dlls are included. Installing the SharePoint binaries is **not required** for the replication to work 👍

SPReplicator is currently in beta. Please report any issues to clemaire@gmail.com.

## Installer
SPReplicator is now in the PowerShell Gallery. Run the following from an administrative prompt to install SPReplicator for all users:
```powershell
Install-Module dbatools
```

Or if you don't have administrative access or want to save it locally (just for yourself), run:
```powershell
Install-Module dbatools -Scope CurrentUser
```

If you're scheduling tasks via Task Schedule or SQL Server agent, installing the module with administrative privleges is best because it will ensure all users have access via Program Files.

## Usage scenarios

This module can be used for replicating data in a number of ways.

* Between air gapped (offline) servers that do not have direct access to each other
* Directly from SharePoint site collection to SharePoint site collection
* From SQL Server to SharePoint
* From CSV to SharePoint

## Usage examples

SPReplicator has a number of commands that help you manage SharePoint lists. You can view, delete, and add records easily and there's even a command that makes it easy to see internal column names and datatypes.

#### Export from SharePoint List

```powershell
Export-SPRListData -Site https://intranet -ListName Employees -Path \\nas\replicationdata\Employees.csv
```

### Establish a session to the SharePoint site

You can specify `-Site` and `-Credential` with every command. Or you can establish a connection and not worry about specifying the Site or Credentials in subsequent command executions.

```powershell
# using your own account credentials
Connect-SPRSite -Site https://intranet

# specifying other credentials
Connect-SPRSite -Site https://intranet -Credential (Get-Credential ad\otheruser)
```

#### Import to SharePoint List
Now that we've established a connection via `Connect-SPRSite`, we no longer need to specify the Site.

We can import data two ways, using `Import-SPRListData` or `Add-SPRListItem`
```powershell
# Import from CSV
Import-SPRListData -ListName Employees -Path \\nas\replicationdata\Employees.csv

# Import from SQL Server
Invoke-DbaSqlQuery -SqlInstance sql2017 -Query "Select fname, lname where id > 100" | Add-SPRListItem -ListName emps

# Import any PowerShell object, really. So long as it has the properly named columns.
Get-ADUser -Filter * | Select SamAccountName, whateverelse | Add-SPRListItem -ListName ADList

# Didn't have time to create a good SharePoint list? Use -AutoCreateList
Get-ADUser -Filter * | Add-SPRListItem -ListName ADList -AutoCreateList

```

The rest of the commands, you can see in screenshots.

## Command summaries

In the screenshots and examples below, I'll be connecting to my SharePoint 2016 server, aptly named `https://sharepoint2016`

## Add-SPRColumn
Adds a column to a SharePoint list.

![image](https://user-images.githubusercontent.com/8278033/42560633-c61f0a78-8492-11e8-9ac2-f3b772d8b8dc.png)

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

![image](https://user-images.githubusercontent.com/8278033/42560182-c8fd276c-8491-11e8-8c2e-2234b249439c.png)

![image](https://user-images.githubusercontent.com/8278033/42560506-826f8cee-8492-11e8-89a5-0b1eaac26a95.png)

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

https://user-images.githubusercontent.com/8278033/42554381-57ff0744-8480-11e8-97fe-64f666b953e8.png
-->
