@{
    PSDependOptions = @{
        AddToPath      = $true
        Target         = 'DscConfigurations'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            Repository = 'PSGallery'
        }
    }

    CommonTasks     = '0.3.212'
    #CommonTasks     = '0.3.197'

}
