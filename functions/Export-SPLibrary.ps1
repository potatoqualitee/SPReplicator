
function Export-SPLibrary {
    <#
		.SYNOPSIS
		Copy the contents of a SharePoint document library to disk

		.DESCRIPTION
		This function copies all files from within the chosen SharePoint libraries to a folder. Use of the -Recurse switch will also include all subfolders and their contents

		.PARAMETER Url
		URL of the SharePoint site 

		.PARAMETER Path
		Output location for exporting files and folders

		.PARAMETER Library
		This is the name of the SharePoint libraries to be exported. This should be their name and NOT their title
		
		.PARAMETER Recurse
		Switch to iterate through all subfolders of the provided library/Libraries

		.EXAMPLE
		Export-SPLibrary -Url https://SharePointURL/Sites/SiteName -Path "C:\SharePointDocuments\Output" -Library "Library1","Library2"

		.EXAMPLE
		Export-SPLibrary -Url https://SharePointURL/Sites/SiteName -Path "C:\SharePointDocuments\Output" -Library "Library1","Library2" -Recurse -Verbose

		.NOTES
			Author: Craig Porteous
			Created: July 2018
			Based on script written by Anatoly Mironov
			https://github.com/mirontoli/sp-lend-id/blob/master/aran-aran/Pull-Documents.ps1
	#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    Param(
        [Parameter(Mandatory = $true)]
        [string]
        $Url,
        [Parameter(Mandatory = $true)]
        [ValidateScript( {Test-Path -Path $_})]
        [string]
        $Path,
        [Parameter(Mandatory = $true)]
        [String[]]
        $Library,
        [switch]
        $Recurse
    )

    #TODO Work around the need for SharePoint files
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

    Write-Verbose "Connecting to SP Site to retrieve Web"
    $site = new-object microsoft.sharepoint.spsite($Url)
    $web = $site.OpenWeb()
    $site.Dispose()

    for ($i = 0; $i -lt $Library.Length; $i++) {
        if (!$web.GetFolder($Library[$i])) {			
            #TODO Test against libraries in site
            Write-Error "The '$Library[$i]' library cannot be found"
            $web.Dispose()
            return
        }
        else {
            Write-Verbose "Retrieving library:$($Library[$i]) from SharePoint"
            $folder = $web.GetFolder($Library[$i])

            # Create local path
            $rootDirectory = $Path
            $directory = Join-Path $Path $folder.Name

            if (Test-Path $directory) {
                #TODO Put in an Overwrite option here 
                Write-Error "The folder $Library in the current directory already exists, please remove it"
                $web.Dispose()
                return
            }
            else {
                $fileArray = @()

                #TODO Add file count - # $fileCount = Get-SPFileCount $folder
                if ($PSCmdlet.ShouldProcess($folder, "Copying documents to disk")) {
                    try {
                        if ($Recurse) {
                            Write-Verbose "Saving files from $($folder.Name) and subfolders to $directory"
                            $fileArray = Save-SPLibrary $folder $rootDirectory -Recurse 
                            $fileArray | Export-Csv -Path "$($rootDirectory)\$($folder.Name).csv" -NoTypeInformation
                        }
                        else {					
                            Write-Verbose "Saving files from $($folder.Name) to $directory"
                            $fileArray = Save-SPLibrary $folder $rootDirectory
                            $fileArray | Export-Csv -Path "$($rootDirectory)\$($folder.Name).csv" -NoTypeInformation
						}
					}
					catch
					{
						throw (New-Object System.Exception("Exception occurred while exporting contents of $($folder.Name) to $directory! $($_.Exception.Message)", $_.Exception))
					}                    
                }
            }
            $web.Dispose()
        }
	}
}