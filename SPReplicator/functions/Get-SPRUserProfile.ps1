Function Get-SPRUserProfile {
<#
.SYNOPSIS
    Sets SharePoint user profile properties.

.DESCRIPTION
    Sets SharePoint user profile  properties.

    This requires : https://social.technet.microsoft.com/Forums/msonline/en-US/90459cd0-d3e6-4078-80c4-399e56aeaed0/how-to-see-who-has-the-8220manage-profile8221-permissions-for-user-profile-properties?forum=onlineservicessharepoint

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER Identity
    The Active Directory Identity

.PARAMETER InputObject
    Allows piping from Get-SPRUser

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local
    Get-SPRUserProfile -Identity 'ad\user' -Property Email -Value test@hello.com

    Sets the ad\user SharePoint object on intranet.ad.local

.EXAMPLE
    Get-SPRUserProfile -Site intranet.ad.local -Identity 'ad\user' -Property Email -Value test@hello.com

    Sets the ad\user SharePoint object on intranet.ad.local
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint user name")]
        [string[]]$Identity,
        [Parameter(Position = 1, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [Microsoft.SharePoint.Client.User[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $null = Connect-SPRSite -Site $Site -Credential $Credential
                $InputObject = Get-SPRUser -Identity $Identity
            }
            elseif ($script:spweb) {
                $InputObject = Get-SPRUser -Identity $Identity
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site or run Connect-SPRSite"
                return
            }
        }
        
        if (-not $InputObject) {
            Stop-PSFFunction -EnableException:$EnableException -Message "$Identity not found in $spsite"
            return
        }
        
        foreach ($user in $InputObject) {
            if ($user -isnot [Microsoft.SharePoint.Client.User]) {
                Stop-PSFFunction -EnableException:$EnableException -Message "Invalid inputobject"
                return
            }
            $user.Context.Load($user)
            $login = $user.LoginName
            $user.Context.ExecuteQuery()
            try {
                $people = New-Object Microsoft.SharePoint.Client.UserProfiles.PeopleManager($user.Context)
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                return
            }
            
            try {
                $userprofile = $people.GetPropertiesFor($login)
                $user.Context.Load($userprofile)
                $user.Context.ExecuteQuery()
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message 'Failure. Did you run "Setup My Sites"?' -ErrorRecord $erecord
                return
            }
            if ($userprofile.UserProfileProperties.Keys) {
                $keys = $userprofile.UserProfileProperties.Keys | Sort-Object
                $properties = [pscustomobject] | Select-Object -Property $keys
                foreach ($key in $keys) {
                    try { $value = $userprofile.UserProfileProperties[$key] } catch { $value = $null }
                    $properties.$key = $value
                }
                Add-Member -InputObject $properties -NotePropertyName UserProfileObject -NotepropertyValue $userprofile -Force
                Select-Object -InputObject $properties -Property *
            }
        }
    }
}