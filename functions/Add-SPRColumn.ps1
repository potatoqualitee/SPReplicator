Function Add-SPRColumn {
<#
.SYNOPSIS
    Returns data from a SharePoint list using a Web service proxy object.
    
.DESCRIPTION
    Returns data from a SharePoint list using a Web service proxy object.
    
.PARAMETER Uri
    The address to the web application. You can also pass a hostname and it'll figure it out.

.PARAMETER ListName
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.
    
.PARAMETER RowLimit
    Limit the number of rows returned. The entire list is returned by default.
 
.PARAMETER Id
    Return only rows with specific IDs
 
.PARAMETER Credential
    Provide alternative credentials to the web service. Otherwise, it will use default credentials. 
 
.PARAMETER IntputObject
    Allows piping from Add-SPRColumn 
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
 
.EXAMPLE
    Add-SPRColumn -Uri intranet.ad.local -ListName 'My List'

    Gets data from My List on intranet.ad.local. Figures out the wsdl address automatically.
    
.EXAMPLE
    Add-SPRColumn -ListName 'My List' -Uri intranet.ad.local | Add-SPRColumn

     Gets data from My List on intranet.ad.local.
    
.EXAMPLE
    Add-SPRColumn -Uri intranet.ad.local -ListName 'My List' -Credential (Get-Credential ad\user)

    Gets data from My List and logs into the webapp as ad\user.
    
.EXAMPLE    
    Add-SPRColumn -Uri sharepoint2016 -ListName 'My List' -Id 100, 101, 105
    
    Gets list items with ID 100, 101 and 105
#>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Uri,
        [PSCredential]$Credential,
        [Parameter(HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [Parameter(Mandatory)]
        [string]$ColumnName,
        [string]$DisplayName,
        [string]$Type = "Text",
        [string]$Description,
        [string]$Xml,
        [string]$Default,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$DoNotAddToDefaultView,
        [ValidateSet("DefaultValue", "AddToDefaultContentType", "AddToNoContentType", "AddToAllContentTypes", "AddFieldInternalNameHint", "AddFieldToDefaultView", "AddFieldCheckDisplayName")]
        [string[]]$FieldOption = "AddFieldInternalNameHint",
        [switch]$EnableException
    )
    begin {
        if (-not $DisplayName) {
            $DisplayName = $ColumnName
        }
        $addtodefaultlist = $DoNotAddToDefaultView -eq $false
    }
    process {
        if (-not $InputObject) {
            if ($Uri) {
                $InputObject = Get-SPRList -Uri $Uri -Credential $Credential -ListName $ListName
            }
            elseif ($global:server) {
                $InputObject = $global:server | Get-SPRList -ListName $ListName
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Uri and ListName pipe in results from Get-SPRList"
                return
            }
        }
        
        foreach ($list in $InputObject) {
            try {
                $server = $list.Context
                $server.Load($list.Fields)
                $server.ExecuteQuery()
                if (-not $Xml) {
                    $xml = "<Field Type='$Type' Name='$ColumnName' StaticName='$ColumnName' DisplayName='$DisplayName' Description ='$Description'  />"
                }
                Write-PSFMessage -Level Verbose -Message $xml
                if ($Default) {
                    $xml = $xml.Replace(" />", "><Default>$Default</Default></Field>")
                }
                Write-PSFMessage -Level Verbose -Message "Adding $ColumnName as $Type"
                $field = $list.Fields.AddFieldAsXml($xml, $addtodefaultlist, $FieldOption)
                $list.Update()
                $server.Load($list)
                $server.ExecuteQuery()
                $list.Update()
                $server.ExecuteQuery()
                
                $list | Get-SPRColumnDetail | Where-Object Name -eq $ColumnName | Sort-Object guid -Descending | Select-Object -First 1
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                return
            }
        }
    }
}