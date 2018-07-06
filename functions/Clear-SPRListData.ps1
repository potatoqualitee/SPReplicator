Function Clear-SPRListData {   
<#
.SYNOPSIS
    Deletes all items from a SharePoint list using a Web service proxy object.
    
.DESCRIPTION
     Deletes all items from a SharePoint list using a Web service proxy object.
    
.PARAMETER Uri
    The address to the web application. You can also pass a hostname and it'll figure it out.

.PARAMETER ListName
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.
   
.PARAMETER Credential
    Provide alternative credentials to the web service. Otherwise, it will use default credentials. 
 
.PARAMETER IntputObject
    Allows piping from Get-SPRList or Get-SPRListData
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
 
.PARAMETER WhatIf
    If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

.PARAMETER Confirm
    If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

.EXAMPLE
    Clear-SPRListData -Uri intranet.ad.local -ListName 'My List'

    Deletes all items from My List on intranet.ad.local. Prompts for confirmation.
    
.EXAMPLE
    Get-SPRList -ListName 'My List' -Uri intranet.ad.local | Clear-SPRListData -Confirm:$false

     Deletes all items from My List on intranet.ad.local. Does not prompt for confirmation.
    
.EXAMPLE
    Get-SPRListData -Uri intranet.ad.local -ListName 'My List' -Credential (Get-Credential ad\user) | Clear-SPRListData -Confirm:$false

    Deletes all items from My List by logging into the webapp as ad\user.
    
.EXAMPLE
    Clear-SPRListData -Uri intranet.ad.local -ListName 'My List'
    
    No actions are performed but informational messages will be displayed about the items that would be deleted from the My List list.
#>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(HelpMessage = "SharePoint lists.asmx?wsdl location")]
        [string]$Uri,
        [Parameter(HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    begin {
        $xml = @()
    }
    process {
        if (-not $InputObject) {
            if ($Uri -and $ListName) {
                $InputObject = Get-SPRListData -Uri $Uri -Credential $Credential -ListName $ListName
            }
            else {
                Stop-PSFFunction -Message "You must specify Uri and ListName or pipe in the results of Get-SPRService"
                return
            }
        }
        
        if (-not $InputObject[0].ows_ID) {
            $InputObject = $InputObject | Get-SPRListData
        }
        
        foreach ($list in $InputObject) {
            $service = $list.Service
            $batchelement = $list.BatchElement
            
            if (-not $listname) {
                if ($list.ListName) {
                    $listname = $list.ListName
                }
                else {
                    Stop-PSFFunction -Message "Invalid list data"
                    return
                }
            }
            
            foreach ($item in $list) {
                $id = $item.ows_ID
                if ($Pscmdlet.ShouldProcess($listname, "Deleting item with id $id")) {
                    $xml += "<Method ID='$Id' Cmd='Delete'><Field Name='ID'>$Id</Field></Method>"
                }
            }
        }
    }
    end {
        if (-not $list) {
            Stop-PSFFunction -Message "No records to delete"
        }
        else {
        $list.BatchElement.InnerXml = $xml -join ""
            
            if ($Pscmdlet.ShouldProcess($listname, "Removing batch")) {
                try {
                    # Do batch
                    $results = ($list.Service.UpdateListItems($listName, $list.BatchElement)).Result
                    Invoke-ParseResultSet -ResultSet $results
                }
                catch {
                    Stop-PSFFunction -Message "Failure" -ErrorRecord $_
                }
            }
        }
    }
}