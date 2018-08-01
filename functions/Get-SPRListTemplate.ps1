Function Get-SPRListTemplate {
<#
.SYNOPSIS
    Get list of native and custom SharePoint templates.

.DESCRIPTION
    Get list of native and custom SharePoint templates.

.PARAMETER Id
    Return only templates with specific IDs

.PARAMETER Name
    Return only templates with specific names

.PARAMETER InputObject
    Piped input from a web
    
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
        [Microsoft.SharePoint.Client.Web[]]$InputObject,
        [switch]$EnableException
    )
    process {
        try {
            if (-not $InputObject) {
                if ($Site) {
                    $null = Connect-SPRSite -Site $Site -Credential $Credential
                }
                
                if ($Web) {
                    $InputObject = Get-SPRWeb -Web $Web
                }
                elseif ($script:spweb) {
                    $InputObject = $script:spweb
                }
                
                if (-not $InputObject) {
                    Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site, Web or run Connect-SPRSite"
                    return
                }
            }
            
            $script:spsite.Load($script:spweb.ListTemplates)
            $script:spsite.Load($script:spsite.Site)
            $customtemplates = $script:spsite.Site.GetCustomListTemplates($script:spweb)
            $script:spsite.Load($customtemplates)
            $script:spsite.ExecuteQuery()
            
            # long story as to why it's done this way
            $templates = $customtemplates, $script:spweb.ListTemplates | Select-DefaultView -Property 'ListTemplateTypeKind as Id', Name, Description, InternalName, BaseType, IsCustomTemplate, Hidden
            
            if ($Id) {
                $templates | Where-Object Id -in $Id
            }
            
            if ($Name) {
                $templates | Where-Object Name -in $Name
            }
            
            if (-not $Id -and -not $Name) {
                $templates
            }
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
        }
    }
}