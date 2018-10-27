function Save-SPLibrary {
    <#
		.SYNOPSIS
		Saves the contents of a specified SharePoint library to disk

		.DESCRIPTION
		This function takes a SharePoint library object and calls the Save-SPFile function to save the contents of the library to disk. The recurse switch will include all subfolders and files

		.PARAMETER Folder
		SharePoint Library(folder) object.

		.PARAMETER Path
		Output location for exporting files and folders

		.PARAMETER Recurse
		Switch to iterate through all subfolders of the provided library(folder)

		.EXAMPLE
		Save-SPLibrary -Folder $folder -Path "C:\SharePointOutput\" -Recurse

		.LINK
		Export-SPLibrary

		.LINK
		Save-SPFile
	#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [psObject]
        $Folder,
        [Parameter(Mandatory = $true)]
        [string]
        $Path,
        [switch]
        $Recurse
    )

    #Target directory
    $directory = Join-Path $Path $Folder.Name
    #Forms folder is not wanted.
    if ($Folder.Name -eq 'Forms') {
        return
    }
    #Logging Array
    $spLog = @()

    if ($Folder.Files.Count -gt 0 -or $Folder.SubFolders.Count -gt 0) {
        #Only creating directories that contain files or subfolders
        mkdir $directory | Out-Null

        foreach ($file in $Folder.Files) {
            #Saving file to directory
            $localName = Save-SPFile $file $directory

            Write-Verbose "Adding to log."
            $spArray = @()
            $spArray += New-Object PSObject -Property @{
                FileName       = "$($file.Name)"
                SPRelativeUrl  = "$($file.ServerRelativeUrl)"
                SPParentFolder = "$($file.ParentFolder)"
                LocalFileName  = "$($localName)"
                LastModified   = "$($file.TimeLastModified)"
		        ModifiedBy     = "$($file.ModifiedBy)"
            }
            $spLog += $spArray
        }
        if ($Recurse) {
            $Folder.Subfolders | Foreach-Object { Save-SPLibrary $_ $directory -Recurse }
        }
    }
    return $spLog
}