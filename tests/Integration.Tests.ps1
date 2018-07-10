$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        $list = Get-SPRList -Uri $script:uri -ListName $script:mylist -WarningAction SilentlyContinue 3> $null
        $null = $list | Remove-SPRList -Confirm:$false -WarningAction SilentlyContinue 3> $null
        # all commands set $global:spsite, remove this variable to start from scratch
        $global:spsite = $null
    }
    AfterAll {
        $list = Get-SPRList -Uri $script:uri -ListName $script:mylist -WarningAction SilentlyContinue 3> $null
        $null = $list | Remove-SPRList -Confirm:$false -WarningAction SilentlyContinue 3> $null
    }
    Context "Connect-SPRSite" {
        It "Connects to a site" {
            $results = Connect-SPRSite -Uri $script:uri
            $results.Url | Should -Be "https://$script:uri"
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
            $results = Get-SPRList -Uri $script:uri -ListName $script:mylist
            $results.Title | Should -Be $script:mylist
            $results.BaseType | Should -Be 'GenericList'
        }
        It "Gets a list named $script:mylist and doesn't require a Uri since Connect-SPRSite was used" {
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
    }
    
    Context "Get-SPRColumnDetail" {
        It "Gets a list named $script:mylist with a basetype GenericList" {
            $results = Get-SPRColumnDetail -Uri $script:uri -ListName $script:mylist
            $results.Name.Count | Should -BeGreaterThan 10
            $results.Name | Should -Contain 'TestColumn'
            $results.Name | Should -Contain 'Scoopty'
            $results.DisplayName | Should -Contain 'PipedColumnSample'
        }
        It "Gets a list named $script:mylist and doesn't require a Uri since Connect-SPRSite was used" {
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
            $results = Add-SPRListItem -Uri $script:uri -ListName $script:mylist -InputObject $object
            $results.Title | Should -Be 'Hello', 'Hello2', 'Hello3'
            $results.TestColumn | Should -Be 'Sample Data', 'Sample Data2', 'Sample Data3'
        }
        if ($env:COMPUTERNAME -eq "workstationx") {
            It "Adds datatable results to list and doesn't require Uri since we used connect earlier" {
                $results = Invoke-DbaSqlQuery -SqlInstance sql2017 -Query "Select Title = 'Hello SQL', TestColumn = 'Sample SQL Data'" | Add-SPRListItem -ListName $script:mylist
                $results.Title | Should -Be 'Hello SQL'
                $results.TestColumn | Should -Be 'Sample SQL Data'
            }
        }
        
        It "Autocreates new list" {
            $newlistname = 'Sample test create new list'
            $object = @()
            $object += [pscustomobject]@{ Title = 'Hello'; TestColumn = 'Sample Data'; }
            $object += [pscustomobject]@{ Title = 'Hello2'; TestColumn = 'Sample Data2'; }
            $object += [pscustomobject]@{ Title = 'Hello3'; TestColumn = 'Sample Data3'; }
            $results = $object | Add-SPRListItem -Uri $script:uri -ListName $newlistname -AutoCreateList
            $results.Title | Should -Be 'Hello', 'Hello2', 'Hello3'
            $results.TestColumn | Should -Be 'Sample Data', 'Sample Data2', 'Sample Data3'
            
            $results = Get-SPRList -Uri $script:uri -ListName $newlistname
            $results | Should -Not -Be $null
            $results | Remove-SPRList -Confirm:$false
        }
    }
    
    Context "Get-SPRListData" {
        It "Gets data from $script:mylist" {
            $results = Get-SPRListData -Uri $script:uri -ListName $script:mylist
            $results.Title.Count | Should -BeGreaterThan 1
            $results.Title | Should -Contain 'Hello SQL'
            $results.TestColumn | Should -Contain 'Sample SQL Data'
            $script:id = $results[0].Id
        }
        
        It "Gets one data based on ID ($script:id), doesn't require Uri" {
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
            $result = Export-SPRListData -Uri $script:uri -ListName $script:mylist -Path $script:filename
            $result.FullName | Should -Be $script:filename
            $string = Select-String -Pattern 'TestColumn' -Path $result
            $string.Count | Should -BeGreaterThan 3
        }
    }
    
    Context "Import-SPRListData" {
        It "imports data from $script:filename" {
            $count = (Get-SPRListData -Uri $script:uri -ListName $script:mylist).Title.Count
            $results = Import-SPRListData -Uri $script:uri -ListName $script:mylist -Path $script:filename
            $results.Title | Should -Contain 'Hello SQL'
            (Get-SPRListData -Uri $script:uri -ListName $script:mylist).Title.Count | Should -BeGreaterThan $count
        }
    }
    
    Context "Add-SPRListItem" {
        It "Imports data from $script:filename" {
            $count = (Get-SPRListData -Uri $script:uri -ListName $script:mylist).Title.Count
            $results = Import-CliXml -Path $script:filename | Add-SPRListItem -Uri $script:uri -ListName $script:mylist
            (Get-SPRListData -Uri $script:uri -ListName $script:mylist).Title.Count | Should -BeGreaterThan $count
            $results.Title | Should -Contain 'Hello SQL'
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
        It "Removes data from $script:mylist" {
            $results = Clear-SPRListData -Uri $script:uri -ListName $script:mylist -Confirm:$false
            Get-SPRListData -Uri $script:uri -ListName $script:mylist | Should -Be $null
        }
    }
    
    Context "Remove-SPRList" {
        It "Removes $script:mylist" {
            $results = Get-SPRList -Uri $script:uri -ListName 'My List', $script:mylist | Remove-SPRList -Confirm:$false
            Get-SPRList -Uri $script:uri -ListName $script:mylist | Should -Be $null
            
        }
    }
}