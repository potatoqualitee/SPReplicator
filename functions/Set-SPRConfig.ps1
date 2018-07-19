function Set-SPRConfig {
    <#
        .SYNOPSIS
            Sets configuration entries.
    
        .DESCRIPTION
            This function creates or changes configuration values.

            These can be used to provide dynamic configuration information outside the PowerShell variable system.
    
        .PARAMETER Name
            Name of the configuration entry.
    
        .PARAMETER Value
            The value to assign to the named configuration element.
    
        .PARAMETER Handler
            A scriptblock that is executed when a value is being set.

            Is only executed if the validation was successful (assuming there was a validation, of course)
    
        .PARAMETER Append
            Adds the value to the existing configuration instead of overwriting it
    
        .PARAMETER Temporary
            The setting is not persisted outside the current session.
            By default, settings will be remembered across all powershell sessions.
    
        .PARAMETER EnableException
            By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
            This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
            Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
            
        .EXAMPLE
            Set-SPRConfig -Name Location -Value Online
        
            Sets the location to online (as opposed to onprem)
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding(DefaultParameterSetName = "FullName")]
    param (
        [string]$Name,
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        $Value,
        [System.Management.Automation.ScriptBlock]$Handler,
        [switch]$Append,
        [switch]$Temporary,
        [switch]$EnableException
    )
    
    process {
        if (-not (Get-SPRConfig -Name $Name)) {
            Stop-PSFFunction -Message "Setting named $Name does not exist. If you'd like us to support an additional setting, please file a GitHub issue."
            return
        }
        
        if ($append) {
            $Value = (Get-PSFConfigValue -FullName SPReplicator.$Name), $Value
        }
        
        $Name = $Name.ToLower()
        
        Set-PSFConfig -Module SPReplicator -Name $name -Value $Value
        try {
            if (-not $Temporary) { Register-PSFConfig -FullName SPReplicator.$name -EnableException -WarningAction SilentlyContinue }
        }
        catch {
            Set-PSFConfig -Module SPReplicator -Name $name -Value ($Value -join ", ")
            if (-not $Temporary) { Register-PSFConfig -FullName SPReplicator.$name }
        }
        
        Get-SPRConfig -Name $name
    }
}