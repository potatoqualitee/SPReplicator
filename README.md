# SPReplicator

<img align="left" src=https://user-images.githubusercontent.com/8278033/42554599-39b769a6-8481-11e8-8b6a-379f4a3e54e6.png alt="SPReplicator logo">SPReplicator is a PowerShell module that helps replicate SharePoint list data. 

This module uses the SharePoint Client Side Object Model (CSOM) and all required libraries and dlls are included. Installing the SharePoint binaries is **not required** for the replication to work 👍 Thank you Microsoft for the redistributable nuget.

SPReplicator works with both on-prem and SharePoint Online and is currently in beta. It also works on .NET Core, so it's cross-platform, and supports Windows, macOS and Linux.

Please report any issues to clemaire@gmail.com.

## Installer
SPReplicator is now in the PowerShell Gallery. Run the following from an administrative prompt to install SPReplicator for all users:
```powershell
Install-Module SPReplicator
```

Or if you don't have administrative access or want to save it locally (just for yourself), run:
```powershell
Install-Module SPReplicator -Scope CurrentUser
```

If you're scheduling tasks via Task Schedule or SQL Server agent, installing the module with administrative privileges is best because it will ensure all users have access via Program Files.

## Command Reference

For more details about commands, visit the [wiki](https://github.com/potatoqualitee/SPReplicator/wiki/Command-Reference) or use Get-Help.

## Usage scenarios

This module can be used for replicating data in a number of ways.

* Between air gapped (offline) servers that do not have direct access to each other
* Directly from SharePoint site collection to SharePoint site collection
* From SQL Server to SharePoint
* From SharePoint to SQL Server
* From CSV to SharePoint
* From SharePoint to CSV
* From On-prem to SharePoint Online and back

## Usage examples

SPReplicator has a number of commands that help you manage SharePoint lists. You can view, delete, and add records easily and there's even a command that makes it easy to see internal column names and datatypes.

#### Export from SharePoint List

```powershell
Export-SPRListItem -Site https://intranet -List Employees -Path \\nas\replicationdata\Employees.csv
```

#### Establish a session to the SharePoint site

You can specify `-Site` and `-Credential` with every command. Or you can establish a connection and not worry about specifying the Site or Credentials in subsequent command executions.

There is no need to assign the output to a variable, as it creates a reusable global variable `$global:spsite`.

```powershell
# using your own account credentials
Connect-SPRSite -Site https://intranet

# specifying other credentials
Connect-SPRSite -Site https://intranet -Credential ad\otheruser

# using your own account credentials and SP Online
Connect-SPRSite -Site https://corp.sharepoint.com -Credential otheruser@corp.onmicrosoft.com

# using MFA
Connect-SPRSite -Site https://corp.sharepoint.com -AuthenticationMode WebLogin

# using app login
Connect-SPRSite -Site https://corp.sharepoint.com -AuthenticationMode AppOnly -Credential 1e36c5cc-5281-4235-a84f-c94dc2de8800

```

#### Import to SharePoint List
Now that we've established a connection via `Connect-SPRSite`, we no longer need to specify the Site.

We can import data two ways, using `Import-SPRListItem` or `Add-SPRListItem`

```powershell
# Import from CSV
Import-SPRListItem -List Employees -Path \\nas\replicationdata\Employees.csv

# Import from SQL Server
Invoke-DbaQuery -SqlInstance sql2017 -Query "Select fname, lname where id > 100" | Add-SPRListItem -List emps

# Import any PowerShell object, really. So long as it has the properly named columns.
Get-ADUser -Filter * | Select SamAccountName, whateverelse | Add-SPRListItem -List ADList

# Didn't have time to create a good SharePoint list? Use -AutoCreateList
Get-ADUser -Filter * | Add-SPRListItem -List ADList -AutoCreateList

```
#### Find out more

This was just a subset of command examples. For more command examples, visit the [wiki](https://github.com/potatoqualitee/SPReplicator/wiki/Command-Reference) or use Get-Help.

## Selected screenshots

#### Connect to a site
![image](https://user-images.githubusercontent.com/8278033/42564673-1ceca0a4-849d-11e8-8f6b-22c1a0aad1e1.png)

#### Add a generic object to a list
![image](https://user-images.githubusercontent.com/8278033/42570287-227a3c4a-84af-11e8-9e5a-4dc6e9f2f4af.png)

#### Add SQL data to a list and auto create the list if it doesn't exist
![image](https://user-images.githubusercontent.com/8278033/42570505-d060d8be-84af-11e8-948d-f97888611346.png)

#### This is what it looks like!
![image](https://user-images.githubusercontent.com/8278033/42570634-3f2478fa-84b0-11e8-8ab7-3c996d29021d.png)

#### Get details about columns to help you format your input/output
![image](https://user-images.githubusercontent.com/8278033/42567935-19fcb8ac-84a7-11e8-9b48-0da67dd2ce0f.png)

#### Results of built-in logger (New-SPRLogList and `-LogToList`)

![image](https://user-images.githubusercontent.com/8278033/43561352-63b655cc-95b2-11e8-93e0-90926df74d47.png)

## Power BI
A Power BI Template is included in the bin directory. More coming soon.

![image](https://user-images.githubusercontent.com/8278033/43371234-568d7622-9329-11e8-9100-df03d7a442bc.png)

## Pester tested

This module comes with integration tests! If you'd like to see how I test the commands, check out [Integration.Tests.ps1](https://github.com/potatoqualitee/SPReplicator/blob/master/tests/Integration.Tests.ps1)

![image](https://user-images.githubusercontent.com/8278033/43365014-39eee66c-92c1-11e8-91bf-9b6bf8d1032a.png)

## Learn more

To find out more about any command, including additional examples, use `Get-Help`. 

```powershell
Get-Help Get-SPRColumnDetail -Detailed
```

<!--
$global:a = @()
foreach ($prop in $props.Name) {
    try {
        $server.Load($server.Web.$prop)
    }
    catch {
        $global:a += $prop
        continue
    }
}
-->
