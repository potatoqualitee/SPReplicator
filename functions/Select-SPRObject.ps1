function Select-SPRObject {
    <#
.SYNOPSIS
    Makes it easier to alias columns to select and rename for export.
    
.DESCRIPTION
    Makes it easier to alias columns to select and rename for export.
    
    A lot of this is from boe, thanks boe!
    https://learn-powershell.net/2013/08/03/quick-hits-set-the-default-property-display-in-powershell-on-custom-objects/

.PARAMETER InputObject
    Allows piping
 
.PARAMETER TypeName
    TypeName creates a new type so that we can use ps1xml to modify the output
    
.PARAMETER Property
    Only includes specific properties
    
.PARAMETER ExcludeProperty
    Excludes other properties
    
.EXAMPLE
    Get-SPRListItem -Site intranet.ad.local -List 'My List' | Select-SPRObject -Property 'Title as FullName', Created
    
    Returns two visible columns, Name and Created. Name is an alias of Title.

.EXAMPLE
    Get-SPRListItem -Site intranet.ad.local -List 'My List' | Select-SPRObject -Property 'Title as FullName', Created | Export-SPRObject -Path C:\temp\items.xml
    
    Returns two visible columns, Name and Created. Name is an alias of FullName.
    
    Then, an object is exported with only the columns Name and Created

#>    
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,
        [string[]]$Property,
        [string[]]$ExcludeProperty,
        [string]$TypeName
    )
    process {
        foreach ($object in $InputObject) {
            if ($TypeName) {
                $object.PSObject.TypeNames.Insert(0, "spreplicator.$TypeName")
            }
            
            if ($ExcludeProperty) {
                if ($object.GetType().Name.ToString() -eq 'DataRow') {
                    $ExcludeProperty += 'Item', 'RowError', 'RowState', 'Table', 'ItemArray', 'HasErrors'
                }
                
                $props = ($object | Get-Member | Where-Object MemberType -in 'Property', 'NoteProperty', 'AliasProperty' | Where-Object { $_.Name -notin $ExcludeProperty }).Name
                $defaultset = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]$props)
            }
            else {
                # property needs to be string
                if ("$property" -like "* as *") {
                    $props = @()
                    foreach ($p in $property) {
                        if ($p -like "* as *") {
                            $old, $new = $p -isplit " as "
                            # Do not be tempted to not pipe here
                            $object | Add-Member -Force -MemberType AliasProperty -Name $new -Value $old -ErrorAction SilentlyContinue
                            $props += $new
                        }
                        else {
                            $props += $p
                        }
                    }
                }
                else {
                    $props = $Property
                }
                $defaultset = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]$props)
            }
            Select-Object -InputObject $object -Property $props
        }
    }
}