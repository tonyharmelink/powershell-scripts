Configuration MigrateNovellFSPermissions {
    
    # Load modules
    # Run Import-Module {ModuleName} to install if needed.
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName cNtfsAccessControl

    # What node to run on, we will be running locally.
    Node @('localhost')
    {
        # Parse the lines from our CSV, expected columns are:
        # Folder path, full path with drive D:\[bla]
        # newFull to designate a principal to recieve a Full Access permission
        # newRW to designate a principal to recieve a Read and Write permission
        # newRO to designate a principal to recieve a Read Only permission
        # folderTraverse to designate a principal to recieve a Folder Traversal permission
        # noAccess to break inheretance, make permissions, and remove the noAccess principal

        Import-Csv ".\home.csv" | ForEach-Object {

            # If there is a principal to apply a Full Access permission to
            if (-not ([string]::IsNullOrEmpty($_.newFull)))
            {

                cNtfsPermissionEntry "@{ Result = $([guid]::NewGuid()).$_.Folder.$_.newFull }"
                {
                    Ensure = 'Present'
                    Path = $_.Folder
                    Principal = $_.newFull
                    AccessControlInformation = @(
                        cNtfsAccessControlInformation
                        {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'FullControl'
                            Inheritance = 'ThisFolderSubfoldersAndFiles'
                            NoPropagateInherit = $false
                        }
                    )
                }
            }


            # If there is a principal to apply a RW permission to
            if (-not ([string]::IsNullOrEmpty($_.newRW)))
            {

                cNtfsPermissionEntry "@{ Result = $([guid]::NewGuid()).$_.Folder.$_.newRW }"
                {
                    Ensure = 'Present'
                    Path = $_.Folder
                    Principal = $_.newRW
                    AccessControlInformation = @(
                        cNtfsAccessControlInformation
                        {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'Modify'
                            Inheritance = 'ThisFolderSubfoldersAndFiles'
                            NoPropagateInherit = $false
                        }
                    )
                }
            }

            # If there is a principal to apply a RO permission to
            if (-not ([string]::IsNullOrEmpty($_.newRO)))
            {

                cNtfsPermissionEntry "@{ Result = $([guid]::NewGuid()).$_.Folder.$_.newRO }"
                {
                    Ensure = 'Present'
                    Path = $_.Folder
                    Principal = $_.newRO
                    AccessControlInformation = @(
                        cNtfsAccessControlInformation
                        {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'Read'
                            Inheritance = 'ThisFolderSubfoldersAndFiles'
                            NoPropagateInherit = $false
                        }
                    )
                }
            }

            # If there is a principal to apply a folder traversal permission to
            if (-not ([string]::IsNullOrEmpty($_.folderTraverse)))
            {

                cNtfsPermissionEntry "@{ Result = $([guid]::NewGuid()).$_.Folder.$_.folderTraverse }"
                {
                    Ensure = 'Present'
                    Path = $_.Folder
                    Principal = $_.folderTraverse
                    AccessControlInformation = @(
                        cNtfsAccessControlInformation
                        {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'Traverse,ListDirectory'
                            Inheritance = 'ThisFolderOnly'
                            NoPropagateInherit = $true
                        }
                    )
                }
            }

            # If there is a principal, break inheretance, explicit the parent permissions, and remove the noAccess principal
            if (-not ([string]::IsNullOrEmpty($_.NoAccess)))
            {
                cNtfsPermissionsInheritance "@{ Result = $([guid]::NewGuid()).$_.Folder.$_.NoAccess }"
                {
                    Path = $_.Folder
                    PreserveInherited = $true
                    Enabled = $false
                }

                cNtfsPermissionEntry "@{ Result = $([guid]::NewGuid()).$_.Folder.$_.NoAccess }"
                {
                    Ensure = 'Absent'
                    Path = $_.Folder
                    Principal = $_.NoAccess
                }
            }
        }
    }
}

MigrateNovellFSPermissions -OutputPath ".\"

<#
compile to DSC via:
.\[Filename]

Run on target computer via:
Move the *.mof file to the server, install modules on the server if needed.
Start-DscConfiguration -Path .\ -Wait -Force -Verbose
#>