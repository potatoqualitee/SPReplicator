$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

if ($PSVersionTable.PSEdition -eq "Core") {
    Stop-PSFFunction -Message "SharePoint Online not supported in Core :("
    return
}

Describe "$CommandName Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        $script:startingconfig = Get-SPRConfig
        $null = Set-SPRConfig -Name location -Value Online
        $list = Get-SPRList -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist -WarningAction SilentlyContinue 3> $null
        $null = $list | Remove-SPRList -Confirm:$false -WarningAction SilentlyContinue 3> $null
        # all commands set $global:spsite, remove this variable to start from scratch
        $global:spsite = $null
    }
    AfterAll {
        $list = Get-SPRList -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist -WarningAction SilentlyContinue 3> $null
        $null = $list | Remove-SPRList -Confirm:$false -WarningAction SilentlyContinue 3> $null
        $oldvalue = $script:startingconfig | Where-Object Name -eq location
        $results = Set-SPRConfig -Name location -Value $oldvalue.Value
    }
    
    Context "Connect-SPRSite" {
        It "Connects to a site" {
            $results = Connect-SPRSite -Site $script:onlinesite -Credential $script:onlinecred
            $results.Url | Should -Be $script:onlinesite
            $results.RequestTimeout | Should -Be 180000
        }
    }
    
    Context "Get-SPRConnectedSite" {
        It "Gets connected site information" {
            $results = Get-SPRConnectedSite
            $results.Url | Should -Be $script:onlinesite
            $results.RequestTimeout | Should -Be 180000
        }
    }
    Context "Get-SPRListTemplate" {
        It "Gets all template info" {
            $results = Get-SPRListTemplate
            $results.Count | Should -BeGreaterThan 50
            $results.Template | Should -Contain 'NoListTemplate'
        }
        It "Gets specific template info by id" {
            $results = Get-SPRListTemplate -Id 100
            $results.Template.Count | Should -Be 1
            $results.Id | Should -Be 100
            $results.Template | Should -Be 'GenericList'
        }
        It "Gets specific template info by name" {
            $results = Get-SPRListTemplate -Name 'HelpLibrary'
            $results.Template.Count | Should -Be 1
            $results.Template | Should -Be 'HelpLibrary'
            $results.Id | Should -Be 151
        }
    }
    
    Context "New-SPRList" {
        It "Creates a new list named $script:mylist" {
            $results = New-SPRList -ListName $script:mylist -Description "My List Description"
            $results.Title | Should -Be $script:mylist
            $results.GetType().Name | Should -Be 'List'
            $results.Description | Should -Be "My List Description"
        }
        It "Does not create a duplicate list named $script:mylist" {
            $results = New-SPRList -ListName $script:mylist -WarningAction SilentlyContinue 3>$null
            $results | Should -Be $null
        }
        #TODO - attempt to create a duplicate list
    }
    
    Context "Get-SPRList" {
        $global:spsite = $null
        It "Gets a list named $script:mylist with a basetype GenericList" {
            $results = Get-SPRList -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist
            $results.Title | Should -Be $script:mylist
            $results.BaseType | Should -Be 'GenericList'
        }
        It "Gets a list named $script:mylist and doesn't require a Site since Connect-SPRSite was used" {
            $results = Get-SPRList -ListName $script:mylist
            $results.Title | Should -Be $script:mylist
        }
    }
    
    Context "Add-SPRColumn" {
        It "Adds a column named TestColumn" {
            $results = Add-SPRColumn -ListName $script:mylist -ColumnName TestColumn -Description "One column"
            $results.ListName | Should -Be $script:mylist
            $results.Name | Should -Be TestColumn
            $results.DisplayName | Should -Be TestColumn
            $results.Description | Should -Be "One column"
        }
        It "Supports piping" {
            $results = Get-SPRList -ListName $script:mylist | Add-SPRColumn -ColumnName Scoopty -DisplayName PipedColumnSample
            $results.ListName | Should -Be $script:mylist
            $results.Name | Should -Be Scoopty
            $results.DisplayName | Should -Be PipedColumnSample
            $results.Description.Length | Should -Be 0
        }
        It "Supports xml" {
            $xml = "<Field Type='URL' Name='EmployeePicture' StaticName='EmployeePicture'  DisplayName='Employee Picture' Format='Image'/>"
            $results = Get-SPRList -ListName $script:mylist | Add-SPRColumn -Xml $xml
            $results.DisplayName | Should -Be 'Employee Picture'
            $results.Type | Should -Be 'Hyperlink or Picture'
            $results.ListName | Should -Be $script:mylist
        }
    }
    
    Context "Get-SPRColumnDetail" {
        It "Gets a list named $script:mylist with a basetype GenericList" {
            $results = Get-SPRColumnDetail -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist
            $results.Name.Count | Should -BeGreaterThan 10
            $results.Name | Should -Contain 'TestColumn'
            $results.Name | Should -Contain 'Scoopty'
            $results.DisplayName | Should -Contain 'PipedColumnSample'
        }
        It "Gets a list named $script:mylist and doesn't require a Site since Connect-SPRSite was used" {
            $results = Get-SPRColumnDetail -ListName $script:mylist
            $results.Name.Count | Should -BeGreaterThan 10
        }
    }
    
    Context "Add-SPRListItem" {
        It "Adds generic objects to list" {
            $object = @()
            $object += [pscustomobject]@{ Title = 'Hello'; TestColumn = 'Sample Data'; }
            $object += [pscustomobject]@{ Title = 'Hello2'; TestColumn = 'Sample Data2'; }
            $object += [pscustomobject]@{ Title = 'Hello3'; TestColumn = 'Sample Data3'; }
            $results = Add-SPRListItem -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist -InputObject $object
            $results.Title | Should -Be 'Hello', 'Hello2', 'Hello3'
            $results.TestColumn | Should -Be 'Sample Data', 'Sample Data2', 'Sample Data3'
        }
        
        It "Adds datatable results to list and doesn't require Site since we used connect earlier" {
            if ($PSVersionTable.PSEdition -ne "Core" -and (Get-Command Invoke-DbaSqlQuery -ErrorAction SilentlyContinue)) {
                $dt = Invoke-DbaSqlQuery -SqlInstance sql2017 -Query "Select Title = 'Hello SQL', TestColumn = 'Sample SQL Data'"
            }
            else {
                $dt = New-Object System.Data.Datatable
                [void]$dt.Columns.Add("Title")
                [void]$dt.Columns.Add("TestColumn")
                [void]$dt.Rows.Add("Hello SQL", "Sample SQL Data")
            }
            $results = $dt | Add-SPRListItem -ListName $script:mylist
            $results.Title | Should -Be 'Hello SQL'
            $results.TestColumn | Should -Be 'Sample SQL Data'
        }
        
        It "Autocreates new list" {
            $newlistname = 'Sample test create new list'
            $object = @()
            $object += [pscustomobject]@{ Title = 'Hello'; TestColumn = 'Sample Data'; }
            $object += [pscustomobject]@{ Title = 'Hello2'; TestColumn = 'Sample Data2'; }
            $object += [pscustomobject]@{ Title = 'Hello3'; TestColumn = 'Sample Data3'; }
            $results = $object | Add-SPRListItem -Site $script:onlinesite -Credential $script:onlinecred -ListName $newlistname -AutoCreateList
            $results.Title | Should -Be 'Hello', 'Hello2', 'Hello3'
            $results.TestColumn | Should -Be 'Sample Data', 'Sample Data2', 'Sample Data3'
            
            $results = Get-SPRList -Site $script:onlinesite -Credential $script:onlinecred -ListName $newlistname
            $results | Should -Not -Be $null
            $results | Remove-SPRList -Confirm:$false
        }
    }
    
    Context "Get-SPRListData" {
        It "Gets data from $script:mylist" {
            $results = Get-SPRListData -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist
            $results.Title.Count | Should -BeGreaterThan 1
            $results.Title | Should -Contain 'Hello SQL'
            $results.TestColumn | Should -Contain 'Sample SQL Data'
            $script:id = $results[0].Id
        }
        
        It "Gets one data based on ID ($script:id), doesn't require Site" {
            $results = Get-SPRListData -ListName $script:mylist -Id $script:id
            $results.Title.Count | Should -Be 1
            $results.Id | Should -Be $script:id
        }
    }
    
    Context "Export-SPRListData" {
        It "Gets data from $script:mylist" {
            if ((Test-Path $script:filename)) {
                Remove-Item $script:filename
            }
            $result = Export-SPRListData -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist -Path $script:filename
            $result.FullName | Should -Be $script:filename
            $string = Select-String -Pattern 'TestColumn' -Path $result
            $string.Count | Should -BeGreaterThan 3
        }
    }
    
    Context "Import-SPRListData" {
        It "imports data from $script:filename" {
            $count = (Get-SPRListData -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist).Title.Count
            $results = Import-SPRListData -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist -Path $script:filename
            $results.Title | Should -Contain 'Hello SQL'
            (Get-SPRListData -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist).Title.Count | Should -BeGreaterThan $count
        }
    }
    
    Context "Add-SPRListItem" {
        It "Imports data from $script:filename" {
            $count = (Get-SPRListData -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist).Title.Count
            $results = Import-CliXml -Path $script:filename | Add-SPRListItem -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist
            (Get-SPRListData -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist).Title.Count | Should -BeGreaterThan $count
            $results.Title | Should -Contain 'Hello SQL'
        }
    }
    
    Context "Update-SPRListItem" {
        It -Skip "Updates data from $script:filename" {
            # Replace a value to update
            (Get-Content $script:filename).replace('Hello SQL', 'ScooptyScoop') | Set-Content $script:filename
            (Get-Content $script:filename).replace('Sample SQL Data', 'ScooptyData') | Set-Content $script:filename
            $updates = Import-CliXml -Path $script:filename
            $results = Get-SPRListData -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist | Update-SPRListItem -UpdateObject $updates -Confirm:$false
            $results.Title.Count | Should -Be 1
            $results.Title | Should -Be 'ScooptyScoop'
            $results.TestColumn | Should -Be 'ScooptyData'
        }
        It "Doesn't update the other rows" {
            $results = Get-SPRListData -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist
            $results.Title | Should -Contain 'ScooptyScoop'
            $results.Title | Should -Contain 'Hello'
            $results.Title | Should -Contain 'Hello2'
            $results.Title | Should -Contain 'Hello3'
        }
    }
    
    Context "Select-SPRObject" {
        It "Gets data from $script:mylist and excludes other data" {
            $results = Get-SPRListData -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist | Select-SPRObject -Property 'Title as Test1234'
            $results | Get-Member -Name Title | Should -Be $null
            $results | Get-Member -Name Test1234 | Should -Not -Be $null
            $results.Test1234 | Should -Contain 'ScooptyScoop'
        }
    }
    
    Context "Remove-SPRListData" {
        It "Removes specific data from $script:mylist" {
            $row = Get-SPRListData -ListName $script:mylist -Id $script:id
            $row | Should -Not -Be $null
            $results = Get-SPRListData -ListName $script:mylist | Where-Object Id -in $script:id | Remove-SPRListData -Confirm:$false
            $results.Site | Should -Not -Be $null
            $row = Get-SPRListData -ListName $script:mylist -Id $script:id  3> $null
            $row | Should -Be $null
        }
    }
    
    Context "Clear-SPRListData" {
        It -Skip "Removes data from $script:mylist" {
            $results = Clear-SPRListData -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist -Confirm:$false
            Get-SPRListData -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist | Should -Be $null
        }
    }
    
    Context "Remove-SPRList" {
        It "Removes $script:mylist" {
            $results = Get-SPRList -Site $script:onlinesite -Credential $script:onlinecred -ListName 'My List', $script:mylist | Remove-SPRList -Confirm:$false
            Get-SPRList -Site $script:onlinesite -Credential $script:onlinecred -ListName $script:mylist | Should -Be $null
            
        }
    }
    Context "Get-SPRLog" {
        It "Gets some logs" {
            $results = Get-SPRLog
            $results.ModuleName | Select-Object -First 1 | Should -Be 'SPReplicator'
            $results | Measure-Object | Select-Object -ExpandProperty Count | Should -BeGreaterThan 20
        }
    }
    Context "Get-SPRConfig" {
        It "Gets some configs" {
            $results = Get-SPRConfig
            $results.location | Should -Not -Be $null
        }
    }
    Context "Set-SPRConfig" {
        It "Sets some configs" {
            $script:currentconfig = Get-SPRConfig
            $results = Set-SPRConfig -Name location -Value Test
            $results.Value | Should -Be 'Test'
            $results = Get-SPRConfig
            ($results | Where-Object Name -eq location).Value | Should -Be 'Test'
        }
    }
}