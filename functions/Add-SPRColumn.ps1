Function Add-SPRColumn {
<#
.SYNOPSIS
    Adds a column to a SharePoint list.

.DESCRIPTION
    Adds a column to a SharePoint list.

.PARAMETER Uri
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Uri or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER ListName
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.

.PARAMETER ColumnName
    The column name.

.PARAMETER DisplayName
    The column display name.

.PARAMETER Type
   The column datatype.

 .PARAMETER Description
    The column description.

 .PARAMETER Xml
    This commands builds up the XML for AddFieldAsXml. If you want to override that and just pass
    an xml command, use this parameter.

    See this site for examples: https://karinebosch.wordpress.com/my-articles/creating-fields-using-csom/

 .PARAMETER Default
    Sets the default value of the column.

.PARAMETER DoNotAddToDefaultView
    By default, the newly added column will be added to the default view. Use this parameter
    to prevent this.

.PARAMETER FieldOption
    The Field Options for the column. This parameter has auto-complete for your convenience.

.PARAMETER InputObject
    Allows piping from Get-SPRList

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Connect-SPRSite -Uri intranet.ad.local
    Add-SPRColumn -ListName 'My List' -ColumnName TestColumn -Description "One column"

    Adds a text column named TestColumn to 'My List' on intranet.ad.local

.EXAMPLE
    Add-SPRColumn -Uri intranet.ad.local -ListName 'My List' -Credential (Get-Credential ad\user) -ColumnName TestColumn

    Adds a text column named TestColumn to 'My List' on intranet.ad.local and logs into the site collection as ad\user.

.EXAMPLE
    Add-SPRColumn -Uri intranet.ad.local -ListName List1 -ColumnName Age -Default 40 -Type Integer

    Adds a number column named Age to List1 on intranet.ad.local and sets the default value to 40s.

.EXAMPLE
    $xml = "<Field Type='URL' Name='EmployeePicture' StaticName='EmployeePicture' DisplayName='Employee Picture' Format='Image'/>"
    Get-SPRList -ListName List1 -Uri intranet.ad.local | Add-SPRColumn -Xml $xml

    Adds a column named EmployeePicture with the URL datatype to List1 on intranet.ad.local
#>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Uri,
        [PSCredential]$Credential,
        [Parameter(HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [string]$ColumnName,
        [string]$DisplayName,
        [string]$Type = "Text",
        [string]$Description,
        [string]$Xml,
        [string]$Default,
        [switch]$DoNotAddToDefaultView,
        [ValidateSet("DefaultValue", "AddToDefaultContentType", "AddToNoContentType", "AddToAllContentTypes", "AddFieldInternalNameHint", "AddFieldToDefaultView", "AddFieldCheckDisplayName")]
        [string[]]$FieldOption = "AddFieldInternalNameHint",
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    begin {
        if (-not $DisplayName) {
            $DisplayName = $ColumnName
        }
        $addtodefaultlist = $DoNotAddToDefaultView -eq $false
    }
    process {
        if (-not $ColumnName -and -not $Xml) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You must specify ColumnName or Xml"
            return
        }
        if ($Xml -and $Default) {
            Stop-PSFFunction -EnableException:$EnableException -Message "You cannot specify Xml and Default. Add the default to the Xml instead."
            return
        }
        if (-not $InputObject) {
            if ($Uri) {
                $InputObject = Get-SPRList -Uri $Uri -Credential $Credential -ListName $ListName
            }
            elseif ($global:spsite) {
                $InputObject = $global:spsite | Get-SPRList -ListName $ListName
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
                    if ($Default) {
                        $xml = $xml.Replace(" />", "><Default>$Default</Default></Field>")
                    }
                }
                if (-not $ColumnName) {
                    $xmldata = [xml]($xml.ToString())
                    $ColumnName = $xmldata.Field.Name
                }
                Write-PSFMessage -Level Verbose -Message $xml
                Write-PSFMessage -Level Verbose -Message "Added $ColumnName as $Type"
                $field = $list.Fields.AddFieldAsXml($xml, $addtodefaultlist, $FieldOption)
                $list.Update()
                $server.Load($list)
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