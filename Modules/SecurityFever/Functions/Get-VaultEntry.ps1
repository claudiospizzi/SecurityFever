
<#
    .SYNOPSIS
    Get the credential entries from the Windows Credential Manager vault.

    .DESCRIPTION
    This cmdlet uses the native unmanaged Win32 api to retrieve all entries from
    the Windows Credential Manager vault. The entries are not objects of type
    PSCredential. The PSCredential is available on the Credential property or
    with the Get-VaultEntryCredential cmdlet or you can get a secure string
    with the Get-VaultEntrySecureString cmdlet.

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

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/SecurityFever
#>

function Get-VaultEntry
{
    [CmdletBinding()]
    [OutputType([SecurityFever.CredentialManager.CredentialEntry])]
    param
    (
        # Use the target name to get one credential. Does not support wildcards.
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [System.String]
        $TargetName
    )

    if ([String]::IsNullOrEmpty($TargetName))
    {
        $credentialEntries = [SecurityFever.CredentialManager.CredentialStore]::GetCredentials()

        foreach ($credentialEntry in $credentialEntries)
        {
            Write-Output $credentialEntry
        }
    }
    else
    {
        $credentialEntry = [SecurityFever.CredentialManager.CredentialStore]::GetCredential($TargetName)

        Write-Output $credentialEntry
    }
}
