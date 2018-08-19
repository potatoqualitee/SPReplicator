Function Copy-SPRFile {
<#
.SYNOPSIS
    Quickly copies import and export files using either robocopy or Start-BitsTransfer.

.DESCRIPTION
    Quickly copies import and export files using either robocopy or Start-BitsTransfer.

.PARAMETER Path
    Path to the file(s) to copy.
    
.PARAMETER Destination
    Path to the destination.

.PARAMETER Method
    The method for copying files. Uses RoboCopy by default. The other option is BitsTransfer.
    
    You can read more about Bits here: https://docs.microsoft.com/en-us/windows/desktop/bits/background-intelligent-transfer-service-portal
  
.PARAMETER Credential
    Provide alternative credentials to the destination location.
    
.PARAMETER InputObject
    Allows piping from Export-SPRListItem and Get-ChildItem
  
.PARAMETER WhatIf
    If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

.PARAMETER Confirm
    If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
 
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Export-SPRListItem -List MyList -Path C:\temp\mylist.dat | Copy-SPRFile -Destination \\nas\dropoff

    Exports a list to a file then copies it to \\nas\dropoff using robocopy
    
.EXAMPLE
    Export-SPRListItem -List MyList -Path C:\temp\mylist.dat | Copy-SPRFile -Destination \\nas\dropoff -Credential ad\user -Method BitsTransfer

    Exports a list to a file then copies it using Start-BitsTransfer to \\nas\dropoff with the credential ad\user
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string[]]$Path,
        [parameter(Mandatory)]
        [string[]]$Destination,
        [Validateset("Robocopy", "BitsTransfer")]
        [string]$Method = "Robocopy",
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [System.IO.FileInfo[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Path) {
                try {
                    $InputObject = Get-ChildItem -Path $Path -ErrorAction Stop
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                    return
                }
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Path pipe in the results of Get-ChildItem"
                return
            }
        }
        foreach ($file in $InputObject) {
            if ((Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target "$Destination" -Action "Copying $file using $Method")) {
                try {
                    if ($Method -eq 'Robocopy') {
                        if ($file -is [System.IO.DirectoryInfo]) {
                            Invoke-Command2 -Raw -Credential $Credential -ScriptBlock {
                                Invoke-RoboCopy -Path $file -Destination $Destination
                                Get-ChildItem $Destination -ErrorAction Stop
                            }
                        }
                        else {
                            Invoke-Command2 -Raw -Credential $Credential -ScriptBlock {
                                $leaf = Split-Path $file -Leaf
                                $dir = Split-Path $file
                                Invoke-RoboCopy -Path $dir -Destination $Destination -ArgumentList $leaf
                                Get-ChildItem "$Destination\$leaf" -ErrorAction Stop
                            }
                        }
                    }
                    elseif ($Method -eq "BitsTransfer") {
                        Invoke-Command2 -Raw -Credential $Credential -ScriptBlock {
                            Start-BitsTransfer -Source $file -Destination $Destination -ErrorAction Stop
                        }
                        $leaf = Split-Path $file -Leaf
                        $dir = Split-Path $file
                        Get-ChildItem "$Destination\$leaf" -ErrorAction Stop
                    }
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}