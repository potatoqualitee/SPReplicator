Function Get-SPRService {
<#
.SYNOPSIS
    Creates a SharePoint Web service proxy object that lets you use and manage the Web service in Windows PowerShell.
    
.DESCRIPTION
    Creates a SharePoint Web service proxy object that lets you use and manage the Web service in Windows PowerShell.
    
.PARAMETER Uri
    The address to the web application. You can also pass a hostname and it'll figure it out.

.PARAMETER Credential
    Provide alternative credentials to the web service. Otherwise, it will use default credentials. 
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
 
.PARAMETER WhatIf
    If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

.PARAMETER Confirm
    If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

.EXAMPLE
    Get-SPRService -Uri intranet.ad.local

    Creates a web service object for intranet.ad.local. Figures out the wsdl address automatically.
    
.EXAMPLE
    Get-SPRService -Uri http://intranet.ad.local/_vti_bin/lists.asmx?wsdl

    Creates a web service object for intranet.ad.local using the formal and complete address.
    
.EXAMPLE
    Get-SPRService -Uri intranet.ad.local -Credential (Get-Credential ad\user)

    Creates a web service object and logs into the webapp as ad\user.
            
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage = "SharePoint lists.asmx?wsdl location")]
        [string]$Uri,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    
    if ($Uri.EndsWith('wsdl')) {
        # seems legit
    }
    elseif ($Uri.EndsWith('asmx')) {
        $Uri = "$Uri`?wsdl"
    }
    else {
        $parseduri = [System.Uri]$Uri
        $scheme = $parseduri.Scheme
        if (-not $scheme) {
            $scheme = "http"
        }
        $hostname = $parseduri.Host
        if (-not $hostname) {
            $hostname = $Uri
        }
        
        $Uri = "$scheme`://$hostname/_vti_bin/lists.asmx?wsdl"
    }
    
    Write-PSFMessage -Level Verbose -Message "Connecting to the SharePoint service at $Uri"
    try {
        if ($Credential) {
            New-WebServiceProxy -Uri $Uri -Namespace SpWs -Credential $Credential -ErrorAction Stop
        }
        else {
            New-WebServiceProxy -Uri $Uri -Namespace SpWs -UseDefaultCredential -ErrorAction Stop
        }
    }
    catch {
        Stop-PSFFunction -Message "Failure" -ErrorRecord $_
    }
}