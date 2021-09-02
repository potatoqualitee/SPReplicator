Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\..\constants.ps1"

Describe "Online Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        $env:psmodulepath = "$env:psmodulepath:/home/runner/work/SPReplicator/SPReplicator"
        $script:mylist = "My Actions List"
        $script:filename = "/tmp/$script:mylist.xml"
        $script:onlinesite = "https://netnerds.sharepoint.com/"
        $secpasswd = ConvertTo-SecureString $env:CLIENTSECRET -AsPlainText -Force
        $script:onlinecred = New-Object System.Management.Automation.PSCredential ($env:CLIENTID, $secpasswd)
        $PSDefaultParameterValues["Connect-SPRSite:AuthenticationMode"] = "AppOnly"
        Import-Module /home/runner/work/SPReplicator/SPReplicator/SPReplicator/SPReplicator.psd1
 
        $oldconfig = Get-SPRConfig -Name location
        $null = Set-SPRConfig -Name location -Value Online
        $null = Connect-SPRSite -Site $script:onlinesite -Credential $script:onlinecred
        $thislist = Get-SPRList -Site $script:onlinesite -Credential $script:onlinecred -List $script:mylist, 'Sample test create new list' -WarningAction SilentlyContinue 3> $null
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
            $results.Url | Should -match sharepoint.com
            $results.RequestTimeout | Should -Be 180000
        }
    }

    if ($erz -or $warn) {
        throw "no more, test failed"
    }

    Context "Get-SPRConnectedSite" {
        It "Gets connected site information" {
            $results = Get-SPRConnectedSite
            $results.Url | Should -match sharepoint.com
            $results.RequestTimeout | Should -Be 180000
        }
    }

    Context "Get-SPRWeb" {
        It "Gets a web" {
            $results = Get-SPRWeb | Select-Object -First 1
            $results.Url | Should -match sharepoint.com
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
}