<#
    .SYNOPSIS
        Get the credential entries from the Windows Credential Manager vault.

    .DESCRIPTION
        This cmdlet uses the native unmanaged Win32 api to retrieve all entries
        from the Windows Credential Manager vault. The entries are not objects
        of type PSCredential. The PSCredential is available on the Credential
        property or with the Get-VaultCredential cmdlet or you can get a secure
        string with the Get-VaultSecureString cmdlet.

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.CredentialManager.CredentialEntry.

    .EXAMPLE
        PS C:\> Get-VaultEntry
        Returns all available credential entries.

    .EXAMPLE
        PS C:\> Get-VaultEntry -TargetName 'MyUserCred'
        Return the credential entry with the target name 'MyUserCred'.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-VaultEntry
{
    [CmdletBinding()]
    [OutputType([SecurityFever.CredentialManager.CredentialEntry])]
    param
    (
        # Filter the credentials by target name. Does not support wildcards.
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [System.String]
        $TargetName,

        # Filter the credentials by type.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [SecurityFever.CredentialManager.CredentialType]
        $Type,

        # Filter the credentials by persist location.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [SecurityFever.CredentialManager.CredentialPersist]
        $Persist,

        # Filter the credentials by username. Does not support wildcards.
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [System.String]
        $Username
    )

    $credentialEntries = [SecurityFever.CredentialManager.CredentialStore]::GetCredentials($TargetName, $Type, $Persist, $Username)

    foreach ($credentialEntry in $credentialEntries)
    {
        Write-Output $credentialEntry
    }
}
