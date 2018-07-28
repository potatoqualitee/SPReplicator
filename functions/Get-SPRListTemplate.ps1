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
                elseif ($global:spweb) {
                    $InputObject = $global:spweb
                }
                
                if (-not $InputObject) {
                    Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site, Web or run Connect-SPRSite"
                    return
                }
            }
            
            $global:spsite.Load($global:spweb.ListTemplates)
            $global:spsite.Load($global:spsite.Site)
            $customtemplates = $global:spsite.Site.GetCustomListTemplates($global:spweb)
            $global:spsite.Load($customtemplates)
            $global:spsite.ExecuteQuery()
            
            $templates = $customtemplates, $global:spweb.ListTemplates
            
            if ($id) {
                $templates = $templates | Where-Object ListTemplateTypeKind -in $id
            }
            if ($Name) {
                $templates = $templates | Where-Object Name -in $name
            }
            
            $templates | Select-SPRObject -Property 'ListTemplateTypeKind as Id', Name, Description, InternalName, BaseType, IsCustomTemplate, Hidden
        }
        catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
        }
    }
}