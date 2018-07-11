Function Get-SPRColumnDetail {
 <#
.SYNOPSIS
    Returns information (Name, DisplayName, Data type) about columns in a SharePoint list.

.DESCRIPTION
    Returns information (Name, DisplayName, Data type) about columns in a SharePoint list.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER ListName
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER InputObject
    Allows piping from Get-SPRList

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRColumnDetail -Site intranet.ad.local -ListName 'My List'

    Gets column information from My List on intranet.ad.local.

.EXAMPLE
    Get-SPRList -ListName 'My List' -Site intranet.ad.local | Get-SPRColumnDetail

     Gets column information from My List on intranet.ad.local.

.EXAMPLE
    Get-SPRListData -Site intranet.ad.local -ListName 'My List' -Credential (Get-Credential ad\user)

    Gets column information from My List on intranet.ad.local by logging into the webapp as ad\user.
#>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [Parameter(HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $InputObject = Get-SPRList -Site $Site -Credential $Credential -ListName $ListName
            }
            elseif ($global:spsite) {
                $InputObject = $global:spsite | Get-SPRList -ListName $ListName
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site and ListName pipe in results from Get-SPRList"
                return
            }
        }

        foreach ($list in $InputObject) {
            try {
                $list.Context.Load($list.Fields)
                $list.Context.ExecuteQuery()
                foreach ($column in $list.Fields) {
                    $title = $column.Title
                    Add-Member -InputObject $column -MemberType NoteProperty -Name ListName -Value $list.Title
                    Add-Member -InputObject $column -MemberType NoteProperty -Name OwsName -Value "ows_$title"
                    Select-DefaultView -InputObject $column -Property ListName, 'Title as DisplayName', 'StaticName as Name', 'TypeDisplayName as Type'
                }
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -ErrorRecord $_ -Message "Failure"
            }
        }
    }
}