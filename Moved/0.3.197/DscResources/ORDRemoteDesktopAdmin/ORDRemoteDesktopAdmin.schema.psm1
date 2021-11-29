#configuration ORD_RDA
# When this is named the same as the file/folder, it shows up in Get-DSCResource -name ordremotedesktopadmin! 4/1/21
configuration ORDRemoteDesktopAdmin
{
    param
    (
        [Parameter(Mandatory)]
        [hashtable[]]
        $ORD_RDA
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc

    foreach ($disk in $ORD_RDA.GetEnumerator())
    #foreach ($disk in $ORD_RDA)
    {
        #$disk.IsSingleInstance = 'Yes'
        #$disk.Ensure = 'Present'
        #$disk.UserAuthentication = 'Secure'
        if (-not $disk.ContainsKey('IsSingleInstance')) {
            $disk.IsSingleInstance = 'Yes'
        }
        if (-not $disk.ContainsKey('Ensure')) {
            $disk.Ensure = 'Present'
        }
        if (-not $disk.ContainsKey('UserAuthentication')) {
            $disk.UserAuthentication = 'Secure'
        }

        #$executionName = $disk.id
        $executionName = 'RDA'
        (Get-DscSplattedResource -ResourceName RemoteDesktopAdmin -ExecutionName $executionName -Properties $disk -NoInvoke).Invoke($disk)
    }
}
