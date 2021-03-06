<#
.SYNOPSIS
    Touch and fix permissions on an OpenSSH authorized keys file.

.DESCRIPTION
    The configuration file ($env:ProgramData\ssh\sshd_config) for the 
    OpenSSH SSH Server service (sshd) can specify the path to an 
    AuthorizedKeysFile which contains public keys.  This file must
    have these permissions exactly or else authentication will fail:

        NT AUTHORITY\SYSTEM     = Full Control
        BUILTIN\Administrators  = Full Control
        Permissions Inheritance = Disabled

    This script will reset the permissions on the file, if necessary.
    If the file does not exist, a blank one will be created. Note
    that this is not the authorized_keys file for an individual user
    in that user's ~\.ssh\ local profile folder.  

.PARAMETER SshConfigFolder
    Path to the folder containing the OpenSSH Server config files.
    Defaults to the factory default of $env:ProgramData\ssh\.

.PARAMETER AuthorizedKeysFileName
    Name of the desired OpenSSH authorized keys file.  Note that
    this is not an authorized_keys file for an individual user.
    Defaults to administrators_authorized_keys in SshConfigFolder.

.PARAMETER Verbose
    Displays status messages.  Default is to run silently. 
#> 


Param 
(
    $SshConfigFolder = "$env:ProgramData\ssh",
    $AuthorizedKeysFileName = "administrators_authorized_keys",
    [Switch] $Verbose
)


# Full path to the keys file:
$FullPath = Join-Path -Path $SshConfigFolder -ChildPath $AuthorizedKeysFileName


# Create the $AuthorizedKeysFileName if necessary, stop if fail:
if (Test-Path -Path $FullPath)
{
    if ($Verbose){ Write-Verbose -Verbose -Message "File exists: $FullPath" } 
}
else
{ 
    if ($Verbose){ Write-Verbose -Verbose -Message "Creating file: $FullPath" } 
    New-Item -ItemType File -Path $SshConfigFolder -Name $AuthorizedKeysFileName -ErrorAction Stop | Out-Null 
} 


# Get the current permissions:
$Perms = Get-Acl -Path $FullPath


# Fix the permissions if they are wrong:
if ($Perms.SDDL -like 'O:BAG:*D:P*(A;;FA;;;SY)(A;;FA;;;BA)')
{ 
    if ($Verbose){ Write-Verbose -Verbose -Message "Permissions correct on $FullPath" } 
}
else
{
    if ($Verbose){ Write-Verbose -Verbose -Message "Fixing permissions on $FullPath" } 

    # Take ownership for Administrators:
    icacls.exe $FullPath /setowner 'BUILTIN\Administrators' | Out-Null

    # Replace all perms with default inherited perms:
    icacls.exe $FullPath /reset | Out-Null

    # Grant full control to System and Administrors explicity (do first):
    icacls.exe $FullPath /grant:r 'BUILTIN\Administrators:(F)' /grant:r 'NT AUTHORITY\SYSTEM:(F)' | Out-Null 

    # Remove all other inherited perms and disable inheritance (do afterwards):
    icacls.exe $FullPath /inheritance:r | Out-Null

    # Get the (new) permissions again:
    $Perms = Get-Acl -Path $FullPath


    # Check the permissions again and fail if somehow still wrong:
    if ($Perms.SDDL -like 'O:BAG:*D:P*(A;;FA;;;SY)(A;;FA;;;BA)')
    { 
        if ($Verbose){ Write-Verbose -Verbose -Message "Permissions correct on $FullPath" } 
    }
    else
    {
        Throw "ERROR: Failed to set necessary permissions on $FullPath"
        #Exit
    }
}

