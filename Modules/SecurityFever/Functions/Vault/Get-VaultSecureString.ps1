<#
    .SYNOPSIS
        Get the secure string objects from the Windows Credential Manager vault.

    .DESCRIPTION
        This cmdlet uses the native unmanaged Win32 api to retrieve all entries
        from the Windows Credential Manager vault. The entries are of type
        secure string. To get the full secure string entries with all properties
        like target name, use the Get-VaultEntry cmdlet.

    .INPUTS
        None.

    .OUTPUTS
        System.Security.SecureString.

    .EXAMPLE
        PS C:\> Get-VaultSecureString -TargetName 'MySecString'
        Return the secure string objects with the target name 'MySecString'.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-VaultSecureString
{
    [CmdletBinding()]
    [Alias('Get-VaultEntrySecureString')]
    [OutputType([System.Security.SecureString])]
    param
    (
        # Filter the secure strings by target name. Does not support wildcards.
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [System.String]
        $TargetName,

        # Filter the secure strings by type.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [SecurityFever.CredentialManager.CredentialType]
        $Type,

        # Filter the secure strings by persist location.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [SecurityFever.CredentialManager.CredentialPersist]
        $Persist,

        # Filter the secure strings by username. Does not support wildcards.
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [System.String]
        $Username
    )

    $credentialEntries = [SecurityFever.CredentialManager.CredentialStore]::GetCredentials($TargetName, $Type, $Persist, $Username)

    foreach ($credentialEntry in $credentialEntries)
    {
        Write-Output $credentialEntry.Credential.Password
    }
}
