<#
.SYNOPSIS
    Compares two versions and find whether they're equal, or one is newer than the other.

.DESCRIPTION
    The Compare-SemVerVersion allows the comparison of SemVer 2.0 versions (including prerelease identifiers)
    as documented on semver.org
    The result will be = if the versions are equivalent, > if the reference version takes precedence, or < if the
    difference version wins.

.PARAMETER ReferenceVersion
    The string version you would like to test.

.PARAMETER DifferenceVersion
    The other string version you would like to compare agains the reference.

.EXAMPLE
    Compare-SemVerVersion -ReferenceVersion '0.2.3.546-alpha.201+01012018' -DifferenceVersion '0.2.3.546-alpha.200'
    # >
    Compare-SemVerVersion -ReferenceVersion '0.2.3.546-alpha.201+01012018' -DifferenceVersion '0.2.3.546-alpha.202'
    # <

.EXAMPLE
    Compare-SemVerVersion -ReferenceVersion '0.2.3.546-alpha.201+01012018' -DifferenceVersion '0.2.3.546-alpha.201+01012015'
    # =

.NOTES
    Worth noting that the documentaion of SemVer versions should follow this logic (from semver.org)
    1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0.
#>
function Compare-SemVerVersion {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(
            Mandatory
        )]
        [System.String]
        $ReferenceVersion,

        [System.String]
        $DifferenceVersion
    )

    $refVersion = Get-SemVerFromString -VersionString $ReferenceVersion -ErrorAction Stop
    $diffVersion = Get-SemVerFromString -VersionString $DifferenceVersion -ErrorAction Stop

    # Compare Version first
    if ($refVersion.Version -eq $diffVersion.Version) {
        if (!$refVersion.Prerelease -and $diffVersion.Prerelease) {
            '>'
        }
        elseif ($refVersion.Prerelease -and !$diffVersion.Prerelease) {
            '<'
        }
        elseif (!$diffVersion.Prerelease -and !$refVersion.Prerelease) {
            '='
        }
        elseif ($refVersion.Prerelease -eq $diffVersion.Prerelease) {
            '='
        }
        else {
            $resultSoFar = '='

            foreach ($index in 0..($refVersion.PrereleaseArray.count - 1)) {
                $refId = ($refVersion.PrereleaseArray[$index] -as [uint64])
                $diffId = ($diffVersion.PrereleaseArray[$index] -as [uint64])
                if ($refId -and $diffId) {
                    if ($refid -gt $diffId) { return '>'}
                    elseif ($refId -lt $diffId) { return '<'}
                    else {
                        Write-Debug "Ref identifier at index = $index are equals, moving onto next"
                    }
                }
                else {
                    $refId = [char[]]$refVersion.PrereleaseArray[$index]
                    $diffId = [char[]]$diffVersion.PrereleaseArray[$index]
                    foreach ($charIndex in 0..($refId.Count - 1)) {
                        if ([int]$refId[$charIndex] -gt [int]$diffId[$charIndex]) {
                            return '>'
                        }
                        elseif ([int]$refId[$charIndex] -lt [int]$diffId[$charIndex]) {
                            return '<'
                        }

                        if ($refId.count -eq $charIndex + 1 -and $refId.count -lt $diffId.count) {
                            return '>'
                        }
                        elseif ($diffId.count -eq $index + 1 -and $refId.count -gt $diffId.count) {
                            return '<'
                        }
                    }
                }

                if ($refVersion.PrereleaseArray.count -eq $index + 1 -and $refVersion.PrereleaseArray.count -lt $diffVersion.PrereleaseArray.count) {
                    return '<'
                }
                elseif ($diffVersion.PrereleaseArray.count -eq $index + 1 -and $refVersion.PrereleaseArray.count -gt $diffVersion.PrereleaseArray.count) {
                    return '>'
                }
            }
            return $resultSoFar
        }
    }
    elseif ($refVersion.Version -gt $diffVersion.Version) {
        '>'
    }
    else {
        '<'
    }
}

<#
.SYNOPSIS
Transforms parameters Key/value into choco.exe Parameters.

.DESCRIPTION
This private command allows to pass parameters and it returns
an array of parameters to be used with the choco.exe command.
No validation is done at this level, it should be handled
by the Commands leveraging this function.

.PARAMETER Name
Name of the element being targeted (can be source, feature, package and so on).

.PARAMETER Value
The value of the config setting. Required with some Actions.
Defaults to empty.

.PARAMETER Source
Source uri (whether local or remote)

.PARAMETER Disabled
Specify whethere the element targeted should be disabled or enabled (by default).

.PARAMETER BypassProxy
Bypass the proxy for fetching packages on a feed.

.PARAMETER SelfService
Specify if the source is, can or should be used for self service.

.PARAMETER NotBroken
Filter out the packages that are reported broken.

.PARAMETER AllVersions
List all version available.

.PARAMETER Priority
Priority of the feed, default to 0

.PARAMETER Credential
Credential to authenticate to the source feed.

.PARAMETER ProxyCredential
Credential for the Proxy.

.PARAMETER Force
Force the action being targeted.

.PARAMETER CacheLocation
Location where the download will be cached.

.PARAMETER InstallArguments
Arguments to pass to the Installer (Not Package args)

.PARAMETER InstallArgumentsSensitive
Arguments to pass to the Installer that should be obfuscated from log and output.

.PARAMETER PackageParameters
PackageParameters - Parameters to pass to the package, that should be handled by the ChocolateyInstall.ps1

.PARAMETER PackageParametersSensitive
Arguments to pass to the Package that should be obfuscated from log and output.

.PARAMETER OverrideArguments
Should install arguments be used exclusively without appending to current package passed arguments

.PARAMETER NotSilent
    Do not install this silently. Defaults to false.

.PARAMETER ApplyArgsToDependencies
    Apply Install Arguments To Dependencies  - Should install arguments be
    applied to dependent packages? Defaults to false

.PARAMETER AllowDowngrade
    Should an attempt at downgrading be allowed? Defaults to false.

.PARAMETER SideBySide
    AllowMultipleVersions - Should multiple versions of a package be installed?

.PARAMETER IgnoreDependencies
    IgnoreDependencies - Ignore dependencies when installing package(s).

.PARAMETER NoProgress
    Do Not Show Progress - Do not show download progress percentages

.PARAMETER ForceDependencies
    Force dependencies to be reinstalled when force
    installing package(s). Must be used in conjunction with --force.
    Defaults to false.

.PARAMETER SkipPowerShell
    Skip Powershell - Do not run chocolateyInstall.ps1. Defaults to false.

.PARAMETER IgnoreChecksum
    IgnoreChecksums - Ignore checksums provided by the package. Overrides
    the default feature 'checksumFiles' set to 'True'.

.PARAMETER AllowEmptyChecksum
    Allow Empty Checksums - Allow packages to have empty/missing checksums
    for downloaded resources from non-secure locations (HTTP, FTP). Use this
    switch is not recommended if using sources that download resources from
    the internet. Overrides the default feature 'allowEmptyChecksums' set to
    'False'. Available in 0.10.0+.

.PARAMETER ignorePackageCodes
    IgnorePackageExitCodes - Exit with a 0 for success and 1 for non-success,
    no matter what package scripts provide for exit codes. Overrides the
    default feature 'usePackageExitCodes' set to 'True'. Available in 0.-
    9.10+.

.PARAMETER UsePackageCodes
    UsePackageExitCodes - Package scripts can provide exit codes. Use those
    for choco's exit code when non-zero (this value can come from a
    dependency package). Chocolatey defines valid exit codes as 0, 1605,
    1614, 1641, 3010.  Overrides the default feature 'usePackageExitCodes'
    set to 'True'. Available in 0.9.10+.

.PARAMETER StopOnFirstFailure
    Stop On First Package Failure - stop running install, upgrade or
    uninstall on first package failure instead of continuing with others.
    Overrides the default feature 'stopOnFirstPackageFailure' set to 'False-
    '. Available in 0.10.4+.

.PARAMETER SkipCache
    Skip Download Cache - Use the original download even if a private CDN
    cache is available for a package. Overrides the default feature
    'downloadCache' set to 'True'. Available in 0.9.10+. [Licensed editions](https://chocolatey.org/compare)
    only. See https://chocolatey.org/docs/features-private-cdn

.PARAMETER UseDownloadCache
    Use Download Cache - Use private CDN cache if available for a package.
    Overrides the default feature 'downloadCache' set to 'True'. Available
    in 0.9.10+. [Licensed editions](https://chocolatey.org/compare) only. See https://chocolate-
    y.org/docs/features-private-cdn

.PARAMETER SkipVirusCheck
    Skip Virus Check - Skip the virus check for downloaded files on this run.
    Overrides the default feature 'virusCheck' set to 'True'. Available
    in 0.9.10+. [Licensed editions](https://chocolatey.org/compare) only.
    See https://chocolatey.org/docs/features-virus-check

.PARAMETER VirusCheck
    Virus Check - check downloaded files for viruses. Overrides the default
    feature 'virusCheck' set to 'True'. Available in 0.9.10+. Licensed
    editions only. See https://chocolatey.org/docs/features-virus-check

.PARAMETER VirusPositive
    Virus Check Minimum Scan Result Positives - the minimum number of scan
    result positives required to flag a package. Used when virusScannerType
    is VirusTotal. Overrides the default configuration value
    'virusCheckMinimumPositives' set to '5'. Available in 0.9.10+. Licensed
    editions only. See https://chocolatey.org/docs/features-virus-check

.PARAMETER OrderByPopularity
    Order the community packages (chocolatey.org) by popularity.

.PARAMETER Version
    Version - A specific version to install. Defaults to unspecified.

.PARAMETER LocalOnly
    LocalOnly - Only search against local machine items.

.PARAMETER IdOnly
    Id Only - Only return Package Ids in the list results. Available in 0.10.6+.

.PARAMETER Prerelease
    Prerelease - Include Prereleases? Defaults to false.

.PARAMETER ApprovedOnly
    ApprovedOnly - Only return approved packages - this option will filter
    out results not from the [community repository](https://chocolatey.org/packages). Available in 0.9.10+.

.PARAMETER IncludePrograms
    IncludePrograms - Used in conjunction with LocalOnly, filters out apps
    chocolatey has listed as packages and includes those in the list.
    Defaults to false.

.PARAMETER ByIdOnly
    ByIdOnly - Only return packages where the id contains the search filter.
    Available in 0.9.10+.

.PARAMETER IdStartsWith
    IdStartsWith - Only return packages where the id starts with the search
    filter. Available in 0.9.10+.

.PARAMETER Exact
    Exact - Only return packages with this exact name. Available in 0.9.10+.

.PARAMETER x86
    Force the x86 packages on x64 machines.

.PARAMETER AcceptLicense
    AcceptLicense - Accept license dialogs automatically.
    Reserved for future use.

.PARAMETER Timeout
    CommandExecutionTimeout (in seconds) - The time to allow a command to
    finish before timing out. Overrides the default execution timeout in the
    configuration of 2700 seconds. '0' for infinite starting in 0.10.4.

.PARAMETER UseRememberedArguments
    Use Remembered Options for Upgrade - use the arguments and options used
    during install for upgrade. Does not override arguments being passed at
    runtime. Overrides the default feature
    'useRememberedArgumentsForUpgrades' set to 'False'. Available in 0.10.4+.

.PARAMETER IgnoreRememberedArguments
    Ignore Remembered Options for Upgrade - ignore the arguments and options
    used during install for upgrade. Overrides the default feature
    'useRememberedArgumentsForUpgrades' set to 'False'. Available in 0.10.4+.

.PARAMETER ExcludePrerelease
    Exclude Prerelease - Should prerelease be ignored for upgrades? Will be
    ignored if you pass `--pre`. Available in 0.10.4+.

.PARAMETER AutoUninstaller
    UseAutoUninstaller - Use auto uninstaller service when uninstalling.
    Overrides the default feature 'autoUninstaller' set to 'True'. Available
    in 0.9.10+.

.PARAMETER SkipAutoUninstaller
    SkipAutoUninstaller - Skip auto uninstaller service when uninstalling.
    Overrides the default feature 'autoUninstaller' set to 'True'. Available
    in 0.9.10+.

.PARAMETER FailOnAutouninstaller
    FailOnAutoUninstaller - Fail the package uninstall if the auto
    uninstaller reports and error. Overrides the default feature
    'failOnAutoUninstaller' set to 'False'. Available in 0.9.10+.

.PARAMETER IgnoreAutoUninstallerFailure
    Ignore Auto Uninstaller Failure - Do not fail the package if auto
    uninstaller reports an error. Overrides the default feature
    'failOnAutoUninstaller' set to 'False'. Available in 0.9.10+.

.PARAMETER KeyUser
    User - used with authenticated feeds. Defaults to empty.

.PARAMETER Key
    Password - the user's password to the source. Encrypted in chocolatey.config file.

.EXAMPLE
    Get-ChocolateyDefaultArguments @PSBoundparameters
#>
function Get-ChocolateyDefaultArgument {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "")]
    [CmdletBinding(
        SupportsShouldProcess=$true
        ,ConfirmImpact="High"
    )]
    Param(
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $Name,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        $Source,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $Disabled,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        $Value,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $BypassProxy,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SelfService,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $NotBroken,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $AllVersions,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [int]
        $Priority = 0,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [PSCredential]
        $Credential,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [PSCredential]
        $ProxyCredential,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $Force,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $CacheLocation,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [String]
        $InstallArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [String]
        $InstallArgumentsSensitive,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [String]
        $PackageParameters,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [String]
        $PackageParametersSensitive,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $OverrideArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $NotSilent,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ApplyArgsToDependencies,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $AllowDowngrade,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SideBySide,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IgnoreDependencies,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $NoProgress,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ForceDependencies,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SkipPowerShell,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IgnoreChecksum,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $AllowEmptyChecksum,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ignorePackageCodes,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $UsePackageCodes,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $StopOnFirstFailure,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SkipCache,


        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $UseDownloadCache,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SkipVirusCheck,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $VirusCheck,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [int]
        $VirusPositive,

        [Parameter(
            ,ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Switch]
        $OrderByPopularity,

        [Parameter(
            ,ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $LocalOnly,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IdOnly,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $Prerelease,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ApprovedOnly,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IncludePrograms,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ByIdOnly,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IdStartsWith,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $Exact,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $x86,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $AcceptLicense,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [int]
        $Timeout,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $UseRememberedArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IgnoreRememberedArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ExcludePrerelease,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $AutoUninstaller,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SkipAutoUninstaller,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $FailOnAutouninstaller,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IgnoreAutoUninstallerFailure,

        #To be used when Password is too long (>240 char) like a key
        $KeyUser,
        $Key
    )

    Process {

        $ChocoArguments = switch($PSBoundParameters.Keys) {
            'Value'         { "--value=`"$value`""}
            'Priority'      { if ( $Priority -gt 0) {"--priority=$priority" } }
            'SelfService'   { "--allow-self-service"}
            'Name'          { "--name=`"$Name`"" }
            'Source'        { "-s`"$Source`"" }
            'ByPassProxy'   {  "--bypass-proxy" }
            'CacheLocation' { "--cache-location=`"$CacheLocation`"" }
            'WhatIf'        {  "--whatif"  }
            'cert'          { "--cert=`"$Cert`"" }
            'Force'         {  '--yes'; '--force' }
            'AcceptLicense' { '--accept-license' }
            'Verbose'       { '--verbose'}
            'Debug'         { '--debug'  }
            'NoProgress'    { '--no-progress' }
            'Credential'    {
                if ($Credential.Username) {
                    "--user=`"$($Credential.Username)`""
                }
                if ($Credential.GetNetworkCredential().Password) {
                    "--password=`"$($Credential.GetNetworkCredential().Password)`""
                }
            }
            'KeyUser'           { "--user=`"$KeyUser`"" }
            'Key'               { "--password=`"$Key`"" }
            'Timeout'           { "--execution-timeout=$Timeout" }
            'AllowUnofficalBuild'{ "--allow-unofficial-build" }
            'FailOnSTDErr'      { '--fail-on-stderr' }
            'Proxy'             { "--Proxy=`"$Proxy`"" }
            'ProxyCredential'   {
                if ($ProxyCredential.Username) {
                    "--proxy-user=`"$($ProxyCredential.Username)`""
                }
                if ($ProxyCredential.GetNetworkCredential().Password) {
                    "--proxy-password=`"$($ProxyCredential.GetNetworkCredential().Password)`""
                }
            }
            'ProxyBypassList'   { "--proxy-bypass-list=`"$($ProxyBypassList -join ',')`"" }
            'ProxyBypassLocal'  { "--proxy-bypass-on-local" }

            #List / Search Parameters
            'ByTagOnly'         { '--by-tag-only' }
            'ByIdOnly'          { '--by-id-only' }
            'LocalOnly'         { '--local-only' }
            'IdStartsWith'      { '--id-starts-with' }
            'ApprovedOnly'      { '--approved-only'}
            'OrderByPopularity' { '--order-by-popularity' }
            'NotBroken'         { '--not-broken' }
            'prerelease'        { '--prerelease' }
            'IncludePrograms'   { '--include-programs'}
            'AllVersions'       { '--all-versions' }
            'Version'           { "--version=`"$version`"" }
            'exact'             { "--exact" }

            #Install Parameters
            'x86'               { "--x86"}
            'OverrideArguments' { '--override-arguments' }
            'NotSilent'         { '--not-silent' }
            'ApplyArgsToDependencies' { '--apply-install-arguments-to-dependencies' }
            'AllowDowngrade'    { '--allow-downgrade' }
            'SideBySide'        { '--side-by-side' }
            'ignoredependencies'{ '--ignore-dependencies' }
            'ForceDependencies' { '--force-dependencies' }
            'SkipPowerShell'    { '--skip-powershell' }
            'IgnoreChecksum'    { '--ignore-checksum' }
            'allowemptychecksum'{ '--allow-empty-checksum' }
            'AllowEmptyChecksumSecure' { '--allow-empty-checksums-secure' }
            'RequireChecksum'   { '--requirechecksum'}
            'Checksum'          { "--download-checksum=`"$Checksum`"" }
            'Checksum64'        { "--download-checksum-x64=`"$CheckSum64`"" }
            'ChecksumType'      { "--download-checksum-type=`"$ChecksumType`""}
            'checksumtype64'    { "--download-checksum-type-x64=`"$Checksumtype64`""}
            'ignorepackagecodes'{ '--ignore-package-exit-codes' }
            'UsePackageExitCodes' { '--use-package-exit-codes' }
            'StopOnFirstFailure'{ '--stop-on-first-failure' }
            'SkipCache'         { '--skip-download-cache' }
            'UseDownloadCache'  { '--use-download-cache'}
            'SkipVirusCheck'    { '--skip-virus-check' }
            'VirusCheck'        { '--virus-check' }
            'VirusPositive'     { "--virus-positives-minimum=`"$VirusPositive`"" }
            'InstallArguments'  { "--install-arguments=`"$InstallArguments`""}
            'InstallArgumentsSensitive' { "--install-arguments-sensitive=`"$InstallArgumentsSensitive`""}
            'PackageParameters' {"--package-parameters=`"$PackageParameters`"" }
            'PackageParametersSensitive' { "--package-parameters-sensitive=`"$PackageParametersSensitive`""}
            'MaxDownloadRate'   { "--maximum-download-bits-per-second=$MaxDownloadRate" }
            'IgnoreRememberedArguments' { '--ignore-remembered-arguments' }
            'UseRememberedArguments' { '--use-remembered-options' }
            'ExcludePrerelease'  { '--exclude-pre' }

            #uninstall package params
            'AutoUninstaller'     { '--use-autouninstaller'  }
            'SkipAutoUninstaller' { '--skip-autouninstaller' }
            'FailOnAutouninstaller' { '--fail-on-autouninstaller' }
            'IgnoreAutoUninstallerFailure' { '--ignore-autouninstaller-failure' }
        }
        return $ChocoArguments
    }
}

<#
.SYNOPSIS
    Returns a Downloader object (System.Net.WebClient) set up.

.DESCRIPTION
    Returns a Downloader object configured with Proxy and Credential.
    This is used during the Chocolatey software Install Process,
    to retrieve metadata and to download the file.

.PARAMETER url
    Url to execute the request against.

.PARAMETER ProxyLocation
    Url of the Proxy to use for executing request.

.PARAMETER ProxyCredential
    Credential to be used by the proxy. By default it will try to use the cached credential.

.PARAMETER IgnoreProxy
    Bypass the proxy for this request.

.EXAMPLE
    Get-Downloader -Url https://chocolatey.org/api/v2
#>
function Get-Downloader {
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory
        )]
        [System.String]
        $url,

        [uri]
        $ProxyLocation,

        [pscredential]
        $ProxyCredential,

        # To bypass the use of any proxy, please set IgnoreProxy
        [switch]
        $IgnoreProxy
    )

    $downloader = new-object System.Net.WebClient
    $defaultCreds = [System.Net.CredentialCache]::DefaultCredentials

    if ($defaultCreds -ne $null) {
        $downloader.Credentials = $defaultCreds
    }

    if ($ignoreProxy -ne $null -and $ignoreProxy -eq 'true') {
        Write-Debug "Explicitly bypassing proxy"
        $downloader.Proxy = [System.Net.GlobalProxySelection]::GetEmptyWebProxy()
    }
    else {  # check if a proxy is required
        if ($ProxyLocation -and ![string]::IsNullOrEmpty($ProxyLocation)) {
            $proxy = New-Object System.Net.WebProxy($ProxyLocation, $true)
            if ($null -ne $ProxyCredential) {
                $proxy.Credentials = $ProxyCredential
            }

            Write-Debug "Using explicit proxy server '$ProxyLocation'."
            $downloader.Proxy = $proxy
        }
        elseif (!$downloader.Proxy.IsBypassed($url)) {
            # system proxy (pass through)
            $creds = $defaultCreds
            if ($creds -eq $null) {
                Write-Debug "Default credentials were null. Attempting backup method"
                Throw "Could not download required file from $url"
            }

            $proxyaddress = $downloader.Proxy.GetProxy($url).Authority
            Write-Debug "Using system proxy server '$proxyaddress'."
            $proxy = New-Object System.Net.WebProxy($proxyaddress)
            $proxy.Credentials = $creds
            $downloader.Proxy = $proxy
        }
    }

  return $downloader
}

<#
.SYNOPSIS
    Download a file from url using specified proxy settings.

.DESCRIPTION
    Helper function to Download a file from a given url
    using specified proxy settings.

.PARAMETER url
    URL of the file to download

.PARAMETER file
    File path and name to save the downloaded file to.

.PARAMETER ProxyLocation
    Proxy uri to use for the download.

.PARAMETER ProxyCredential
    Credential to use for authenticating to the proxy.
    By default it will try to load cached credentials.

.PARAMETER IgnoreProxy
    Bypass the proxy for this request.

.EXAMPLE
    Get-RemoteFile -Url https://chocolatey.org/api/v2/0.10.8/ -file C:\chocolatey.zip

#>
function Get-RemoteFile {
    [CmdletBinding()]
    param (
        [System.String]$url,

        [System.String]$file,

        [uri]
        $ProxyLocation,

        [pscredential]
        $ProxyCredential,

        # To bypass the use of any proxy, please set IgnoreProxy
        [switch]
        $IgnoreProxy
    )

    Write-Debug "Downloading $url to $file"
    $downloaderParams = @{}
    $KeysForDownloader = $PSBoundParameters.keys | Where-Object { $_ -notin @('file')}
    foreach ($key in $KeysForDownloader ) {
        Write-Debug "`tWith $key :: $($PSBoundParameters[$key])"
        $null = $downloaderParams.Add($key ,$PSBoundParameters[$key])
    }
    $downloader = Get-Downloader @downloaderParams
    $downloader.DownloadFile($url, $file)
}

<#
.SYNOPSIS
    Download the content from url using specified proxy settings.

.DESCRIPTION
    Helper function to Download the content from a url
    using specified proxy settings.

.PARAMETER url
    URL of the file to download.

.PARAMETER file
    File path and name to save the downloaded file to.

.PARAMETER ProxyLocation
    Proxy uri to use for the download.

.PARAMETER ProxyCredential
    Credential to use for authenticating to the proxy.
    By default it will try to load cached credentials.

.PARAMETER IgnoreProxy
    Bypass the proxy for this request.

.EXAMPLE
    Get-RemoteString -Url https://chocolatey.org/install.ps1
#>
function Get-RemoteString {
    [CmdletBinding()]
    param (
        [System.String]$url,

        [uri]
        $ProxyLocation,

        [pscredential]
        $ProxyCredential,

        # To bypass the use of any proxy, please set IgnoreProxy
        [switch]
        $IgnoreProxy
    )

    Write-Debug "Downloading string from $url"
    $downloaderParams = @{}
    $KeysForDownloader = $PSBoundParameters.keys | Where-Object { $_ -notin @()}
    foreach ($key in $KeysForDownloader ) {
        Write-Debug "`tWith $key :: $($PSBoundParameters[$key])"
        $null = $downloaderParams.Add($key,$PSBoundParameters[$key])
    }
    $downloader = Get-Downloader @downloaderParams
    return $downloader.DownloadString($url)
}

function Get-SemVerFromString {
    <#
    .SYNOPSIS
        Private function to parse a string to a SemVer 2.0 custom object, but with added Revision number common to .Net world (and Choco Packages)

    .DESCRIPTION
        This function parses the string of a version into an object composed of a [System.Version] object (Major, Minor, Patch, Revision)
        plus the pre-release identifiers and Build Metadata. The PreRelease metadata is also made available as an array to ease the
        version comparison.

    .PARAMETER VersionString
        String representation of the Version to Parse.

    .EXAMPLE
        Get-SemVerFromString -VersionString '1.6.24.256-rc1+01012018'

    .EXAMPLE
        Get-SemVerFromString -VersionString '1.6-alpha.13.24.15'

    .NOTES
        The function returns a PSObject of PSTypeName Package.Version
    #>
    [CmdletBinding()]
    [OutputType([PSobject])]

    Param (
        [System.String]
        $VersionString
    )

    # Based on SemVer 2.0 but adding Revision (common in .Net/NuGet/Chocolatey packages) https://semver.org
    if ($VersionString -notmatch '-') {
        [System.Version]$version, $BuildMetadata = $VersionString -split '\+', 2
    }
    else {
        [System.Version]$version, [System.String]$Tag = $VersionString -split '-', 2
        $PreRelease, $BuildMetadata = $Tag -split '\+', 2
    }

    $PreReleaseArray = $PreRelease -split '\.'

    [psobject]@{
        PSTypeName      = 'Package.Version'
        Version         = $version
        Prerelease      = $PreRelease
        Metadata        = $BuildMetadata
        PrereleaseArray = $PreReleaseArray
    }
}

<#
.SYNOPSIS
    Fix for PS2/3

.DESCRIPTION
    PowerShell v2/3 caches the output stream. Then it throws errors due
    to the FileStream not being what is expected. Fixes "The OS handle's
    position is not what FileStream expected. Do not use a handle
    simultaneously in one FileStream and in Win32 code or another
    FileStream."

.EXAMPLE
    Repair-PowerShellOutputRedirectionBug #Only for PSVersion below PS4
#>
function Repair-PowerShellOutputRedirectionBug {
    [CmdletBinding()]
    Param(

    )

    if ($PSVersionTable.PSVersion.Major -lt 4) {
        return
    }

    try {
        # http://www.leeholmes.com/blog/2008/07/30/workaround-the-os-handles-position-is-not-what-filestream-expected/ plus comments
        $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetField"
        $objectRef = $host.GetType().GetField("externalHostRef", $bindingFlags).GetValue($host)
        $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetProperty"
        $consoleHost = $objectRef.GetType().GetProperty("Value", $bindingFlags).GetValue($objectRef, @())
        [void] $consoleHost.GetType().GetProperty("IsStandardOutputRedirected", $bindingFlags).GetValue($consoleHost, @())
        $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetField"
        $field = $consoleHost.GetType().GetField("standardOutputWriter", $bindingFlags)
        $field.SetValue($consoleHost, [Console]::Out)
        [void] $consoleHost.GetType().GetProperty("IsStandardErrorRedirected", $bindingFlags).GetValue($consoleHost, @())
        $field2 = $consoleHost.GetType().GetField("standardErrorWriter", $bindingFlags)
        $field2.SetValue($consoleHost, [Console]::Error)
    }
    catch {
        Write-Warning "Unable to apply redirection fix."
    }
}

<#
.SYNOPSIS
    Add a Pin to a Chocolatey Package

.DESCRIPTION
    Allows you to pin a Chocolatey Package like choco pin add -n=packagename

.PARAMETER Name
    Name of the Chocolatey Package to pin.
    The Package must be installed beforehand.

.PARAMETER Version
    This allows to pin a specific Version of a Chocolatey Package.
    The Package with the Version to pin must be installed beforehand.

.EXAMPLE
    Add-ChocolateyPin -Name 'PackageName'

.EXAMPLE
    Add-ChocolateyPin -Name 'PackageName' -Version '1.0.0'

.NOTES
    https://chocolatey.org/docs/commands-pin
#>
function Add-ChocolateyPin {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact='High'
    )]
    Param(
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
        )]
        [Alias('Package')]
        [System.String]
        $Name,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $Version

    )

    Process {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        if (!(Get-ChocolateyPackage -Name $Name)) {
            Throw "Chocolatey Package $Name cannot be found."
        }

        $ChocoArguments = @('pin','add','-r')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        # Write-Debug "choco $($ChocoArguments -join ' ')"

        if ($PSCmdlet.ShouldProcess("$Name $Version", "Add Pin")) {
            $Output = &$chocoCmd $ChocoArguments

            # LASTEXITCODE is always 0 unless point an existing version (0 when remove but already removed)
            if ($LASTEXITCODE -ne 0) {
                Throw ("Error when trying to add Pin for Package '{0}'.`r`n {1}" -f "$Name $Version", ($output -join "`r`n"))
            }
            else {
                $output | Write-Verbose
            }
        }
    }
}

<#
.SYNOPSIS
    Disable a Chocolatey Feature

.DESCRIPTION
    Allows you to disable a Chocolatey Feature usually accessed by choco feature disable -n=bob

.PARAMETER Name
    Name of the Chocolatey Feature to disable. Some are only available in the Chocolatey for business version.

.PARAMETER NoProgress
    This allows to reduce the output created by the Chocolatey Command.

.EXAMPLE
    Disable-ChocolateyFeature -Name 'Bob'

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsFeature
#>
function Disable-ChocolateyFeature {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
        )]
        [Alias('Feature')]
        [System.String]
        $Name,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $NoProgress
    )

    Process {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        if (!(Get-ChocolateyFeature -Name $Name)) {
            Throw "Chocolatey Feature $Name cannot be found."
        }

        $ChocoArguments = @('feature','disable')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose "choco $($ChocoArguments -join ' ')"

        &$chocoCmd $ChocoArguments | Write-Verbose
    }
}

<#
.SYNOPSIS
    Disable a Source set in the Chocolatey Config

.DESCRIPTION
    Lets you disable an existing source.
    The equivalent Choco command is Choco source disable -n=sourcename

.PARAMETER Name
    Name of the Chocolatey source to Disable

.PARAMETER NoProgress
    This allows to reduce the output created by the Chocolatey Command.

.EXAMPLE
    Disable-ChocolateySource -Name chocolatey

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsSource
#>
function Disable-ChocolateySource {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
        )]
        [System.String]
        $Name,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $NoProgress
    )

    Process {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        if (!(Get-ChocolateySource -Name $Name)) {
            Throw "Chocolatey Source $Name cannot be found. You can Register it using Register-ChocolateySource."
        }

        $ChocoArguments = @('source','disable')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose "choco $($ChocoArguments -join ' ')"

        &$chocoCmd $ChocoArguments | Write-Verbose
    }
}

<#
.SYNOPSIS
    Disable a Chocolatey Feature

.DESCRIPTION
    Allows you to enable a Chocolatey Feature usually accessed by choco feature enable -n=bob

.PARAMETER Name
    Name of the Chocolatey Feature to disable

.PARAMETER NoProgress
    This allows to reduce the output created by the Chocolatey Command.

.EXAMPLE
    Enable-ChocolateyFeature -Name 'MyChocoFeatureName'

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsFeature
#>
function Enable-ChocolateyFeature {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
        )]
        [Alias('Feature')]
        [System.String]
        $Name,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $NoProgress
    )

    Process {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        if (!(Get-ChocolateyFeature -Name $Name)) {
            Throw "Chocolatey Feature $Name cannot be found."
        }

        $ChocoArguments = @('feature','enable')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose "choco $($ChocoArguments -join ' ')"

        &$chocoCmd $ChocoArguments | Write-Verbose
    }
}

<#
.SYNOPSIS
    Enable a Source set in the Chocolatey Config

.DESCRIPTION
    Lets you Enable an existing source from the Chocolatey Config.
    The equivalent Choco command is Choco source enable -n=sourcename

.PARAMETER Name
    Name of the Chocolatey source to Disable

.PARAMETER NoProgress
    This allows to reduce the output created by the Chocolatey Command.

.EXAMPLE
    Enable-ChocolateySource -Name 'chocolatey'

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsSource
#>
function Enable-ChocolateySource {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
        )]
        [System.String]
        $Name,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $NoProgress

    )

    Process {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        if (!(Get-ChocolateySource -id $Name)) {
            Throw "Chocolatey Source $Name cannot be found. You can Register it using Register-ChocolateySource."
        }

        $ChocoArguments = @('source','enable')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose "choco $($ChocoArguments -join ' ')"

        &$chocoCmd $ChocoArguments | Write-Verbose
    }
}

<#
.SYNOPSIS
    Gets the Features set in the Configuration file.

.DESCRIPTION
    This command looks up in the Chocolatey Config file, and returns
    the Features available from there.
    Some feature may be available but now show up with this command.

.PARAMETER Feature
    Name of the Feature when retrieving a single Feature. It defaults to returning
    all feature available in the config file.

.EXAMPLE
    Get-ChocolateyFeature -Name MyFeatureName

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsFeature
#>
function Get-ChocolateyFeature {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline
            ,ValueFromPipelineByPropertyName
        )]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Feature = '*'
    )
    Begin {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        $ChocoConfigPath = join-path $chocoCmd.Path ..\..\config\chocolatey.config -Resolve
        $ChocoXml = [xml]::new()
        $ChocoXml.Load($ChocoConfigPath)
    }

    Process {
        if (!$ChocoXml) {
            Throw "Error with Chocolatey config."
        }

        foreach ($Name in $Feature) {
            if ($Name -ne '*') {
                Write-Verbose ('Searching for Feature named ${0}' -f [Security.SecurityElement]::Escape($Name))
                $FeatureNodes = $ChocoXml.SelectNodes("//feature[translate(@name,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')='$([Security.SecurityElement]::Escape($Name.ToLower()))']")
            }
            else {
                Write-Verbose 'Returning all Sources configured.'
                $FeatureNodes = $ChocoXml.chocolatey.features.childNodes
            }

            foreach ($FeatureNode in $FeatureNodes) {
                $FeatureObject = [PSCustomObject]@{
                    PSTypeName  = 'Chocolatey.Feature'
                }
                foreach ($property in $FeatureNode.Attributes.name) {
                    $FeaturePropertyParam = @{
                        MemberType = 'NoteProperty'
                        Name = $property
                        Value = $FeatureNode.($property).ToString()
                    }
                    $FeatureObject | Add-Member @FeaturePropertyParam
                }
                Write-Output $FeatureObject
            }
        }
    }
}

<#
.SYNOPSIS
    List the packages from a source or installed on the local machine.

.DESCRIPTION
    This command can list the packages available on the configured source or a specified one.
    You can also retrieve the list of package installed locally.
    Finally, you can also use this command to search for a specific package, and specific version.

.PARAMETER Name
    Name or part of the name of the Package to search for, whether locally or from source(s).

.PARAMETER Version
    Version of the package you're looking for.

.PARAMETER LocalOnly
    Restrict the search to the installed package.

.PARAMETER IdOnly
    Id Only - Only return Package Ids in the list results. Available in 0.1-0.6+.

.PARAMETER Prerelease
    Prerelease - Include Prereleases? Defaults to false

.PARAMETER ApprovedOnly
    ApprovedOnly - Only return approved packages - this option will filter
    out results not from the community repository (https://chocolatey.org/packages). Available in 0.9.10+

.PARAMETER ByIdOnly
    ByIdOnly - Only return packages where the id contains the search filter.
    Available in 0.9.10+.

.PARAMETER IdStartsWith
    IdStartsWith - Only return packages where the id starts with the search
    filter. Available in 0.9.10+.

.PARAMETER NoProgress
    Do Not Show Progress - Do not show download progress percentages.

.PARAMETER Exact
    Exact - Only return packages with this exact name. Available in 0.9.10+.

.PARAMETER Source
    Source - Source location for install. Can use special 'webpi' or 'windowsfeatures' sources. Defaults to sources.

.PARAMETER Credential
    Credential used with authenticated feeds. Defaults to empty.

.PARAMETER CacheLocation
    CacheLocation - Location for download cache, defaults to %TEMP% or value in chocolatey.config file.

.EXAMPLE
    Get-ChocolateyPackage -LocalOnly chocolatey

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsList
#>
function Get-ChocolateyPackage {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(
            , ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $LocalOnly,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $IdOnly,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $Prerelease,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ApprovedOnly,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $ByIdOnly,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IdStartsWith,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $NoProgress,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $Exact,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        $Source,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [PSCredential]
        $Credential,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $CacheLocation
    )

    Process {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        $ChocoArguments = @('list', '-r')
        $paramKeys = [Array]::CreateInstance([string], $PSboundparameters.Keys.count)
        $PSboundparameters.Keys.CopyTo($paramKeys, 0)
        switch ($paramKeys) {
            'verbose' { $null = $PSBoundParameters.remove('Verbose') }
            'debug' { $null = $PSBoundParameters.remove('debug') }
            'Name' { $null = $PSBoundParameters.remove('Name') }
            'Exact' { $null = $PSBoundParameters.remove('Exact') }
        }

        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose "choco $($ChocoArguments -join ' ')"

        if ($ChocoArguments -contains '--verbose') {
            $ChocoArguments = [System.Collections.ArrayList]$ChocoArguments
            $ChocoArguments.remove('--verbose')
        }

        if ( $LocalOnly -and
            !$PSboundparameters.containsKey('Version') -and
            (($Name -and $Exact) -or ([string]::IsNullOrEmpty($Name)))
        ) {
            $CacheFolder = Join-Path -Path $Env:ChocolateyInstall -ChildPath 'cache'
            $CachePath   = Join-Path -Path $CacheFolder -ChildPath 'GetChocolateyPackageCache.xml'
            try {
                if (!(Test-Path $CacheFolder)) {
                    $null = New-Item -Type Directory -Path $CacheFolder -Force -ErrorAction Stop
                }
                if (Test-Path $CachePath) {
                    $CachedFile = Get-Item $CachePath
                }
                [io.file]::OpenWrite($CachePath).close()
                $CacheAvailable = $true
            }
            catch {
                Write-Debug "Unable to write to cache $CachePath, caching unavailable."
                $CacheAvailable = $false
            }

            if ( $CacheAvailable -and $CachedFile -and
                 $CachedFile.LastWriteTime -gt ([datetime]::Now.AddSeconds(-60))
            ) {
                Write-Debug "Retrieving from cache at $CachePath."
                $UnfilteredResults = @(Import-Clixml -Path $CachePath)
                Write-Debug "Loaded $($UnfilteredResults.count) from cache."
            }
            else {
                Write-Debug "Running command (before caching)."
                $ChocoListOutput = &$chocoCmd $ChocoArguments
                Write-Debug "$chocoCmd $($ChocoArguments -join ' ')"
                $UnfilteredResults = $ChocoListOutput | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'
                $CacheFile = [io.fileInfo]$CachePath

                if ($CacheAvailable) {
                    try {
                        $null = $UnfilteredResults | Export-Clixml -Path $CacheFile -Force -ErrorAction Stop
                        Write-Debug "Unfiltered list cached at $CacheFile."
                    }
                    catch {
                        Write-Debug "Error Creating the cache at $CacheFile."
                    }
                }
            }

            $UnfilteredResults | Where-Object {
                $( if ($Name) {$_.Name -eq $Name} else { $true })
            }
        }
        else {
            Write-Debug "Running from command without caching."
            $ChocoListOutput = &$chocoCmd $ChocoArguments $Name $( if ($Exact) { '--exact' } )
            $ChocoListOutput | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'
        }
    }
}

<#
.SYNOPSIS
    Gets the pinned Chocolatey Packages.

.DESCRIPTION
    This command gets the pinned Chocolatey Packages, and returns
    the Settings available from there.

.PARAMETER Name
    Name of the Packages when retrieving a single one or a specific list.
    It defaults to returning all Packages available in the config file.

.EXAMPLE
    Get-ChocolateyPin -Name packageName

.NOTES
    https://chocolatey.org/docs/commands-pin
#>

function Get-ChocolateyPin {
    [CmdletBinding()]
    Param(
        [Parameter(
            ValueFromPipeline
            ,ValueFromPipelineByPropertyName
        )]
        [System.String]
        $Name = '*'
    )

    if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
        Throw "Chocolatey Software not found."
    }

    if (!(Get-ChocolateyPackage -Name $Name)) {
        Throw "Chocolatey Package $Name cannot be found."
    }

    # Prepare the arguments for `choco pin list -r`
    $ChocoArguments = @('pin', 'list', '-r')

    # Write-Debug -Message "choco $($ChocoArguments -join ' ')"

    # Stop here if the list is empty
    if (-Not ($ChocoPinListOutput = &$chocoCmd $ChocoArguments)) {
        return
    }
    else {
        Write-Verbose ("Found {0} Packages" -f $ChocoPinListOutput.count)
        # Convert the list to objects
        $ChocoPinListOutput = $ChocoPinListOutput | ConvertFrom-Csv -Delimiter '|' -Header 'Name','Version'
    }

    if ($Name -ne '*') {
        Write-Verbose 'Filtering pinned Packages'
        $ChocoPinListOutput = $ChocoPinListOutput | Where-Object { $_.Name -in $Name }
    }
    else {
        Write-Verbose 'Returning all pinned Packages'
    }

    foreach ($Pin in $ChocoPinListOutput) {
        [PSCustomObject]@{
            PSTypeName  = 'Chocolatey.Pin'
            Name        = $Pin.Name
            Version     = $Pin.Version
        }
    }
}

<#
.SYNOPSIS
    Gets the Settings set in the Configuration file.

.DESCRIPTION
    This command looks up in the Chocolatey Config file, and returns
    the Settings available from there.

.PARAMETER Setting
    Name of the Setting when retrieving a single one or a specific list.
    It defaults to returning all Settings available in the config file.

.EXAMPLE
    Get-ChocolateySetting -Name CacheLocation

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsConfig
#>
function Get-ChocolateySetting {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline
            ,ValueFromPipelineByPropertyName
        )]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Setting = '*'
    )
    Begin {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        $ChocoConfigPath = join-path $chocoCmd.Path ..\..\config\chocolatey.config -Resolve
        $ChocoXml = [xml]::new()
        $ChocoXml.Load($ChocoConfigPath)
    }

    Process {
        if (!$ChocoXml) {
            Throw "Error with Chocolatey config."
        }

        foreach ($Name in $Setting) {
            if ($Name -ne '*') {
                Write-Verbose ("Searching for Setting named {0}" -f [Security.SecurityElement]::Escape($Name))
                $SettingNodes = $ChocoXml.SelectNodes("//add[translate(@key,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')='$([Security.SecurityElement]::Escape($Name.ToLower()))']")
            }
            else {
                Write-Verbose 'Returning all Sources configured.'
                $SettingNodes = $ChocoXml.chocolatey.config.childNodes
            }

            foreach ($SettingNode in $SettingNodes) {
                $SettingObject = [PSCustomObject]@{
                    PSTypeName  = 'Chocolatey.Setting'
                }
                foreach ($property in $SettingNode.Attributes.name) {
                    $SettingPropertyParam = @{
                        MemberType = 'NoteProperty'
                        Name       = $property
                        Value      = $SettingNode.($property).ToString()
                    }
                    $SettingObject | Add-Member @SettingPropertyParam
                }
                Write-Output $SettingObject
            }
        }
    }
}

<#
.SYNOPSIS
    List the source from Configuration file.

.DESCRIPTION
    Allows you to list the configured source from the Chocolatey Configuration file.
    When it comes to the source location, this can be a folder/file share
    or an http location. If it is a url, it will be a location you can go
    to in a browser and it returns OData with something that says Packages
    in the browser, similar to what you see when you go
    to https://chocolatey.org/api/v2/.

.PARAMETER Name
    Retrieve specific source details from configuration file.

.EXAMPLE
    Get-ChocolateySource -Name Chocolatey

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsSource
#>
function Get-ChocolateySource {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline
            ,ValueFromPipelineByPropertyName
        )]
        [Alias('id')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name = '*'
    )
    Begin {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }
        $ChocoConfigPath = join-path $chocoCmd.Path ..\..\config\chocolatey.config -Resolve
        $ChocoXml = [xml]::new()
        $ChocoXml.Load($ChocoConfigPath)
    }

    Process {
        if (!$ChocoXml) {
            Throw "Error with Chocolatey config."
        }

        foreach ($id in $Name) {
            if ($id -ne '*') {
                Write-Verbose ('Searching for Source with id ${0}' -f [Security.SecurityElement]::Escape($id))
                $sourceNodes = $ChocoXml.SelectNodes("//source[translate(@id,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')='$([Security.SecurityElement]::Escape($id.ToLower()))']")
            }
            else {
                Write-Verbose 'Returning all Sources configured.'
                $sourceNodes = $ChocoXml.chocolatey.sources.childNodes
            }

            foreach ($source in $sourceNodes) {
                Write-Output ([PSCustomObject]@{
                        PSTypeName  = 'Chocolatey.Source'
                        Name        = $source.id
                        Source      = $source.value
                        disabled    = [bool]::Parse($source.disabled)
                        bypassProxy = [bool]::Parse($source.bypassProxy)
                        selfService = [bool]::Parse($source.selfService)
                        priority    = [int]$source.priority
                        username    = $source.user
                        password    = $source.password
                    })
            }
        }
    }
}

<#
.SYNOPSIS
    Retrieve the version of the Chocolatey available in $Env:Path

.DESCRIPTION
    Get the version of the Chocolatey currently installed.

.EXAMPLE
    Get-ChocolateyVersion #This command does not accept parameter

.NOTES
    This does not specify the SKU (C4B or Community)
#>
function Get-ChocolateyVersion {
    [CmdletBinding()]
    [OutputType([version])]
    param(
    )

    if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
        Throw "Chocolatey Software not found."
    }

    $ChocoArguments = @('-v')
    Write-Verbose "choco $($ChocoArguments -join ' ')"

    $CHOCO_OLD_MESSAGE = "Please run chocolatey /? or chocolatey help - chocolatey v"
    $versionOutput = (&$chocoCmd $ChocoArguments) -replace ([regex]::escape($CHOCO_OLD_MESSAGE))
    #remove other text to keep only the last line which should have the version
    $versionOutput = ($versionOutput -split '\r\n|\n|\r')[-1]
    Write-Verbose $versionOutput
    [version]($versionOutput)
}

<#
.SYNOPSIS
    Installs a Chocolatey package or a list of packages (sometimes specified as a packages.config).

.DESCRIPTION
    Once the Chocolatey Software has been installed (see Install-ChocolateySoftware) this command
    allows you to install Software packaged for Chocolatey.

.PARAMETER Name
    Package Name to install, either from a configured source, a specified one such as a folder,
    or the current directory '.'

.PARAMETER Version
    Version - A specific version to install. Defaults to unspecified.

.PARAMETER Source
    Source - The source to find the package(s) to install. Special sources
    include: ruby, webpi, cygwin, windowsfeatures, and python. To specify
    more than one source, pass it with a semi-colon separating the values (-
    e.g. "'source1;source2'"). Defaults to default feeds.

.PARAMETER Credential
    Credential used with authenticated feeds. Defaults to empty.

.PARAMETER Force
    Force - force the behavior. Do not use force during normal operation -
    it subverts some of the smart behavior for commands.

.PARAMETER CacheLocation
    CacheLocation - Location for download cache, defaults to %TEMP% or value
    in chocolatey.config file.

.PARAMETER NoProgress
    Do Not Show Progress - Do not show download progress percentages.
    Available in 0.10.4+.

.PARAMETER AcceptLicense
    AcceptLicense - Accept license dialogs automatically. Reserved for future use.

.PARAMETER Timeout
    CommandExecutionTimeout (in seconds) - The time to allow a command to
    finish before timing out. Overrides the default execution timeout in the
    configuration of 2700 seconds. '0' for infinite starting in 0.10.4.

.PARAMETER x86
    ForceX86 - Force x86 (32bit) installation on 64 bit systems. Defaults to false.

.PARAMETER InstallArguments
    InstallArguments - Install Arguments to pass to the native installer in
    the package. Defaults to unspecified.

.PARAMETER InstallArgumentsSensitive
    InstallArgumentsSensitive - Install Arguments to pass to the native
    installer in the package that are sensitive and you do not want logged.
    Defaults to unspecified. Available in 0.10.1+. [Licensed editions](https://chocolatey.org/compare) only.

.PARAMETER PackageParameters
    PackageParameters - Parameters to pass to the package, that should be handled by the ChocolateyInstall.ps1

.PARAMETER PackageParametersSensitive
    PackageParametersSensitive - Package Parameters to pass the package that
    are sensitive and you do not want logged. Defaults to unspecified.
    Available in 0.10.1+. [Licensed editions](https://chocolatey.org/compare) only.

.PARAMETER OverrideArguments
    OverrideArguments - Should install arguments be used exclusively without
    appending to current package passed arguments? Defaults to false.

.PARAMETER NotSilent
    NotSilent - Do not install this silently. Defaults to false.

.PARAMETER ApplyArgsToDependencies
    Apply Install Arguments To Dependencies  - Should install arguments be
    applied to dependent packages? Defaults to false.

.PARAMETER AllowDowngrade
    AllowDowngrade - Should an attempt at downgrading be allowed? Defaults to false.

.PARAMETER SideBySide
    AllowMultipleVersions - Should multiple versions of a package be
    installed? Defaults to false.

.PARAMETER IgnoreDependencies
    IgnoreDependencies - Ignore dependencies when installing package(s).
    Defaults to false.

.PARAMETER ForceDependencies
    ForceDependencies - Force dependencies to be reinstalled when force
    installing package(s). Must be used in conjunction with --force.
    Defaults to false.

.PARAMETER SkipPowerShell
    Skip Powershell - Do not run chocolateyInstall.ps1. Defaults to false.

.PARAMETER IgnoreChecksum
    IgnoreChecksums - Ignore checksums provided by the package. Overrides
    the default feature 'checksumFiles' set to 'True'. Available in 0.9.9.9+.

.PARAMETER AllowEmptyChecksum
    Allow Empty Checksums - Allow packages to have empty/missing checksums
    for downloaded resources from non-secure locations (HTTP, FTP). Use this
    switch is not recommended if using sources that download resources from
    the internet. Overrides the default feature 'allowEmptyChecksums' set to
    'False'. Available in 0.10.0+.

.PARAMETER ignorePackageCodes
    IgnorePackageExitCodes - Exit with a 0 for success and 1 for non-success,
    no matter what package scripts provide for exit codes. Overrides the
    default feature 'usePackageExitCodes' set to 'True'. Available in 0.-9.10+.

.PARAMETER UsePackageCodes
    UsePackageExitCodes - Package scripts can provide exit codes. Use those
    for choco's exit code when non-zero (this value can come from a
    dependency package). Chocolatey defines valid exit codes as 0, 1605,
    1614, 1641, 3010.  Overrides the default feature 'usePackageExitCodes'
    set to 'True'. Available in 0.9.10+.

.PARAMETER StopOnFirstFailure
    Stop On First Package Failure - stop running install, upgrade or
    uninstall on first package failure instead of continuing with others.
    Overrides the default feature 'stopOnFirstPackageFailure' set to 'False'. Available in 0.10.4+.

.PARAMETER SkipCache
    Skip Download Cache - Use the original download even if a private CDN
    cache is available for a package. Overrides the default feature
    'downloadCache' set to 'True'. Available in 0.9.10+. [Licensed editions](https://chocolatey.org/compare)
    only. See https://chocolatey.org/docs/features-private-cdn

.PARAMETER UseDownloadCache
    Use Download Cache - Use private CDN cache if available for a package.
    Overrides the default feature 'downloadCache' set to 'True'. Available
    in 0.9.10+. [Licensed editions](https://chocolatey.org/compare) only. See https://chocolate-
    y.org/docs/features-private-cdn

.PARAMETER SkipVirusCheck
    Skip Virus Check - Skip the virus check for downloaded files on this run.
    Overrides the default feature 'virusCheck' set to 'True'. Available
    in 0.9.10+. [Licensed editions](https://chocolatey.org/compare) only.
    See https://chocolatey.org/docs/features-virus-check

.PARAMETER VirusCheck
    Virus Check - check downloaded files for viruses. Overrides the default
    feature 'virusCheck' set to 'True'. Available in 0.9.10+.
    Licensed editions only. See https://chocolatey.org/docs/features-virus-check

.PARAMETER VirusPositive
    Virus Check Minimum Scan Result Positives - the minimum number of scan
    result positives required to flag a package. Used when virusScannerType
    is VirusTotal. Overrides the default configuration value
    'virusCheckMinimumPositives' set to '5'. Available in 0.9.10+. Licensed
    editions only. See https://chocolatey.org/docs/features-virus-check

.EXAMPLE
    Install-ChocolateyPackage -Name Chocolatey -Version 0.10.8

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsInstall
#>
function Install-ChocolateyPackage {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact='High'
    )]
    param(
        [Parameter(
            Mandatory
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
        )]
        [System.String[]]
        $Name,

        [Parameter(
            ,ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        $Source,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [PSCredential]
        $Credential,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $Force,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $CacheLocation,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $NoProgress,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $AcceptLicense,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [int]
        $Timeout,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $x86,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $InstallArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $InstallArgumentsSensitive,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $PackageParameters,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $PackageParametersSensitive,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $OverrideArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $NotSilent,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $ApplyArgsToDependencies,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $AllowDowngrade,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $SideBySide,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $IgnoreDependencies,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $ForceDependencies,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $SkipPowerShell,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $IgnoreChecksum,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $AllowEmptyChecksum,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $ignorePackageCodes,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $UsePackageCodes,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $StopOnFirstFailure,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $SkipCache,


        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $UseDownloadCache,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $SkipVirusCheck,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $VirusCheck,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [int]
        $VirusPositive
    )

    begin {
        $null = $PSboundParameters.remove('Name')
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }
        $CachePath = [io.path]::Combine($Env:ChocolateyInstall,'cache','GetChocolateyPackageCache.xml')
        if ( (Test-Path $CachePath)) {
            $null = Remove-Item $CachePath -ErrorAction SilentlyContinue
        }
    }
    Process {
        foreach ($PackageName in $Name) {
            $ChocoArguments = @('install',$PackageName)
            $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
            Write-Verbose "choco $($ChocoArguments -join ' ')"

            if ($PSCmdlet.ShouldProcess($PackageName,"Install")) {
                #Impact confirmed, go choco go!
                $ChocoArguments += '-y'
                $ChocoOut = &$chocoCmd $ChocoArguments
                if ($ChocoOut) {
                    Write-Output $ChocoOut
                }
            }
        }
    }
}

# =====================================================================
# Copyright 2017 Chocolatey Software, Inc, and the
# original authors/contributors from ChocolateyGallery
# Copyright 2011 - 2017 RealDimensions Software, LLC, and the
# original authors/contributors from ChocolateyGallery
# at https://github.com/chocolatey/chocolatey.org
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =====================================================================

<#
.SYNOPSIS
    Install the Chocolatey Software from a URL to download the binary from.

.DESCRIPTION
    Install Chocolatey Software either from a fixed URL where the chocolatey nupkg is stored,
    or from the url of a NuGet feed containing the Chocolatey Package.
    A version can be specified to lookup the Package feed for a specific version, and install it.
    A proxy URL and credential can be specified to fetch the Chocolatey package, or the proxy configuration
    can be ignored.

.PARAMETER ChocolateyPackageUrl
    Exact URL of the chocolatey package. This can be an HTTP server, a network or local path.
    This must be the .nupkg package as downloadable from here: https://chocolatey.org/packages/chocolatey

.PARAMETER PackageFeedUrl
    Url of the NuGet Feed API to use for looking up the latest version of Chocolatey (available on that feed).
    This is also used when searching for a specific version, doing a lookup via an Odata filter.

.PARAMETER Version
    Version to install if you want to be specific, this is the way to Install a pre-release version, as when not specified,
    the latest non-prerelease version is looked up from the feed defined in PackageFeedUrl.

.PARAMETER ChocoTempDir
    The temporary folder to extract the Chocolatey Binaries during install. This does not set the Chocolatey Cache dir.

.PARAMETER ProxyLocation
    Proxy url to use when downloading the Chocolatey Package for installation.

.PARAMETER ProxyCredential
    Credential to authenticate to the proxy, if not specified but the ProxyLocation is set, an attempt
    to use the Cached credential will be made.

.PARAMETER IgnoreProxy
    Ensure the proxy is bypassed when downloading the Chocolatey Package from the URL.

.PARAMETER InstallationDirectory
    Set the Installation Directory for Chocolatey, by creating the Environment Variable. This will persist after the installation.

.EXAMPLE
    Install latest chocolatey software from the Community repository (non pre-release version)
    Install-ChocolateySoftware

.EXAMPLE
    Install latest chocolatey software from a custom internal feed
    Install-ChocolateySoftware -PackageFeedUrl https://proget.mycorp.local/nuget/Choco

.NOTES
    Please raise issues at https://github.com/gaelcolas/Chocolatey/issues
#>
function Install-ChocolateySoftware {
    [CmdletBinding(
        DefaultParameterSetName = 'FromFeedUrl'
    )]
    param(
        [Parameter(
            ParameterSetName = 'FromPackageUrl'
        )]
        [uri]
        $ChocolateyPackageUrl,

        [Parameter(
            ParameterSetName = 'FromFeedUrl'
        )]
        [uri]
        $PackageFeedUrl = 'https://chocolatey.org/api/v2',

        [System.String]
        $Version,

        [System.String]
        $ChocoTempDir,

        [uri]
        $ProxyLocation,

        [pscredential]
        $ProxyCredential,

        [switch]
        $IgnoreProxy,

        [System.String]
        $InstallationDirectory
    )

    if ($PSVersionTable.PSVersion.Major -lt 4) {
        Repair-PowerShellOutputRedirectionBug
    }

    # Attempt to set highest encryption available for SecurityProtocol.
    # PowerShell will not set this by default (until maybe .NET 4.6.x). This
    # will typically produce a message for PowerShell v2 (just an info
    # message though)
    try {
        # Set TLS 1.2 (3072), then TLS 1.1 (768), then TLS 1.0 (192), finally SSL 3.0 (48)
        # Use integers because the enumeration values for TLS 1.2 and TLS 1.1 won't
        # exist in .NET 4.0, even though they are addressable if .NET 4.5+ is
        # installed (.NET 4.5 is an in-place upgrade).
        [System.Net.ServicePointManager]::SecurityProtocol = 3072 -bor 768 -bor 192 -bor 48
    }
    catch {
        Write-Warning 'Unable to set PowerShell to use TLS 1.2 and TLS 1.1 due to old .NET Framework installed. If you see underlying connection closed or trust errors, you may need to do one or more of the following: (1) upgrade to .NET Framework 4.5+ and PowerShell v3, (2) specify internal Chocolatey package location (set $env:chocolateyDownloadUrl prior to install or host the package internally), (3) use the Download + PowerShell method of install. See https://chocolatey.org/install for all install options.'
    }

    switch ($PSCmdlet.ParameterSetName) {
        'FromFeedUrl' {
            if ($PackageFeedUrl -and ![string]::IsNullOrEmpty($Version)){
                Write-Verbose "Downloading specific version of Chocolatey: $Version"
                $url = "$PackageFeedUrl/package/chocolatey/$Version"
            }
            else {
                if (![string]::IsNullOrEmpty($PackageFeedUrl)) {
                    $url = $PackageFeedUrl
                }
                else {
                    $url = 'https://chocolatey.org/api/v2'
                }
                Write-Verbose "Getting latest version of the Chocolatey package for download."
                $url = "$url/Packages()?`$filter=((Id%20eq%20%27chocolatey%27)%20and%20(not%20IsPrerelease))%20and%20IsLatestVersion"
                Write-Debug "Retrieving Binary URL from Package Metadata: $url"

                $GetRemoteStringParams = @{
                    url = $url
                }
                $GetRemoteStringParamsName = (get-command Get-RemoteString).parameters.keys
                $KeysForRemoteString = $PSBoundParameters.keys | Where-Object { $_ -in $GetRemoteStringParamsName}
                foreach ($key in $KeysForRemoteString ) {
                    Write-Debug "`tWith $key :: $($PSBoundParameters[$key])"
                    $null = $GetRemoteStringParams.Add($key ,$PSBoundParameters[$key])
                }
                [xml]$result = Get-RemoteString @GetRemoteStringParams
                Write-Debug "New URL for nupkg: $url"
                $url = $result.feed.entry.content.src
            }
        }
        'FromPackageUrl' {
            #ignores version
            Write-Verbose "Downloading Chocolatey from : $ChocolateyPackageUrl"
            $url = $ChocolateyPackageUrl
        }
    }

    if ($null -eq $env:TEMP) {
        $env:TEMP = Join-Path $Env:SYSTEMDRIVE 'temp'
    }

    $tempDir = [io.path]::Combine($Env:TEMP,'chocolatey','chocInstall')
    if (![System.IO.Directory]::Exists($tempDir)) {
        $null = New-Item -path $tempDir -ItemType Directory
    }
    $file = Join-Path $tempDir "chocolatey.zip"

    # Download the Chocolatey package
    Write-Verbose "Getting Chocolatey from $url."
    $GetRemoteFileParams = @{
        url = $url
        file = $file
    }
    $GetRemoteFileParamsName = (get-command Get-RemoteFile).parameters.keys
    $KeysForRemoteFile = $PSBoundParameters.keys | Where-Object { $_ -in $GetRemoteFileParamsName}
    foreach ($key in $KeysForRemoteFile ) {
        Write-Debug "`tWith $key :: $($PSBoundParameters[$key])"
        $null = $GetRemoteFileParams.Add($key ,$PSBoundParameters[$key])
    }
    $null = Get-RemoteFile @GetRemoteFileParams

    # unzip the package
    Write-Verbose "Extracting $file to $tempDir..."

    if ($PSVersionTable.PSVersion.Major -ge 5) {
        Expand-Archive -Path "$file" -DestinationPath "$tempDir" -Force
    }
    else {
        try {
            $shellApplication = new-object -com shell.application
            $zipPackage = $shellApplication.NameSpace($file)
            $destinationFolder = $shellApplication.NameSpace($tempDir)
            $destinationFolder.CopyHere($zipPackage.Items(),0x10)
        }
        catch {
            throw "Unable to unzip package using built-in compression. Error: `n $_"
        }
    }

    # Call chocolatey install
    Write-Verbose "Installing chocolatey on this machine."
    $TempTools = [io.path]::combine($tempDir,'tools')
    #   To be able to mock
    $chocInstallPS1 = Join-Path $TempTools 'chocolateyInstall.ps1'

    if ($InstallationDirectory) {
        [Environment]::SetEnvironmentVariable('ChocolateyInstall', $InstallationDirectory, 'Machine')
        [Environment]::SetEnvironmentVariable('ChocolateyInstall', $InstallationDirectory, 'Process')
    }
    & $chocInstallPS1 | Write-Debug

    Write-Verbose 'Ensuring chocolatey commands are on the path.'
    $chocoPath = [Environment]::GetEnvironmentVariable('ChocolateyInstall')
    if ($chocoPath -eq $null -or $chocoPath -eq '') {
        $chocoPath = "$env:ALLUSERSPROFILE\Chocolatey"
    }

    if (!(Test-Path ($chocoPath))) {
        $chocoPath = "$env:SYSTEMDRIVE\ProgramData\Chocolatey"
    }

    $chocoExePath = Join-Path $chocoPath 'bin'

    if ($($env:Path).ToLower().Contains($($chocoExePath).ToLower()) -eq $false) {
        $env:Path = [Environment]::GetEnvironmentVariable('Path',[System.EnvironmentVariableTarget]::Machine)
    }

    Write-Verbose 'Ensuring chocolatey.nupkg is in the lib folder'
    $chocoPkgDir = Join-Path $chocoPath 'lib\chocolatey'
    $nupkg = Join-Path $chocoPkgDir 'chocolatey.nupkg'
    $null = [System.IO.Directory]::CreateDirectory($chocoPkgDir)
    Copy-Item "$file" "$nupkg" -Force -ErrorAction SilentlyContinue

    if ($ChocoVersion = & "$chocoPath\choco.exe" -v) {
        Write-Verbose "Installed Chocolatey Version: $ChocoVersion"
    }
}

<#
.SYNOPSIS
    Register a new Chocolatey source or edit an existing one.

.DESCRIPTION
    Chocolatey will allow you to interact with sources.
    You can register a new source, whether internal or external with some source
    specific settings such as proxy.

.PARAMETER Name
    Name - the name of the source. Required with some actions. Defaults to empty.

.PARAMETER Source
    Source - The source. This can be a folder/file share or an http location.
    If it is a url, it will be a location you can go to in a browser and
    it returns OData with something that says Packages in the browser,
    similar to what you see when you go to https://chocolatey.org/api/v2/.
    Defaults to empty.

.PARAMETER Disabled
    Allow the source to be registered but disabled.

.PARAMETER BypassProxy
    Bypass Proxy - Should this source explicitly bypass any explicitly or
    system configured proxies? Defaults to false. Available in 0.10.4+.

.PARAMETER SelfService
    Allow Self-Service - Should this source be allowed to be used with self-
    service? Requires business edition (v1.10.0+) with feature
    'useBackgroundServiceWithSelfServiceSourcesOnly' turned on. Defaults to
    false. Available in 0.10.4+.

.PARAMETER Priority
    Priority - The priority order of this source as compared to other
    sources, lower is better. Defaults to 0 (no priority). All priorities
    above 0 will be evaluated first, then zero-based values will be
    evaluated in config file order. Available in 0.9.9.9+.

.PARAMETER Credential
    Credential used with authenticated feeds. Defaults to empty.

.PARAMETER Force
    Force - force the behavior. Do not use force during normal operation -
    it subverts some of the smart behavior for commands.

.PARAMETER CacheLocation
    CacheLocation - Location for download cache, defaults to %TEMP% or value
    in chocolatey.config file.

.PARAMETER NoProgress
    Do Not Show Progress - Do not show download progress percentages.
    Available in 0.10.4+.

.PARAMETER KeyUser
    API Key User for the source being registered.

.PARAMETER Key
    API key for the source (too long in C4B to be passed as credentials)

.EXAMPLE
    Register-ChocolateySource -Name MyNuget -Source https://proget/nuget/choco

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsSource
#>
function Register-ChocolateySource {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
        )]
        [System.String]
        $Name,

        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
        )]
        $Source,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $Disabled = $false,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $BypassProxy = $false,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $SelfService = $false,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [int]
        $Priority = 0,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [PSCredential]
        $Credential,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $Force,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $CacheLocation,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $NoProgress,

        #To be used when Password is too long (>240 char) like a key
        $KeyUser,
        $Key
    )

    Process {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        if (!$PSBoundParameters.containskey('Disabled')){
            $null = $PSBoundParameters.add('Disabled',$Disabled)
        }
        if (!$PSBoundParameters.containskey('SelfService')){
            $null = $PSBoundParameters.add('SelfService',$SelfService)
        }
        if (!$PSBoundParameters.containskey('BypassProxy')){
            $null = $PSBoundParameters.add('BypassProxy',$BypassProxy)
        }

        $ChocoArguments = @('source','add')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose "choco $($ChocoArguments -join ' ')"

        &$chocoCmd $ChocoArguments | Write-Verbose

        if ($Disabled) {
            &$chocoCmd @('source','disable',"-n=`"$Name`"") | Write-Verbose
        }
    }
}

<#
.SYNOPSIS
    Remove a Pin from a Chocolatey Package

.DESCRIPTION
    Allows you to remove a pinned Chocolatey Package like choco pin remove -n=packagename

.PARAMETER Name
    Name of the Chocolatey Package to remove the pin.

.EXAMPLE
    Remove-ChocolateyPin -Name 'PackageName'

.NOTES
    https://chocolatey.org/docs/commands-pin
#>
function Remove-ChocolateyPin {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        [Parameter(
            Mandatory
            , ValueFromPipelineByPropertyName
        )]
        [Alias('Package')]
        [System.String]
        $Name
    )

    Process {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        if (!(Get-ChocolateyPackage -Name $Name)) {
            Throw "The Pin for Chocolatey Package $Name cannot be found."
        }

        $ChocoArguments = @('pin', 'remove', '-r')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        # Write-Debug "choco $($ChocoArguments -join ' ')"

        if ($PSCmdlet.ShouldProcess("$Name", "Remove Pin")) {
            $Output = &$chocoCmd $ChocoArguments

            # LASTEXITCODE is always 0 unless point an existing version (0 when remove but already removed)
            if ($LASTEXITCODE -ne 0) {
                Throw ("Error when trying to remove Pin for {0}.`r`n {1}" -f "$Name", ($output -join "`r`n"))
            }
            else {
                $output | Write-Verbose
            }
        }
    }
}

<#
.SYNOPSIS
    Set or unset a Chocolatey Setting

.DESCRIPTION
    Allows you to set or unset the value of a Chocolatey setting usually accessed by choco config set -n=bob value

.PARAMETER Name
    Name (or setting) of the Chocolatey setting to modify

.PARAMETER Value
    Value to be given on the setting. This is not available when the switch -Unset is used.

.PARAMETER Unset
    Unset the setting, returning to the Chocolatey defaults.

.EXAMPLE
    Set-ChocolateySetting -Name 'cacheLocation' -value 'C:\Temp\Choco'

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsConfig
#>
function Set-ChocolateySetting {
    [CmdletBinding(
        SupportsShouldProcess
        ,ConfirmImpact='Low'
    )]
    [OutputType([Void])]
    param(
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
        )]
        [Alias('Setting')]
        [System.String]
        $Name,

        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
            ,ParameterSetName = 'Set'
        )]
        [AllowEmptyString()]
        [System.String]
        $Value,

        [Parameter(
            ValueFromPipelineByPropertyName
            ,ParameterSetName = 'Unset'
        )]
        [switch]
        $Unset
    )

    Process {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        $ChocoArguments = @('config')
        #Removing PSBoundParameters that could impact Chocolatey's "choco config set" command
        foreach ($key in @([System.Management.Automation.Cmdlet]::CommonParameters + [System.Management.Automation.Cmdlet]::OptionalCommonParameters)) {
            if ($PSBoundParameters.ContainsKey($key)) {
                $null = $PSBoundParameters.remove($key)
            }
        }

        if ($Unset -or [string]::IsNullOrEmpty($Value)) {
            if ($PSBoundParameters.ContainsKey('value')) { $null = $PSBoundParameters.Remove('Value') }
            $null = $PSBoundParameters.remove('unset')
            $ChocoArguments += 'unset'
        }
        else {
            $PSBoundParameters['Value'] = $ExecutionContext.InvokeCommand.ExpandString($Value).TrimEnd(@('/','\'))
            $ChocoArguments += 'set'
        }
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose "choco $($ChocoArguments -join ' ')"

        if ($PSCmdlet.ShouldProcess($Env:COMPUTERNAME,"$chocoCmd $($ChocoArguments -join ' ')")) {
            $cmdOut = &$chocoCmd $ChocoArguments
        }

        if ($cmdOut) {
            Write-Verbose "$($cmdOut | Out-String)"
        }
    }
}

<#
.SYNOPSIS
    Test Whether a feature is disabled, enabled or not found

.DESCRIPTION
    Some feature might not be available in your version or SKU.
    This command allows you to test the state of that feature.

.PARAMETER Name
    Name of the feature to verify

.PARAMETER Disabled
    Test if the feature is disabled, the default is to test if the feature is enabled.

.EXAMPLE
    Test-ChocolateyFeature -Name FeatureName -Disabled

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsFeature
#>
function Test-ChocolateyFeature {
    [CmdletBinding()]
    [outputType([Bool])]
    param(
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
        )]
        [Alias('Feature')]
        [System.String]
        $Name,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $Disabled
    )

    Process {
        if (-not (Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        if (!($Feature = Get-ChocolateyFeature -Name $Name)) {
            Write-Warning "Chocolatey Feature $Name cannot be found."
            return $false
        }
        $Feature | Write-Verbose
        if ($Feature.enabled -eq !$Disabled.ToBool()) {
            Write-Verbose ("The Chocolatey Feature {0} is set to {1} as expected." -f $Name,(@('Disabled','Enabled')[([int]$Disabled.ToBool())]))
            return $true
        }
        else {
            Write-Verbose ("The Chocolatey Feature {0} is NOT set to {1} as expected." -f $Name,(@('Disabled','Enabled')[([int]$Disabled.ToBool())]))
            return $False
        }
    }
}

<#
.SYNOPSIS
    Test if the Chocolatey Software is installed.

.DESCRIPTION
    To test whether the Chocolatey Software is installed, it first look for the Command choco.exe.
    It then check if it's installed in the InstallDir path, if provided.

.PARAMETER InstallDir
    To ensure the software is installed in the given directory. If not specified,
    it will only test if the commadn choco.exe is available.

.EXAMPLE
    Test-ChocolateyInstall #Test whether the Chocolatey Software is installed

.NOTES
General notes
#>
function Test-ChocolateyInstall
{
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstallDir
    )

    Write-Verbose "Loading machine Path Environment variable into session."
    $envPath = [Environment]::GetEnvironmentVariable('Path','Machine')
    [Environment]::SetEnvironmentVariable($envPath,'Process')

    if ($InstallDir) {
        $InstallDir = (Resolve-Path $InstallDir -ErrorAction Stop).Path
    }

    if ($chocoCmd = get-command choco.exe -CommandType Application -ErrorAction SilentlyContinue)
    {
        if (
            !$InstallDir -or
            $chocoCmd.Path -match [regex]::Escape($InstallDir)
        )
        {
            Write-Verbose ('Chocolatey Software found in {0}' -f $chocoCmd.Path)
            return $true
        }
        else
        {
            Write-Verbose (
                'Chocolatey Software not installed in {0}`n but in {1}' -f $InstallDir,$chocoCmd.Path
            )
            return $false
        }
    }
    else {
        Write-Verbose "Chocolatey Software not found."
        return $false
    }
}

<#
.SYNOPSIS
    Verify if a Chocolatey Package is installed locally

.DESCRIPTION
    Search and compare the Installed PackageName locally, and compare the provided property.
    The command return an object with the detailed properties, and a comparison between the installed version
    and the expected version.

.PARAMETER Name
    Exact name of the package to be testing against.

.PARAMETER Version
    Version expected of the package, or latest to compare against the latest version from a source.

.PARAMETER Source
    Source to compare the latest version against. It will retrieve the

.PARAMETER Credential
    Credential used with authenticated feeds. Defaults to empty.

.PARAMETER CacheLocation
    CacheLocation - Location for download cache, defaults to %TEMP% or value
    in chocolatey.config file.

.PARAMETER UpdateOnly
    Test if the package needs to be installed if absent.
    In Update Only mode, a package of lower version needs to be updated, but a package absent
    won't be installed.

.EXAMPLE
    Test-ChocolateyPackageIsInstalled -Name Chocolatey -Source https://chocolatey.org/api/v2

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsList
#>
function Test-ChocolateyPackageIsInstalled {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
    param(
        [Parameter(
            Mandatory
            , ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        $Source,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [PSCredential]
        $Credential,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $CacheLocation,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [switch]
        $UpdateOnly

    )

    Process {
        if (-not (Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        #if version latest verify against sources
        if (! ($InstalledPackages = @(Get-ChocolateyPackage -LocalOnly -Name $Name -Exact)) ) {
            Write-Verbose "Could not find Package $Name."
        }

        $SearchPackageParams = $PSBoundParameters
        $null = $SearchPackageParams.Remove('version')
        $null = $SearchPackageParams.Remove('UpdateOnly')

        if ($Version -eq 'latest') {
            $ReferenceObject = Get-ChocolateyPackage @SearchPackageParams -Exact
            if (!$ReferenceObject) {
                Throw "Latest version of Package $name not found. Verify that the sources are reachable and package exists."
            }
        }
        else {
            $ReferenceObject = [PSCustomObject]@{
                Name = $Name
            }
            if ($Version) { $ReferenceObject | Add-Member -MemberType NoteProperty -Name version -value $Version }
        }

        $PackageFound = $false
        $MatchingPackages = $InstalledPackages | Where-Object {
            Write-Debug "Testing $($_.Name) against $($ReferenceObject.Name)"
            if ($_.Name -eq $ReferenceObject.Name) {
                $PackageFound = $True
                Write-Debug "Package Found"

                if (!$Version) {
                    return $true
                }
                elseif ((Compare-SemVerVersion $_.version $ReferenceObject.version) -in @('=', '>')) {
                    return $true
                }
                else {
                    return $false
                }
            }
        }

        if ($MatchingPackages) {
            Write-Verbose ("'{0}' packages match the given properties." -f $MatchingPackages.Count)
            $VersionGreaterOrEqual = $true
        }
        elseif ($PackageFound -and $UpdateOnly) {
            Write-Verbose "This package is installed with a lower version than specified."
            $VersionGreaterOrEqual = $false
        }
        elseif (!$PackageFound -and $UpdateOnly) {
            Write-Verbose "No packages match the selection, but no need to Install."
            $VersionGreaterOrEqual = $true
        }
        else {
            Write-Verbose "No packages match the selection and need Installing."
            $VersionGreaterOrEqual = $False
        }

        Write-Output ([PSCustomObject]@{
                PackagePresent        = $PackageFound
                VersionGreaterOrEqual = $VersionGreaterOrEqual
            })
    }
}

<#
.SYNOPSIS
    Test whether a package is set, enabled or not found

.DESCRIPTION
    This command allows you to test the values of a pinned package.

.PARAMETER Name
    Name of the Package to verify

.PARAMETER Version
    Test if the Package version provided matches with the one set on the config file.

.EXAMPLE
    Test-ChocolateyPin -Name PackageName -Version ''

.NOTES
    https://chocolatey.org/docs/commands-pin
#>
function Test-ChocolateyPin {
    [CmdletBinding(
        DefaultParameterSetName = 'Set'
    )]
    [OutputType([Bool])]
    param(
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [System.String]
        $Name,

        [System.String]
        $Version
    )

    Process {
        if (-not (Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        if (!($Setting = Get-ChocolateyPin -Name $Name)) {
            Write-Verbose -Message "The Pin for the Chocolatey Package '$Name' cannot be found."
            return $false
        }

        $Version = $ExecutionContext.InvokeCommand.ExpandString($Version).TrimEnd(@('/','\'))
        if ([string]$Setting.Version -eq $Version) {
            Write-Verbose ("The Pin for the Chocolatey Package '{0}' is set to '{1}' as expected." -f $Name, $Version)
            return $true
        }
        else {
            Write-Verbose ("The Pin for the Chocolatey Package '{0}' is NOT set to '{1}' as expected." -f $Name, $Setting.Version)
            return $False
        }
    }
}

<#
.SYNOPSIS
    Test Whether a setting is set, enabled or not found

.DESCRIPTION
    Some settings might not be available in your version or SKU.
    This command allows you to test the values of a named setting.

.PARAMETER Name
    Name of the Setting to verify

.PARAMETER Value
    Test if the Setting value provided matches with the one set on the config file.

.PARAMETER Unset
    Test if the Setting is disabled, the default is to test if the feature is enabled.

.EXAMPLE
    Test-ChocolateySetting -Name SettingName -value ''

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsConfig
#>
function Test-ChocolateySetting {
    [CmdletBinding(
        DefaultParameterSetName = 'Set'
    )]
    [OutputType([Bool])]
    param(
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
        )]
        [Alias('Setting')]
        [System.String]
        $Name,

        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
            ,ParameterSetName = 'Set'
        )]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String]
        $Value,

        [Parameter(
            ValueFromPipelineByPropertyName
            ,ParameterSetName = 'Unset'
        )]
        [switch]
        $Unset
    )

    Process {
        if (-not (Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        if (!($Setting = Get-ChocolateySetting -Name $Name)) {
            Write-Warning "Chocolatey Setting $Name cannot be found."
            return $false
        }
        $Setting | Write-Verbose
        if ($Unset) {
            $Value = ''
        }

        $Value = $ExecutionContext.InvokeCommand.ExpandString($Value).TrimEnd(@('/','\'))
        if ([string]$Setting.value -eq $Value) {
            Write-Verbose ("The Chocolatey Setting {0} is set to '{1}' as expected." -f $Name,$Value)
            return $true
        }
        else {
            Write-Verbose ("The Chocolatey Setting {0} is NOT set to '{1}' as expected:{2}" -f $Name,$Setting.value,$Value)
            return $False
        }
    }
}

<#
.SYNOPSIS
    Verify the source settings matches the given parameters.

.DESCRIPTION
    This command compares the properties of the source found by name, with the parameters given.

.PARAMETER Name
    Name - the name of the source to find for comparison.

.PARAMETER Source
    Source - The source. This can be a folder/file share or an http location.
    If it is a url, it will be a location you can go to in a browser and
    it returns OData with something that says Packages in the browser,
    similar to what you see when you go to https://chocolatey.org/api/v2/.
    Defaults to empty.

.PARAMETER Disabled
    Test whether the source to is registered but disabled.
    By default it checks if enabled.

.PARAMETER BypassProxy
    Bypass Proxy - Is this source explicitly bypass any explicitly or
    system configured proxies? Defaults to false. Available in 0.10.4+.

.PARAMETER SelfService
    Is Self-Service ? - Is this source be allowed to be used with self-
    service? Requires business edition (v1.10.0+) with feature
    'useBackgroundServiceWithSelfServiceSourcesOnly' turned on. Defaults to
    false. Available in 0.10.4+.

.PARAMETER Priority
    Priority - The priority order of this source as compared to other
    sources, lower is better. Defaults to 0 (no priority). All priorities
    above 0 will be evaluated first, then zero-based values will be
    evaluated in config file order. Available in 0.9.9.9+.

.PARAMETER Credential
    Validate Credential used with authenticated feeds.

.PARAMETER KeyUser
    API Key User for the registered source.

.PARAMETER Key
    API Key for the registered source (used instead of credential when password length > 240 char).

.EXAMPLE
    Test-ChocolateySource -source https://chocolatey.org/api/v2 -priority 0

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsSource
#>
function Test-ChocolateySource {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
        )]
        [System.String]
        $Name,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        $Source,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $Disabled,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $BypassProxy,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SelfService,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [int]
        $Priority = 0,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [PSCredential]
        $Credential,

        #To be used when Password is too long (>240 char) like a key
        $KeyUser,
        $Key
    )

    Process {
        if (-not (Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        if (-not ($Source = (Get-ChocolateySource -Name $Name)) ) {
            Write-Verbose "Chocolatey Source $Name cannot be found."
            Return $false
        }

        $ReferenceSource = [PSCustomObject]@{}
        foreach ( $Property in $PSBoundParameters.keys.where{
            $_ -notin ([System.Management.Automation.Cmdlet]::CommonParameters + [System.Management.Automation.Cmdlet]::OptionalCommonParameters)}
        )
        {
            if ($Property -notin @('Credential','Key','KeyUser')) {
                $MemberParams = @{
                    MemberType = 'NoteProperty'
                    Name = $Property
                    Value = $PSboundParameters[$Property]
                }
                $ReferenceSource | Add-Member @MemberParams
            }
            else {
                if ($Credential) {
                    $Username = $Credential.UserName
                }
                else {
                    $Username = $KeyUser
                }
                $PasswordParam = @{
                    MemberType = 'NoteProperty'
                    Name       = 'password'
                    Value      = 'Reference Object Password'
                }
                $UserNameParam = @{
                    MemberType = 'NoteProperty'
                    Name       = 'username'
                    Value      = $UserName
                }
                $ReferenceSource | Add-Member @PasswordParam -passthru | Add-Member @UserNameParam

                $securePasswordStr = $Source.Password
                $SecureStr = [System.Convert]::FromBase64String($SecurePasswordStr)
                $salt = [System.Text.Encoding]::UTF8.GetBytes("Chocolatey")
                $PasswordBytes = [Security.Cryptography.ProtectedData]::Unprotect($SecureStr, $salt, [Security.Cryptography.DataProtectionScope]::LocalMachine)
                $PasswordInFile = [system.text.encoding]::UTF8.GetString($PasswordBytes)

                if ($Credential) {
                    $PasswordParameter = $Credential.GetNetworkCredential().Password
                }
                else {
                    $PasswordParameter = $Key
                }

                if ($PasswordInFile -eq $PasswordParameter) {
                    Write-Verbose "The Passwords Match."
                    $Source.Password = 'Reference Object Password'
                }
                else {
                    Write-Verbose "The Password Do not Match."
                    $Source.Password = 'Source Object Password'
                }
            }
        }
        Compare-Object -ReferenceObject $ReferenceSource -DifferenceObject $Source -Property $ReferenceSource.PSObject.Properties.Name
    }
}

<#
.SYNOPSIS
    Attempts to remove the Chocolatey Software form the system.

.DESCRIPTION
    This command attempts to clean the system from the Chocolatey Software files.
    It first look into the provided $InstallDir, or in the $Env:ChocolateyInstall if not provided.
    If the $InstallDir provided is $null or empty, it will attempts to find the Chocolatey folder
    from the choco.exe command path.
    If no choco.exe is found under the $InstallDir, it will fail to uninstall.
    This command also remove the $InstallDir from the Path.

.PARAMETER InstallDir
    Installation Directory to remove Chocolatey from. Default looks up in $Env:ChocolateyInstall
    Or, if specified with an empty/$null value, tries to find from the choco.exe path.

.EXAMPLE
    Uninstall-Chocolatey -InstallDir ''
    Will uninstall Chocolatey from the location of Choco.exe if found from $Env:PATH
#>
function Uninstall-Chocolatey {
    [CmdletBinding(
        SupportsShouldProcess
    )]
    param(
        [AllowNull()]
        [System.String]
        $InstallDir = $Env:ChocolateyInstall
    )

    Process {
        #If InstallDir is empty or null, select from whee choco.exe is available

        if (-not $InstallDir) {
            Write-Debug "Attempting to find the choco.exe command."
            $chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue
            #Install dir is where choco.exe is found minus \bin subfolder
            if (-not ($chocoCmd -and ($chocoBin = Split-Path -Parent $chocoCmd.Path -ErrorAction SilentlyContinue))) {
                Write-Warning "Could not find Chocolatey Software Install Folder."
                return
            }
            else {
                Write-Debug "Resolving $chocoBin\.."
                $InstallDir = (Resolve-Path ([io.path]::combine($chocoBin,'..'))).Path
            }
        }
        Write-Verbose "Chocolatey Installation Folder is $InstallDir"

        $chocoFiles = @('choco.exe','chocolatey.exe','cinst.exe','cuninst.exe','clist.exe','cpack.exe','cpush.exe',
        'cver.exe','cup.exe').Foreach{$_;"$_.old"} #ensure the .old are also removed

        #If Install dir does not have a choco.exe, do nothing as it could delete unwanted files
        if (
            [string]::IsNullOrEmpty($InstallDir) -or
            -not ((Test-Path $InstallDir) -and (Test-Path "$InstallDir\Choco.exe"))
             )
        {
            Write-Warning 'Chocolatey Installation Folder Not found.'
            return
        }

        #all files under $InstallDir
        # Except those in $InstallDir\lib unless $_.Basename -in $chocoFiles
        # Except those in $installDir\bin unless $_.Basename -in $chocoFiles
        $FilesToRemove = Get-ChildItem $InstallDir -Recurse | Where-Object {
            -not (
                (
                    $_.FullName -match [regex]::escape([io.path]::combine($InstallDir,'lib')) -or
                    $_.FullName -match [regex]::escape([io.path]::combine($InstallDir,'bin'))
                ) -and
                $_.Name -notin $chocofiles
            )
        }

        Write-Debug ($FilesToRemove -join "`r`n>>  ")

        if ($Pscmdlet.ShouldProcess('Chocofiles')) {
            $FilesToRemove | Sort-Object -Descending FullName | remove-item -Force -recurse -ErrorAction SilentlyContinue
        }

        Write-Verbose "Removing $InstallDir from the Path and the ChocolateyInstall Environment variable."
        [Environment]::SetEnvironmentVariable('ChocolateyInstall', $null, 'Machine')
        $Env:ChocolateyInstall = $null
        $AllPaths = [Environment]::GetEnvironmentVariable('Path','machine').split(';').where{
                        ![string]::IsNullOrEmpty($_) -and
                        $_ -notmatch "^$([regex]::Escape($InstallDir))\\bin$"
                    } | Select-Object -unique

        Write-Debug 'Reset the machine Path without choco (and dedupe/no null).'
        Write-Debug ($AllPaths |Format-Table | Out-String)
        [Environment]::SetEnvironmentVariable('Path', ($AllPaths -Join ';'), 'Machine')

        #refresh after uninstall
        $envPath = [Environment]::GetEnvironmentVariable('Path','Machine')
        [Environment]::SetEnvironmentVariable($EnvPath,'process')
        Write-Verbose 'Unistallation complete'
    }
}

<#
.SYNOPSIS
    Uninstalls a Chocolatey package or a list of packages.

.DESCRIPTION
    Once the Chocolatey Software has been installed (see Install-ChocolateySoftware) this command
    allows you to uninstall Software installed by Chocolatey,
    or synced from Add-remove program (Business edition).

.PARAMETER Name
    Package Name to uninstall, either from a configured source, a specified one such as a folder,
    or the current directory '.'

.PARAMETER Version
    Version - A specific version to install.

.PARAMETER Source
    Source - The source to find the package(s) to install. Special sources
    include: ruby, webpi, cygwin, windowsfeatures, and python. To specify
    more than one source, pass it with a semi-colon separating the values (-
    e.g. "'source1;source2'"). Defaults to default feeds.

.PARAMETER Credential
    Credential used with authenticated feeds. Defaults to empty.

.PARAMETER Force
    Force - force the behavior. Do not use force during normal operation -
    it subverts some of the smart behavior for commands.

.PARAMETER CacheLocation
    CacheLocation - Location for download cache, defaults to %TEMP% or value
    in chocolatey.config file.

.PARAMETER NoProgress
    Do Not Show Progress - Do not show download progress percentages.
    Available in 0.10.4+.

.PARAMETER AcceptLicense
    AcceptLicense - Accept license dialogs automatically. Reserved for future use.

.PARAMETER Timeout
    CommandExecutionTimeout (in seconds) - The time to allow a command to
    finish before timing out. Overrides the default execution timeout in the
    configuration of 2700 seconds. '0' for infinite starting in 0.10.4.

.PARAMETER UninstallArguments
    UninstallArguments - Uninstall Arguments to pass to the native installer
    in the package. Defaults to unspecified.

.PARAMETER OverrideArguments
    OverrideArguments - Should uninstall arguments be used exclusively
    without appending to current package passed arguments? Defaults to false.

.PARAMETER NotSilent
    NotSilent - Do not uninstall this silently. Defaults to false.

.PARAMETER ApplyArgsToDependencies
    Apply Install Arguments To Dependencies  - Should install arguments be
    applied to dependent packages? Defaults to false.

.PARAMETER SideBySide
    AllowMultipleVersions - Should multiple versions of a package be
    installed? Defaults to false.

.PARAMETER IgnoreDependencies
    IgnoreDependencies - Ignore dependencies when installing package(s).
    Defaults to false.

.PARAMETER ForceDependencies
    RemoveDependencies - Uninstall dependencies when uninstalling package(s).
    Defaults to false.

.PARAMETER SkipPowerShell
    Skip Powershell - Do not run chocolateyUninstall.ps1. Defaults to false.

.PARAMETER ignorePackageCodes
    IgnorePackageExitCodes - Exit with a 0 for success and 1 for non-succes-s,
    no matter what package scripts provide for exit codes. Overrides the
    default feature 'usePackageExitCodes' set to 'True'. Available in 0.9.10+.

.PARAMETER UsePackageCodes
    UsePackageExitCodes - Package scripts can provide exit codes. Use those
    for choco's exit code when non-zero (this value can come from a
    dependency package). Chocolatey defines valid exit codes as 0, 1605,
    1614, 1641, 3010. Overrides the default feature 'usePackageExitCodes'
    set to 'True'.
    Available in 0.9.10+.

.PARAMETER StopOnFirstFailure
    Stop On First Package Failure - stop running install, upgrade or
    uninstall on first package failure instead of continuing with others.
    Overrides the default feature 'stopOnFirstPackageFailure' set to 'False'.
    Available in 0.10.4+.

.PARAMETER AutoUninstaller
    UseAutoUninstaller - Use auto uninstaller service when uninstalling.
    Overrides the default feature 'autoUninstaller' set to 'True'.
    Available in 0.9.10+.

.PARAMETER SkipAutoUninstaller
    SkipAutoUninstaller - Skip auto uninstaller service when uninstalling.
    Overrides the default feature 'autoUninstaller' set to 'True'. Available
    in 0.9.10+.

.PARAMETER FailOnAutouninstaller
    FailOnAutoUninstaller - Fail the package uninstall if the auto
    uninstaller reports and error. Overrides the default feature
    'failOnAutoUninstaller' set to 'False'. Available in 0.9.10+.

.PARAMETER IgnoreAutoUninstallerFailure
    Ignore Auto Uninstaller Failure - Do not fail the package if auto
    uninstaller reports an error. Overrides the default feature
    'failOnAutoUninstaller' set to 'False'. Available in 0.9.10+.

.EXAMPLE
    Uninstall-ChocolateyPackage -Name Putty

.NOTES
    https://github.com/chocolatey/choco/wiki/Commandsuninstall
#>
function Uninstall-ChocolateyPackage {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact='High'
    )]
    Param(
        [Parameter(
            Mandatory
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
        )]
        [System.String[]]
        $Name,

        [Parameter(
            ,ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        $Source,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [PSCredential]
        $Credential,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $Force,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $CacheLocation,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $NoProgress,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $AcceptLicense,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [int]
        $Timeout,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $UninstallArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $OverrideArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $NotSilent,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ApplyArgsToDependencies,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SideBySide,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IgnoreDependencies,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ForceDependencies,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SkipPowerShell,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ignorePackageCodes,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $UsePackageCodes,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $StopOnFirstFailure,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $AutoUninstaller,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SkipAutoUninstaller,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $FailOnAutouninstaller,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IgnoreAutoUninstallerFailure
    )

    begin {
        $null = $PSboundParameters.remove('Name')
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }
        $CachePath = [io.path]::Combine($Env:ChocolateyInstall,'cache','GetChocolateyPackageCache.xml')
        if ( (Test-Path $CachePath)) {
            $null = Remove-Item $CachePath -ErrorAction SilentlyContinue
        }
    }
    Process {
        foreach ($PackageName in $Name) {
            $ChocoArguments = @('uninstall',$PackageName)
            $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
            Write-Verbose "choco $($ChocoArguments -join ' ')"

            if ($PSCmdlet.ShouldProcess($PackageName,"Uninstall")) {
                #Impact confirmed, go choco go!
                $ChocoArguments += '-y'
                &$chocoCmd $ChocoArguments | Write-Verbose
            }
        }
    }
}

<#
.SYNOPSIS
    Unregister a Chocolatey source from the Chocolatey Configuration.

.DESCRIPTION
    Chocolatey will allow you to interact with sources.
    You can unregister an existing source.

.PARAMETER Name
    Name - the name of the source to be delete.

.PARAMETER Source
    Source - The source. This can be a folder/file share or an http location.
    If it is a url, it will be a location you can go to in a browser and
    it returns OData with something that says Packages in the browser,
    similar to what you see when you go to https://chocolatey.org/api/v2/.

.PARAMETER Disabled
    The source to be unregistered is disabled.

.PARAMETER BypassProxy
    Bypass Proxy - Should this source explicitly bypass any explicitly or
    system configured proxies? Defaults to false. Available in 0.10.4+.

.PARAMETER SelfService
    Allow Self-Service - The source to be delete is allowed to be used with self-
    service. Requires business edition (v1.10.0+) with feature
    'useBackgroundServiceWithSelfServiceSourcesOnly' turned on.
    Available in 0.10.4+.

.PARAMETER Priority
    Priority - The priority order of this source as compared to other
    sources, lower is better. Defaults to 0 (no priority). All priorities
    above 0 will be evaluated first, then zero-based values will be
    evaluated in config file order. Available in 0.9.9.9+.

.PARAMETER Credential
    Credential used with authenticated feeds. Defaults to empty.

.PARAMETER Force
    Force - force the behavior. Do not use force during normal operation -
    it subverts some of the smart behavior for commands.

.PARAMETER CacheLocation
    CacheLocation - Location for download cache, defaults to %TEMP% or value
    in chocolatey.config file.

.PARAMETER NoProgress
    Do Not Show Progress - Do not show download progress percentages.
    Available in 0.10.4+.

.EXAMPLE
    Unregister-ChocolateySource -Name MyProgetFeed

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsSource
#>
function Unregister-ChocolateySource {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
        )]
        [System.String]
        $Name,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        $Source,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $Disabled,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $BypassProxy,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SelfService,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [int]
        $Priority = 0,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [PSCredential]
        $Credential,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $Force,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $CacheLocation,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $NoProgress

    )

    Process {
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }

        if (!(Get-ChocolateySource -Name $Name)) {
            Throw "Chocolatey Source $Name cannot be found. You can Register it using Register-ChocolateySource."
        }

        $ChocoArguments = @('source','remove')
        $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
        Write-Verbose "choco $($ChocoArguments -join ' ')"

        &$chocoCmd $ChocoArguments | Write-Verbose
    }
}

<#
.SYNOPSIS
    Updates the Chocolatey package to the latest version.

.DESCRIPTION
    Upgrades a package or a list of packages to the latest version available on the source(s).
    If you do not have a package installed, upgrade will install it.

.PARAMETER Name
    Package Name to install, either from a configured source, a specified one such as a folder,
    or the current directory '.'

.PARAMETER Version
    Version - A specific version to install. Defaults to unspecified.

.PARAMETER Source
    Source - The source to find the package(s) to install. Special sources
    include: ruby, webpi, cygwin, windowsfeatures, and python. To specify
    more than one source, pass it with a semi-colon separating the values (-
    e.g. "'source1;source2'"). Defaults to default feeds.

.PARAMETER Credential
    Credential used with authenticated feeds. Defaults to empty.

.PARAMETER Force
    Force - force the behavior. Do not use force during normal operation -
    it subverts some of the smart behavior for commands.

.PARAMETER CacheLocation
    CacheLocation - Location for download cache, defaults to %TEMP% or value
    in chocolatey.config file.

.PARAMETER NoProgress
    Do Not Show Progress - Do not show download progress percentages.
    Available in 0.10.4+.

.PARAMETER AcceptLicense
    AcceptLicense - Accept license dialogs automatically. Reserved for future use.

.PARAMETER Timeout
    CommandExecutionTimeout (in seconds) - The time to allow a command to
    finish before timing out. Overrides the default execution timeout in the
    configuration of 2700 seconds. '0' for infinite starting in 0.10.4.

.PARAMETER x86
    ForceX86 - Force x86 (32bit) installation on 64 bit systems. Defaults to false.

.PARAMETER InstallArguments
    InstallArguments - Install Arguments to pass to the native installer in
    the package. Defaults to unspecified.

.PARAMETER InstallArgumentsSensitive
    InstallArgumentsSensitive - Install Arguments to pass to the native
    installer in the package that are sensitive and you do not want logged.
    Defaults to unspecified.
    Available in 0.10.1+. [Licensed editions](https://chocolatey.org/compare) only.

.PARAMETER PackageParameters
    PackageParameters - Parameters to pass to the package,
    that should be handled by the ChocolateyInstall.ps1

.PARAMETER PackageParametersSensitive
    PackageParametersSensitive - Package Parameters to pass the package that
    are sensitive and you do not want logged. Defaults to unspecified.
    Available in 0.10.1+. [Licensed editions](https://chocolatey.org/compare) only.

.PARAMETER OverrideArguments
    OverrideArguments - Should install arguments be used exclusively without
    appending to current package passed arguments? Defaults to false.

.PARAMETER NotSilent
    NotSilent - Do not install this silently. Defaults to false.

.PARAMETER ApplyArgsToDependencies
    Apply Install Arguments To Dependencies  - Should install arguments be
    applied to dependent packages? Defaults to false.

.PARAMETER AllowDowngrade
    AllowDowngrade - Should an attempt at downgrading be allowed? Defaults to false.

.PARAMETER SideBySide
    AllowMultipleVersions - Should multiple versions of a package be
    installed? Defaults to false.

.PARAMETER IgnoreDependencies
    IgnoreDependencies - Ignore dependencies when installing package(s).
    Defaults to false.

.PARAMETER ForceDependencies
    ForceDependencies - Force dependencies to be reinstalled when force
    installing package(s). Must be used in conjunction with --force.
    Defaults to false.

.PARAMETER SkipPowerShell
    Skip Powershell - Do not run chocolateyInstall.ps1. Defaults to false.

.PARAMETER IgnoreChecksum
    IgnoreChecksums - Ignore checksums provided by the package. Overrides
    the default feature 'checksumFiles' set to 'True'. Available in 0.9.9.9+.

.PARAMETER AllowEmptyChecksum
    Allow Empty Checksums - Allow packages to have empty/missing checksums
    for downloaded resources from non-secure locations (HTTP, FTP). Use this
    switch is not recommended if using sources that download resources from
    the internet. Overrides the default feature 'allowEmptyChecksums' set to
    'False'. Available in 0.10.0+.

.PARAMETER ignorePackageCodes
    IgnorePackageExitCodes - Exit with a 0 for success and 1 for non-success,
    no matter what package scripts provide for exit codes. Overrides the
    default feature 'usePackageExitCodes' set to 'True'. Available in 0.-9.10+.

.PARAMETER UsePackageCodes
    UsePackageExitCodes - Package scripts can provide exit codes. Use those
    for choco's exit code when non-zero (this value can come from a
    dependency package). Chocolatey defines valid exit codes as 0, 1605,
    1614, 1641, 3010.  Overrides the default feature 'usePackageExitCodes'
    set to 'True'. Available in 0.9.10+.

.PARAMETER StopOnFirstFailure
    Stop On First Package Failure - stop running install, upgrade or
    uninstall on first package failure instead of continuing with others.
    Overrides the default feature 'stopOnFirstPackageFailure' set to 'False'.
    Available in 0.10.4+.

.PARAMETER UseRememberedArguments
    Use Remembered Options for Upgrade - use the arguments and options used
    during install for upgrade. Does not override arguments being passed at
    runtime. Overrides the default feature
    'useRememberedArgumentsForUpgrades' set to 'False'. Available in 0.10.4+.

.PARAMETER IgnoreRememberedArguments
    Ignore Remembered Options for Upgrade - ignore the arguments and options
    used during install for upgrade. Overrides the default feature
    'useRememberedArgumentsForUpgrades' set to 'False'. Available in 0.10.4+.

.PARAMETER ExcludePrerelease
    Exclude Prerelease - Should prerelease be ignored for upgrades? Will be
    ignored if you pass `--pre`. Available in 0.10.4+.

.EXAMPLE
    Update-ChocolateyPackage -Name All

.NOTES
    https://github.com/chocolatey/choco/wiki/CommandsUpgrade
#>
function Update-ChocolateyPackage {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact='High'
    )]
    param(
        [Parameter(
            Mandatory
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
        )]
        [System.String[]]
        $Name,

        [Parameter(
            ,ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        $Source,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [PSCredential]
        $Credential,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $Force,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $CacheLocation,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $NoProgress,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $AcceptLicense,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [int]
        $Timeout,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $x86,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $InstallArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $InstallArgumentsSensitive,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $PackageParameters,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [System.String]
        $PackageParametersSensitive,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $OverrideArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $NotSilent,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ApplyArgsToDependencies,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $AllowDowngrade,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SideBySide,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IgnoreDependencies,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ForceDependencies,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $SkipPowerShell,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IgnoreChecksum,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $AllowEmptyChecksum,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ignorePackageCodes,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $UsePackageCodes,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $StopOnFirstFailure,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $UseRememberedArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $IgnoreRememberedArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
        )]
        [Switch]
        $ExcludePrerelease
    )

    begin {
        $null = $PSboundParameters.remove('Name')
        if (-not ($chocoCmd = Get-Command 'choco.exe' -CommandType Application -ErrorAction SilentlyContinue)) {
            Throw "Chocolatey Software not found."
        }
        $CachePath = [io.path]::Combine($Env:ChocolateyInstall,'cache','GetChocolateyPackageCache.xml')
        if ( (Test-Path $CachePath)) {
            $null = Remove-Item $CachePath -ErrorAction SilentlyContinue
        }
    }

    Process {
        foreach ($PackageName in $Name) {
            $ChocoArguments = @('upgrade',$PackageName)
            $ChocoArguments += Get-ChocolateyDefaultArgument @PSBoundParameters
            Write-Verbose "choco $($ChocoArguments -join ' ')"

            if ($PSCmdlet.ShouldProcess($PackageName,"Upgrade")) {
                #Impact confirmed, go choco go!
                $ChocoArguments += '-y'
                &$chocoCmd $ChocoArguments | Write-Verbose
            }
        }
    }
}


