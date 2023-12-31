@{
    PSDependOptions              = @{
        AddToPath      = $true
        Target         = 'DscResources'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            #Repository = 'ORDPSGallery'
            Repository = 'PSGallery'
            AllowPrerelease = $true
        }
    }

    # If these are commented out, it could cause Build.ps1 to fail with a mismatch in number of resources
    xPSDesiredStateConfiguration = '9.1.0'
    ComputerManagementDsc        = '8.4.0'
    NetworkingDsc                = '8.2.0'
    JeaDsc                       = '0.7.2'
    XmlContentDsc                = '0.0.1'
    xWebAdministration           = '3.2.0'
    SecurityPolicyDsc            = '2.10.0.0'
    StorageDsc                   = '5.0.1'
    # 9/10/21 - Try the 0.2 prerelease Chocolatey, which should have my extra code in it
    Chocolatey                   = '0.2.0'
    #Chocolatey                   = '0.2.0-preview0002'
    #Chocolatey                   = '0.0.79'
    #Chocolatey                   = @{
    #    version = 'latest'
    #    Parameters = @{
    #        AllowPrerelease = $true
    #    }
    #}
    ActiveDirectoryDsc           = '6.0.1'
    DfsDsc                       = '4.4.0.0'
    WdsDsc                       = '0.11.0'
    xDhcpServer                  = '3.0.0'
    xDscDiagnostics              = '2.8.0'
    xDnsServer                   = '2.0.0'
    xFailoverCluster             = '1.16.0'
    GPRegistryPolicyDsc          = '1.2.0'
    AuditPolicyDsc               = '1.4.0.0'
    SharePointDSC                = '4.5.1'
    xExchange                    = '1.32.0'
    SqlServerDsc                 = '15.1.1'
    UpdateServicesDsc            = '1.2.1'
    xWindowsEventForwarding      = '1.0.0.0'
    OfficeOnlineServerDsc        = '1.5.0'
    xBitlocker                   = '1.4.0.0'
    ActiveDirectoryCSDsc         = '5.0.0'

}
