@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'SPReplicator.psm1'

    # Version number of this module.
    ModuleVersion     = '0.0.35'

    # ID used to uniquely identify this module
    GUID              = 'e8af347b-2f8c-4cbb-b36d-33aed803b259'

    # Author of this module
    Author            = 'Chrissy LeMaire'

    # Copyright statement for this module
    Copyright         = '(c) 2021 Chrissy LeMaire All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'SPReplicator helps replicate SharePoint list data from CSV, SQL Server, generic PowerShell objects, and other SharePoint lists.'

    # Minimum version of the Windows PowerShell engine required by this module
    # PowerShellVersion = ''

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @(
        @{ ModuleName = 'PSFramework'; ModuleVersion = '0.9.25.107' },
        @{ ModuleName = 'PnP.PowerShell'; ModuleVersion = '1.7.0' }
    )

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess    = @("xml\SPReplicator.Types.ps1xml")

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Add-SPRColumn',
        'Add-SPRListItem',
        'Add-SPRListItemFile',
        'Add-SPRUser',
        'Clear-SPRListItems',
        'Connect-SPRSite',
        'Copy-SPRFile',
        'Copy-SPRListItemFile',
        'Disconnect-SPRSite',
        'Export-SPRListItem',
        'Get-SPRColumnDetail',
        'Get-SPRConfig',
        'Get-SPRConnectedSite',
        'Get-SPRContentType',
        'Get-SPRContentTypeField',
        'Get-SPRList',
        'Get-SPRListFolder',
        'Get-SPRListItem',
        'Get-SPRListTemplate',
        'Get-SPRListView',
        'Get-SPRLogList',
        'Get-SPRUser',
        'Get-SPRUserProfile',
        'Get-SPRWeb',
        'Import-SPRListItem',
        'Invoke-SPRWebRequest',
        'New-SPRList',
        'New-SPRListFolder',
        'New-SPRLogList',
        'Remove-SPRList',
        'Remove-SPRListFolder',
        'Remove-SPRListItem',
        'Remove-SPRListTemplate',
        'Remove-SPRUser',
        'Reset-SPRConfig',
        'Select-SPRObject',
        'Set-SPRConfig',
        'Set-SPRListFieldValue',
        'Set-SPRLogList',
        'Set-SPRUserPropertyValue',
        'Update-SPRListItem',
        'Update-SPRListItemAuthorEditor'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags       = @('SharePoint', 'data', 'replication', 'SQLServer', 'CSV', 'import', 'export')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/potatoqualitee/SPReplicator/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/potatoqualitee/SPReplicator'

            # A URL to an icon representing this module.
            IconUri    = 'https://user-images.githubusercontent.com/8278033/42554599-39b769a6-8481-11e8-8b6a-379f4a3e54e6.png'

            # ReleaseNotes of this module
            # ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

}