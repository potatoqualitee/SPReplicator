$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = (Invoke-Expression (Get-Content "$ModuleRoot\SPReplicator.psd1" -Raw)).ModuleVersion
function Join-SprPath {
    <#
    .SYNOPSIS
        Performs multisegment path joins.

    .DESCRIPTION
        Performs multisegment path joins.

    .PARAMETER Path
        The basepath to join on.

    .PARAMETER SqlInstance
        Optional -- tests to see if destination SQL Server is Linux or Windows

    .PARAMETER Child
        Any number of child paths to add.

    .EXAMPLE
        PS C:\> Join-SprPath -Path 'C:\temp' 'Foo' 'Bar'

        Returns 'C:\temp\Foo\Bar' on windows.
        Returns 'C:/temp/Foo/Bar' on non-windows.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        [Parameter(ValueFromRemainingArguments)]
        [Alias("ChildPath")]
        [string[]]$Child
    )
    return @($path) + $Child -join
    [IO.Path]::DirectorySeparatorChar -replace
    '\\|/', [IO.Path]::DirectorySeparatorChar
}
function Import-ModuleFile {
    <#
		.SYNOPSIS
			Loads files into the module on module import.

		.DESCRIPTION
			This helper function is used during module initialization.
			It should always be dotsourced itself, in order to proper function.

			This provides a central location to react to files being imported, if later desired

		.PARAMETER Path
			The path to the file to load

		.EXAMPLE
			PS C:\> . Import-ModuleFile -File $function.FullName

			Imports the file stored in $function according to import policy
	#>
    [CmdletBinding()]
    Param (
        [string]
        $Path
    )

    if ($doDotSource) { . $Path }
    else { $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($Path))), $null, $null) }
}

# Detect whether at some level dotsourcing was enforced
$script:doDotSource = Get-PSFConfigValue -FullName SPReplicator.Import.DoDotSource -Fallback $false
if ($SPReplicator_dotsourcemodule) { $script:doDotSource = $true }

# Execute Preimport actions
. Import-ModuleFile -Path (Join-SprPath $ModuleRoot internal scripts preimport.ps1)

# Import all internal functions
foreach ($function in (Get-ChildItem "$ModuleRoot\internal\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $function.FullName
}

# Import all public functions
foreach ($function in (Get-ChildItem "$ModuleRoot\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $function.FullName
}

# Execute Postimport actions
. Import-ModuleFile -Path (Join-SprPath $ModuleRoot internal scripts postimport.ps1)

# Those remain in the psm1 in order for it to be easily available from PowerShell Studio completion
$script:spweb = $global:SPReplicator.Web
$script:spsite = $global:SPReplicator.Site
if ($global:SPReplicator.LogList) {	$global:SPReplicator.LogList | Set-SPRLogList }

$global:SPReplicator = [pscustomobject]@{
    Web       = $script:spweb
    Site      = $script:spsite
    LogList   = $global:SPReplicator.LogList
    ListNames = $global:SPReplicator.ListNames
    UserCache = @{ }
}