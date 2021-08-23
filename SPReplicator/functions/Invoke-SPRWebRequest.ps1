Function Invoke-SPRWebRequest {
    <#
.SYNOPSIS
    Invokes a web request against a SharePoint site

.DESCRIPTION
    Invokes a web request against a SharePoint site

.PARAMETER Url
    URL within the SharePoint site to invoke

.PARAMETER Method
    HTTP method to use for the request

.PARAMETER Raw
    If set, the raw web request object will be returned

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Invoke-SPRWebRequest -Url https://intranet.ad.local -Method Get

    Returns the text output of https://intranet.ad.local

.EXAMPLE
    Invoke-SPRWebRequest -Url https://intranet.ad.local -Method Get -Raw

    Returns the raw web request object that can call https://intranet.ad.local
#>
    [CmdletBinding()]
    param (
        [string]$Url = $script:spsite.Url,
        [string]$Method = 'GET',
        [switch]$Raw,
        [switch]$EnableException
    )
    process {
        if (-not $script:spsite) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You must connect to a site using Connect-SPRSite"
            return
        }
    
        try {
            # https://github.com/janikvonrotz/PowerShell-PowerUp/blob/master/functions/SharePoint%20Online/Switch-SPOEnableDisableSolution.ps1
            $request = $script:spsite.WebRequestExecutorFactory.CreateWebRequestExecutor($script:spsite, $Url).WebRequest
            
            $request.Method = "GET"
            
            if ($script:spsite.Credentials) {
                $authCookieValue = $script:spsite.Credentials.GetAuthenticationCookie($script:spsite.Url)
                # Create fed auth Cookie
                $cookiejar = New-Object System.Net.Cookie
                $cookiejar.Name = "FedAuth"
                $cookiejar.Value = $authCookieValue.TrimStart("SPOIDCRL=")
                $cookiejar.Path = "/"
                $cookiejar.Secure = $true
                $cookiejar.HttpOnly = $true
                $cookiejar.Domain = (New-Object System.Uri($script:spsite.Url)).Host
                $cookieContainer.Add($cookiejar)
                $request.CookieContainer = $cookieContainer
            } else {
                # No specific authentication required
                $request.UseDefaultCredentials = $true
            }
            if ($Raw) {
                $request
            } else {
                $sr = New-Object System.IO.StreamReader($request.GetResponse().GetResponseStream()) 
                $sr.ReadToEnd()
            }
        } catch {
            Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
        }
    }
}