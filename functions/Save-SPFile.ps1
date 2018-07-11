function Save-SPFile {
    <#
		.SYNOPSIS
		Saves a specified document in SharePoint to disk

		.DESCRIPTION
		This function takes a SharePoint file object and saves a copy to disk. It is fed from the Export-SPLibrary function

		.PARAMETER File
		SharePoint File object.

		.PARAMETER Path
		Output path to save file to

		.EXAMPLE
		Save-SPFile -File $file -Path "C:\SharePointOutput\"

		.LINK
		Export-SPLibrary

		.LINK
		Save-SPLibrary
	#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [psObject]
        $File,
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    $data = $File.OpenBinary()
    $Path = Join-Path $Path $File.Name
    # progress $path
    try {
        [System.IO.File]::WriteAllBytes($Path, $data) 
        Write-Verbose "$($File.Name) saved to disk: $Path"
        #TODO Can we update the file properties?
    }
    catch {
        throw (New-Object System.Exception("Exception occurred while exporting file $($File.Name) to disk $Path! $($_.Exception.Message)", $_.Exception))
    }   
    return $Path
}