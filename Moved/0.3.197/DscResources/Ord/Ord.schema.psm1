configuration Ord
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $InterfaceAlias,
        [Parameter(Mandatory)]
        [string]
        $IPAddress,
        [string]
        $AddressFamily = 'IPv4',
        [string]
        $PrefixLength = '24',
        [pscredential]
        $RunAsUser
    )

    Import-DscResource -ModuleName ORDDSCModule

    ORDIPAdapter Adapter
    {
        Ensure = 'Present'
        InterfaceAlias = $InterfaceAlias
        IPAddress = $IPAddress
        AddressFamily = $AddressFamily
        PrefixLength = $PrefixLength
        PsDscRunAsCredential = $RunAsUser
    }
}
