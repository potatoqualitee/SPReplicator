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