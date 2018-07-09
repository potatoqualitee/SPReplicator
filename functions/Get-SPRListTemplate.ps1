Function Get-SPRListTemplate {
<#
.SYNOPSIS
    Returns data from a SharePoint list using a Web service proxy object.
    
.DESCRIPTION
    Returns data from a SharePoint list using a Web service proxy object.

.PARAMETER Id
    Return only rows with specific IDs
   
.PARAMETER Name
    Return only rows with specific names
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE    
    Get-SPRListTemplate
    
    Returns all templates and their corresponding numbers
    
.EXAMPLE    
    Get-SPRListTemplate -Id 100, 118
    
    Returns all templates and their corresponding numbers that match 100 and 118
    
.EXAMPLE    
    Get-SPRListTemplate -Name AdminTasks, HealthReports
    
    Returns templates and their corresponding numbers that match the name AdminTasks and HealthReports
#>
    [CmdletBinding()]
    param (
        [int[]]$Id,
        [string[]]$Name,
        [switch]$EnableException
    )
    process {
        # string description = Enumerations.GetEnumDescription((MyEnum)value);
        try {
            $class = [Microsoft.SharePoint.Client.ListTemplateType]
            if ($Id) {
                foreach ($template in [System.Enum]::GetNames($class)) {
                    $number = [int][System.Enum]::Parse($class, $template)
                    if ($number -in $Id) {
                        [pscustomobject]@{
                            ID       = $number
                            Template = $template
                        }
                    }
                }
            }
            elseif ($Name) {
                foreach ($template in [System.Enum]::GetNames($class)) {
                    if ($template -in $name) {
                        [pscustomobject]@{
                            ID       = [int][System.Enum]::Parse($class, $template)
                            Template = $template
                        }
                    }
                }
            }
            else {
                foreach ($template in [System.Enum]::GetNames($class)) {
                    [pscustomobject]@{
                        ID = [int][System.Enum]::Parse($class, $template)
                        Template = $template
                    }
                }
            }
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
        }
    }
}