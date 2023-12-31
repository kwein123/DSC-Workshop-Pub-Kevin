﻿@{

# Script module or binary module file associated with this manifest.
RootModule = 'Chocolatey.psm1'

# Version number of this module.
ModuleVersion = '0.0.79'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'f66a6bf1-29d4-4a00-b625-32434d0dd4cd'

# Author of this module
Author = 'Gael Colas'

# Company or vendor of this module
CompanyName = 'SynEdgy Limited'

# Copyright statement for this module
Copyright = '(c) 2017 Gael Colas. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This is an unofficial module with DSC resource to Install and configure Chocolatey.'

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
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @('Add-ChocolateyPin','Compare-SemVerVersion','Disable-ChocolateyFeature','Disable-ChocolateySource','Enable-ChocolateyFeature','Enable-ChocolateySource','Get-ChocolateyDefaultArgument','Get-ChocolateyFeature','Get-ChocolateyPackage','Get-ChocolateyPin','Get-ChocolateySetting','Get-ChocolateySource','Get-ChocolateyVersion','Get-Downloader','Get-RemoteFile','Get-RemoteString','Get-SemVerFromString','Install-ChocolateyPackage','Install-ChocolateySoftware','Register-ChocolateySource','Remove-ChocolateyPin','Repair-PowerShellOutputRedirectionBug','Set-ChocolateySetting','Test-ChocolateyFeature','Test-ChocolateyInstall','Test-ChocolateyPackageIsInstalled','Test-ChocolateyPin','Test-ChocolateySetting','Test-ChocolateySource','Uninstall-Chocolatey','Uninstall-ChocolateyPackage','Unregister-ChocolateySource','Update-ChocolateyPackage')

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
DscResourcesToExport = @('ChocolateySoftware','ChocolateyPackage','ChocolateyFeature','ChocolateySource','ChocolateyPin')

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Chocolatey','DSC')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/gaelcolas/Chocolatey/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/gaelcolas/Chocolatey'

        # A URL to an icon representing this module.
        IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'This is an unofficial (beta) release of a Chocolatey module and DSC resource.'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
