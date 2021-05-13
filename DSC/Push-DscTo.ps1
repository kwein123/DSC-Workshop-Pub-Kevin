<#
.SYNOPSIS
    Push pre-built DSC config to target server
.TITLE
    Push-DscTo.ps1
.DESCRIPTION
	Force target server into new DSC config
.PARAMETERS
	[-SourceRoot e:\chiz\dsc\Try2\DscWorkshop\DSC]
	-Computer v26267ncec201
.NOTES

.AUTHOR
	Kevin Weinrich, Vision Technologies
#>

[CmdletBinding()]
Param(
	[string]$Computer = 'v26267ncec201'
	,[string]$SourceRoot = '.' # 'e:\chiz\dsc\Try2\DscWorkshop\DSC'
)
# StrictMode has to come after CmdletBinding
Set-StrictMode -version 2

# If variable doesn't exist, set up a new connection
if (!(get-variable cimsessionTarget -erroraction SilentlyContinue)) {
	$cimsessionTarget = new-CimSession $Computer
}
# What does the LCM look like before we start?
Get-DscLocalConfigurationManager -CimSession $cimsessionTarget

# Push LCM config
Write-Host "SourceRoot $SourceRoot"
Set-DscLocalConfigurationManager -Path $SourceRoot\BuildOutput\MetaMof -Verbose -CimSession $cimsessionTarget
# What does the LCM look like after we have pushed it?
Get-DscLocalConfigurationManager -CimSession $cimsessionTarget

# Push DSC config
if (!(get-variable pssessionTarget -erroraction SilentlyContinue) -or ($pssessionTarget.state -ne 'open')) {
	$pssessionTarget = New-PSSession $Computer
}
#"Here are the WithModule modules"
#Get-ModuleFromFolder c:\users\kevin.weinrich\Documents\WindowsPowerShell\Modules
#"End modules"

Push-DscConfiguration -session $pssessionTarget -MOF $SourceRoot\BuildOutput\MOF\$Computer.mof `
 -DSCBuildOutputModules $SourceRoot\BuildOutput\Modules -RemoteStagingPath C:\temp -Verbose `
 -WithModule (Get-ModuleFromFolder $SourceRoot\DscResources) -Confirm:$false

 #-Confirm:$false

# Push-DscConfiguration -session $pssessionTarget -MOF $SourceRoot\BuildOutput\MOF\$Computer.mof `
# -DSCBuildOutputModules $SourceRoot\BuildOutput\Modules -RemoteStagingPath C:\temp -Verbose `
# -WithModule (Get-ModuleFromFolder c:\users\kevin.weinrich\Documents\WindowsPowerShell\Modules) -Confirm:$false

# -WithModule (Get-ModuleFromFolder c:\users\kevin.weinrich\Documents\WindowsPowerShell\Modules) -Confirm:$false

# What does the LCM look like after we have pushed the DSC?
Get-DscLocalConfigurationManager -CimSession $cimsessionTarget
