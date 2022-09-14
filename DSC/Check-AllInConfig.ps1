<#
.SYNOPSIS
   Check that all current DSC-configured servers are in correct config
.TITLE
    Check-AllInConfig.ps1
.DESCRIPTION
	Loop over all servers with .MOF files, check their DSC config status
.PARAMETERS
.NOTES
	Must run in old PowerShell for now, not pwsh
	powershell -executionpolicy bypass # Or else we won't
.AUTHOR
	Kevin Weinrich, Vision Technologies
#>

[CmdletBinding()]
Param(
	[Alias("Computer","MachineName")]
	[string]$Server = ''
	,[switch]$All = $false
)
# StrictMode has to come after CmdletBinding
Set-StrictMode -version 2

if ($All) {
	# Try every server for which we have a file in this folder
	$Servers = (Get-ChildItem .\dscconfigdata\backup-dns-2019\*.yml).Name -replace '.yml'
	$Servers += (Get-ChildItem .\dscconfigdata\backup-dns-2016\*.yml).Name -replace '.yml'
} else {
	if ($Server -eq '') {
		$Servers = (Get-ChildItem .\BuildOutput\MOF\*.mof).Name -replace '.mof'
	} else {
		$Servers = @($Server)
	}
}
foreach ($Server in $Servers) {
	"Checking $Server"
	$cim = new-CimSession $Server
	#$cim
	$config = Get-DscConfigurationStatus -CimSession $cim
	#"post config"
	$config.ResourcesNotInDesiredState
}
