$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        if ($env:appveyor) {
            $env:psmodulepath = "$env:psmodulepath; C:\projects"
        }
        $oldconfig = Get-SPRConfig -Name location
        $null = Set-SPRConfig -Name location -Value Online
        $thislist = Get-SPRList -Site $script:onlinesite -Credential $script:onlinecred -List $script:mylist -WarningAction SilentlyContinue 3> $null
        $null = $thislist | Remove-SPRList -Confirm:$false -WarningAction SilentlyContinue 3> $null
        $originallists = Get-SPRList | Where-Object Title -ne "SPRLog"
        $originalwebs = Get-SPRWeb
        $originalusers = Get-SPRUser
    }
    AfterAll {
        $thislist = Get-SPRList -Site $script:onlinesite -Credential $script:onlinecred -List $script:mylist -WarningAction SilentlyContinue 3> $null
        $null = $thislist | Remove-SPRList -Confirm:$false -WarningAction SilentlyContinue 3> $null
        $results = Set-SPRConfig -Name location -Value $oldconfig.Value
        Remove-Item -Path $script:filename -ErrorAction SilentlyContinue
    }
    
    Context "Connect-SPRSite" {
        It "Connects to a site" {
            $results = Connect-SPRSite -Site $script:onlinesite -Credential $script:onlinecred -ErrorVariable erz -WarningAction SilentlyContinue -WarningVariable warn -EnableException
            $erz | Should -Be $null
            $warn | Should -Be $null
            $results.Url | Should -Be $script:onlinesite
            $results.RequestTimeout | Should -Be 180000
        }
    }
    
    if ($erz -or $warn) {
        throw "no more, test failed"
    }
    
    Context "Get-SPRConnectedSite" {
        It "Gets connected site information" {
            $results = Get-SPRConnectedSite
            $results.Url | Should -Be $script:onlinesite
            $results.RequestTimeout | Should -Be 180000
        }
    }
    
    Context "Get-SPRWeb" {
        It "Gets a web" {
            $results = Get-SPRWeb | Select-Object -First 1
            $results.Url | Should -Be $script:onlinesite
            $results.RecycleBinEnabled | Should -Not -Be $null
        }
    }
    
    Context "Get-SPRListTemplate" {
        It "Gets all template info" {
            $results = Get-SPRListTemplate
            $results.Count | Should -BeGreaterThan 10
        }
        It "Gets specific template info by id" {
            $results = Get-SPRListTemplate -Id 100 | Select-Object -First 1
            $results.Id | Should -Be 100
        }
        It "Gets specific template info by name" {
            $results = Get-SPRListTemplate -Name 'Custom List'
            $results.Name.Count | Should -Be 1
            $results.Name | Should -Be 'Custom List'
        }
    }
    
    Context "New-SPRList" {
        It "Supports WhatIf" {
            InModuleScope SPReplicator { Mock Test-PSFShouldProcess { $null } }
            $results = New-SPRList -Title $script:mylist -Description "My List Description" -WhatIf
            $results | Should -Be $null
            Import-Module SPReplicator -Force
        }
        It "Creates a new list named $script:mylist" {
            $results = New-SPRList -Title $script:mylist -Description "My List Description"
            $results.Title | Should -Be $script:mylist
            $results.GetType().Name | Should -Be 'List'
            $results.Description | Should -Be "My List Description"
        }
        It "Does not create a duplicate list named $script:mylist" {
            $results = New-SPRList -Title $script:mylist -WarningAction SilentlyContinue 3>$null
            $results | Should -Be $null
        }
    }
    
    Context "Get-SPRList" {
        $script:spsite = $null
        It "Gets a list named $script:mylist with a basetype GenericList" {
            $results = Get-SPRList -List $script:mylist
            $results.Title | Should -Be $script:mylist
            $results.BaseType | Should -Be 'GenericList'
        }
        It "Gets a list named $script:mylist and doesn't require a Site since Connect-SPRSite was used" {
            $results = Get-SPRList -List $script:mylist
            $results.Title | Should -Be $script:mylist
        }
    }
    
    Context "Add-SPRColumn" {
        It "Supports WhatIf" {
            InModuleScope SPReplicator { Mock Test-PSFShouldProcess { $null } }
            $results = Add-SPRColumn -List $script:mylist -ColumnName TestColumn -Description "One column" -WhatIf
            $results | Should -Be $null
            Import-Module SPReplicator -Force
        }
        It "Adds a column named TestColumn" {
            $results = Add-SPRColumn -List $script:mylist -ColumnName TestColumn -Description "One column"
            $results.List | Should -Be $script:mylist
            $results.Name | Should -Be TestColumn
            $results.DisplayName | Should -Be TestColumn
            $results.Description | Should -Be "One column"
        }
        It "Supports piping" {
            $results = Get-SPRList -List $script:mylist | Add-SPRColumn -ColumnName Scoopty -DisplayName PipedColumnSample
            $results.List | Should -Be $script:mylist
            $results.Name | Should -Be Scoopty
            $results.DisplayName | Should -Be PipedColumnSample
            $results.Description.Length | Should -Be 0
        }
        It "Supports xml" {
            $xml = "<Field Type='URL' Name='EmployeePicture' StaticName='EmployeePicture'  DisplayName='Employee Picture' Format='Image'/>"
            $results = Get-SPRList -List $script:mylist | Add-SPRColumn -Xml $xml
            $results.DisplayName | Should -Be 'Employee Picture'
            $results.Type | Should -Be 'Hyperlink or Picture'
            $results.List | Should -Be $script:mylist
        }
    }
    
    Context "Get-SPRColumnDetail" {
        It "Gets a list named $script:mylist with a basetype GenericList" {
            $results = Get-SPRColumnDetail -List $script:mylist
            $results.Name.Count | Should -BeGreaterThan 10
            $results.Name | Should -Contain 'TestColumn'
            $results.Name | Should -Contain 'Scoopty'
            $results.DisplayName | Should -Contain 'PipedColumnSample'
        }
        It "Gets a list named $script:mylist and doesn't require a Site since Connect-SPRSite was used" {
            $results = Get-SPRColumnDetail -List $script:mylist
            $results.Name.Count | Should -BeGreaterThan 10
        }
    }
    
    Context "Add-SPRListItem" {
        It "Supports WhatIf" {
            InModuleScope SPReplicator { Mock Test-PSFShouldProcess { $null } }
            $object = @()
            $object += [pscustomobject]@{ Title = 'Hello'; TestColumn = 'Sample Data'; }
            $object += [pscustomobject]@{ Title = 'Hello2'; TestColumn = 'Sample Data2'; }
            $object += [pscustomobject]@{ Title = 'Hello3'; TestColumn = 'Sample Data3'; }
            $results = Add-SPRListItem -List $script:mylist -InputObject $object -WhatIf
            $results | Should -Be $null
            Import-Module SPReplicator -Force
        }
        It "Adds generic objects to list" {
            $object = @()
            $object += [pscustomobject]@{ Title = 'Hello'; TestColumn = 'Sample Data'; }
            $object += [pscustomobject]@{ Title = 'Hello2'; TestColumn = 'Sample Data2'; }
            $object += [pscustomobject]@{ Title = 'Hello3'; TestColumn = 'Sample Data3'; }
            $results = Add-SPRListItem -List $script:mylist -InputObject $object
            $results.Title | Should -Be 'Hello', 'Hello2', 'Hello3'
            $results.TestColumn | Should -Be 'Sample Data', 'Sample Data2', 'Sample Data3'
        }
        It "Adds datatable results to list and doesn't require Site since we used connect earlier" {
            if ($PSVersionTable.PSEdition -ne "Core" -and $env:COMPUTERNAME -eq "workstationx") {
                $dt = Invoke-DbaSqlQuery -SqlInstance sql2017 -Query "Select Title = 'Hello SQL', TestColumn = 'Sample SQL Data'"
            }
            else {
                $dt = New-Object System.Data.Datatable
                [void]$dt.Columns.Add("Title")
                [void]$dt.Columns.Add("TestColumn")
                [void]$dt.Rows.Add("Hello SQL", "Sample SQL Data")
            }
            $results = $dt | Add-SPRListItem -List $script:mylist
            $results.Title | Should -Be 'Hello SQL'
            $results.TestColumn | Should -Be 'Sample SQL Data'
        }
        It "Quietly adds new objects to list" {
            $object = @()
            $object += [pscustomobject]@{ Title = 'Sup'; TestColumn = 'Sample Sup'; }
            $object += [pscustomobject]@{ Title = 'Sup2'; TestColumn = 'Sample Sup2'; }
            $object += [pscustomobject]@{ Title = 'Sup3'; TestColumn = 'Sample Sup3'; }
            $results = Add-SPRListItem -List $script:mylist -InputObject $object -Quiet
            $results | Should -Be $null
            $results = Get-SPRListItem -List $script:mylist
            $results.Title | Should -Contain 'Sup'
            $results.Title | Should -Contain 'Sup2'
            $results.Title | Should -Contain 'Sup3'
            $results.TestColumn | Should -Contain 'Sample Sup3'
        }
        It "Autocreates new list and adds new items as user System Account" {
            $newList = 'Sample test create new list'
            $object = @()
            $object += [pscustomobject]@{ Title = 'Hello'; TestColumn = 'Sample Data'; }
            $object += [pscustomobject]@{ Title = 'Hello2'; TestColumn = 'Sample Data2'; }
            $object += [pscustomobject]@{ Title = 'Hello3'; TestColumn = 'Sample Data3'; }
            $results = $object | Add-SPRListItem -List $newList -AutoCreateList -AsUser 'System Account'
            $results.Title | Should -Be 'Hello', 'Hello2', 'Hello3'
            $results.TestColumn | Should -Be 'Sample Data', 'Sample Data2', 'Sample Data3'
            $results.Author | Should -Be 'System Account', 'System Account', 'System Account'
            $results = Get-SPRList -List $newList
            $results | Should -Not -Be $null
            Remove-SPRList -List $newList -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
    }
    
    Context "Get-SPRListItem" {
        It "Gets data from $script:mylist" {
            $results = Get-SPRListItem -List $script:mylist -Site $script:onlinesite -Credential $script:onlinecred
            $results.Title.Count | Should -BeGreaterThan 1
            $results.Title | Should -Contain 'Hello SQL'
            $results.TestColumn | Should -Contain 'Sample SQL Data'
            $script:id = $results[0].Id
        }
        
        It "Gets one data based on ID ($script:id), doesn't require Site" {
            $results = Get-SPRListItem -List $script:mylist -Id $script:id
            $results.Title.Count | Should -Be 1
            $results.Id | Should -Be $script:id
        }
    }
    
    Context "Get-SPRListView" {
        It "Returns at least one view with some xml" {
            $results = Get-SPRListView -List $script:mylist
            $results.List.Title | Should -Be $script:mylist
            $results.ViewQuery | Should -Not -Be $null
        }
        It "Throws if a view doesn't exist" {
            $null = Get-SPRListItem -List $script:mylist -View DoesntExist -WarningAction SilentlyContinue -WarningVariable warning 3>$null
            $warning | Should -Match "invalid"
        }
        It "Works" {
            $view = Get-SPRListView -List $script:mylist | Where-Object DefaultView | Select-Object -ExpandProperty Title
            $results = Get-SPRListItem -List $script:mylist -View $view
            $results.Title | Should -Not -Be $null
        }
    }
    
    Context "Export-SPRListItem" {
        It "Gets data from $script:mylist" {
            if ((Test-Path $script:filename)) {
                Remove-Item $script:filename
            }
            $result = Export-SPRListItem -List $script:mylist -Path $script:filename
            $result.FullName | Should -Be $script:filename
        }
    }
    
    Context "Import-SPRListItem" {
        It "Supports WhatIf" {
            InModuleScope SPReplicator { Mock Test-PSFShouldProcess { $null } }
            $results = Import-SPRListItem -List $script:mylist -Path $script:filename -WhatIf
            $results | Should -Be $null
            Import-Module SPReplicator -Force
        }
        It "Imports data from $script:filename" {
            $count = (Get-SPRListItem -List $script:mylist).Title.Count
            $results = Import-SPRListItem -List $script:mylist -Path $script:filename
            $results.Title | Should -Contain 'Hello SQL'
            (Get-SPRListItem -List $script:mylist).Title.Count | Should -BeGreaterThan $count
        }
    }
    
    Context "Add-SPRListItem" {
        It "Imports data from $script:filename" {
            $count = (Get-SPRListItem -List $script:mylist).Title.Count
            $results = Import-PSFCliXml -Path $script:filename | Select-Object -ExpandProperty Data | Add-SPRListItem -List $script:mylist
            (Get-SPRListItem -List $script:mylist).Title.Count | Should -BeGreaterThan $count
            $results.Title | Should -Contain 'Hello SQL'
        }
    }
    
    Context "Update-SPRListItem" {
        (Import-PSFCliXml -Path $script:filename) | Export-Clixml -Path $script:filename
        (Get-Content $script:filename).replace('Hello SQL', 'ScooptyScoop') | Set-Content $script:filename
        (Get-Content $script:filename).replace('Sample SQL Data', 'ScooptyData') | Set-Content $script:filename
        $updates = Import-CliXml -Path $script:filename | Select-Object -ExpandProperty Data
        
        It "Supports WhatIf" {
            InModuleScope SPReplicator { Mock Test-PSFShouldProcess { $null } }
            $results = Get-SPRListItem -List $script:mylist | Update-SPRListItem -UpdateObject $updates -Confirm:$false -WhatIf
            $results | Should -Be $null
            Import-Module SPReplicator -Force
        }
        It "Updates data from $script:filename" {
            # Replace a value to update
            $results = Get-SPRListItem -List $script:mylist | Update-SPRListItem -UpdateObject $updates -Confirm:$false
            $results.Title.Count | Should -Be 1
            $results.Title | Should -Be 'ScooptyScoop'
            $results.TestColumn | Should -Be 'ScooptyData'
        }
        It "Doesn't update the other rows" {
            $results = Get-SPRListItem -List $script:mylist
            $results.Title | Should -Contain 'ScooptyScoop'
            $results.Title | Should -Contain 'Hello'
            $results.Title | Should -Contain 'Hello2'
            $results.Title | Should -Contain 'Hello3'
        }
    }
    
    Context "Get-SPRUser" {
        It "Gets users from $script:onlinesite"  {
            $results = Get-SPRUser
            $results.Title | Should -Contain 'System Account'
            $results.Title.Count | Should -BeGreaterThan 2
        }
    }
    
    Context "Select-SPRObject" {
        It "Gets data from $script:mylist and excludes other data" {
            $results = Get-SPRListItem -List $script:mylist | Select-SPRObject -Property 'Title as Test1234'
            $results | Get-Member -Name Title | Should -Be $null
            $results | Get-Member -Name Test1234 | Should -Not -Be $null
            $results.Test1234 | Should -Contain 'ScooptyScoop'
        }
    }
    
    Context "Update-SPRListItemAuthorEditor" {
        It "Supports WhatIf" {
            InModuleScope SPReplicator { Mock Test-PSFShouldProcess { $null } }
            $results = Get-SPRListItem -List $script:mylist | Select-Object -First 1 | Update-SPRListItemAuthorEditor -Username 'System Account' -Confirm:$false -WhatIf
            $results | Should -Be $null
            Import-Module SPReplicator -Force
        }
        It "Updates author/editor for a single item on $script:mylist" {
            $results = Get-SPRListItem -List $script:mylist | Select-Object -First 1 | Update-SPRListItemAuthorEditor -Username 'System Account' -Confirm:$false
            $results.Author | Should -Be 'System Account'
            $results.Editor | Should -Be 'System Account'
        }
        It "Doesn't update other things" {
            $results = Get-SPRListItem -List $script:mylist
            $results.Author | Should -Contain (Connect-SPRSite -Site $script:onlinesite -Credential $script:onlinecred).CurrentUser.Title
        }
    }
    
    Context "Set-SPRListFieldValue" {
        It "Supports WhatIf" {
            InModuleScope SPReplicator { Mock Test-PSFShouldProcess { $null } }
            $results = Get-SPRListItem -List $script:mylist | Select-Object -Last 1 | Set-SPRListFieldValue -Column Title -Value ABC -Confirm:$false -WhatIf
            $results | Should -Be $null
            Import-Module SPReplicator -Force
        }
        
        $current = Get-SPRListItem -List $script:mylist
        
        It "Updates a single column on $script:mylist" {
            $pre = $current | Select-Object -Last 1
            $results = Get-SPRListItem -List $script:mylist | Select-Object -Last 1 | Set-SPRListFieldValue -Column Title -Value ABC -Confirm:$false
            $pre.Author | Should -Be $results.Author
            $post = Get-SPRListItem -List $script:mylist | Select-Object -Last 1
            $post.Title | Should -Be 'ABC'
            $pre.TestColumn | Should -Be $post.TestColumn
        }
        It "Doesn't update other things" {
            $pre = $current | Select-Object -First 1
            $post = Get-SPRListItem -List $script:mylist | Select-Object -First 1
            $pre.Author | Should -Be $post.Author
            $pre.Title | Should -Be $post.Title
            $pre.TestColumn | Should -Be $post.TestColumn
        }
    }
    
    Context "New-SPRLogList" {
        It "Supports WhatIf" {
            InModuleScope SPReplicator { Mock Test-PSFShouldProcess { $null } }
            $results = New-SprLogList -Title SPReplicator -WhatIf
            $results | Should -Be $null
            Import-Module SPReplicator -Force
        }
        It "Creates a new log list" {
            $results = New-SprLogList -Title SPReplicator
            $columns = $results | Get-SPRColumnDetail | Select-Object -ExpandProperty Name
            $columns | Should -Contain "FinishTime"
            $columns | Should -Contain "ItemCount"
            $columns | Should -Contain "Result"
            $columns | Should -Contain "Type"
            $columns | Should -Contain "Duration"
            $columns | Should -Contain "RunAs"
            $columns | Should -Contain "Message"
            $columns | Should -Contain "URL"
            $results.Title | Should -Be "SPReplicator"
            $results.BaseType | Should -Be "GenericList"
            $results | Remove-SPRList -Confirm:$false
        }
    }
    
    Context "Remove-SPRListItem" {
        It "Supports WhatIf" {
            InModuleScope SPReplicator { Mock Test-PSFShouldProcess { $null } }
            $results = Get-SPRListItem -List $script:mylist | Where-Object Id -in $script:id | Remove-SPRListItem -Confirm:$false -WhatIf
            $results | Should -Be $null
            Import-Module SPReplicator -Force
        }
        It "Removes specific data from $script:mylist" {
            $row = Get-SPRListItem -List $script:mylist -Id $script:id
            $row | Should -Not -Be $null
            $results = Get-SPRListItem -List $script:mylist | Where-Object Id -in $script:id | Remove-SPRListItem -Confirm:$false
            $results.Site | Should -Not -Be $null
            $row = Get-SPRListItem -List $script:mylist -Id $script:id  3> $null
            $row | Should -Be $null
        }
    }
    
    Context "Clear-SPRListItems" {
        It "Supports WhatIf" {
            InModuleScope SPReplicator { Mock Test-PSFShouldProcess { $null } }
            $results = Clear-SPRListItems -List $script:mylist -Confirm:$false -WhatIf
            $results | Should -Be $null
            Import-Module SPReplicator -Force
        }
        It "Removes data from $script:mylist" {
            $results = Clear-SPRListItems -List $script:mylist -Confirm:$false
            Get-SPRListItem -List $script:mylist | Should -Be $null
            Get-SPRList -List $script:mylist | Select-Object -ExpandProperty ItemCount | Should -Be 0
        }
    }
    
    Context "Remove-SPRList" {
        It "Supports WhatIf" {
            InModuleScope SPReplicator { Mock Test-PSFShouldProcess { $null } }
            $results = Get-SPRList -List 'My List', $script:mylist | Remove-SPRList -Confirm:$false -WhatIf
            $results | Should -Be $null
            Import-Module SPReplicator -Force
        }
        It "Removes $script:mylist" {
            $results = Get-SPRList -List 'My List', $script:mylist | Remove-SPRList -Confirm:$false
            Get-SPRList -List $script:mylist | Should -Be $null
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
            $results = Set-SPRConfig -Name location -Value Online
            $results.Value | Should -Be 'Online'
            $results = Get-SPRConfig
            ($results | Where-Object Name -eq location).Value | Should -Be 'Online'
        }
    }
    Remove-Item -Path $script:filename -ErrorAction SilentlyContinue
}

Describe "$CommandName Final Tests" -Tag "Finaltests" {
    Context "Checking to ensure all original data has remained" {
        $nowlists = Get-SPRList | Where-Object Title -ne "SPRLog"
        $nowwebs = Get-SPRWeb
        $nowusers = Get-SPRUser
        $originalsum = $originallists.ItemCount | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        $nowlistssum = $nowlists.ItemCount | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        
        It "Site has the same number of webs as before" {
            $originalwebs.Count | Should -Be $nowwebs.Count
        }
        
        It "Site has the same number of lists as before" {
            $originallists.Count | Should -Be $nowlists.Count
        }
        
        It "Site has the same number of users as before" {
            $originalusers.Count | Should -Be $nowusers.Count
        }
        
        It "Lists still have $originalsum items" {
            $originalsum | Should -Be $nowlistssum
            $originalsum | Should -BeGreaterThan 0
        }
        
        foreach ($web in $originalwebs) {
            It "$($web.Title) currently exists" {
                $nowwebs.Title | Should -contain $web.Title
            }
        }
        
        foreach ($list in $originallists) {
            It "$($list.Title) currently exists" {
                $nowlists.Title | Should -contain $list.Title
            }
        }
        
        foreach ($user in $originalusers) {
            It "$($user.Title) currently exists" {
                $nowusers.Title | Should -contain $user.Title
            }
        }
    }
}