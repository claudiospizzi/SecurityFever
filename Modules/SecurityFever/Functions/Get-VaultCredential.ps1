
<#
    .SYNOPSIS
    Get the credential entries from the Windows Credential Manager vault.

    .DESCRIPTION
    This cmdlet uses the native unmanaged Win32 api to retrieve all entries from
    the Windows Credential Manager vault. The entries are not objects of type
    PSCredential. The PSCredential is available on the Credential property or
    with the Get-VaultCredentialValue cmdlet.

    .INPUTS
    None.

    .OUTPUTS
    SecurityFever.CredentialManager.CredentialEntry.

    .EXAMPLE
    PS C:\> Get-VaultCredential
    Returns all available credential entries.

    .EXAMPLE
    PS C:\> Get-VaultCredential -TargetName 'MyUserCred'
    Return the credential entry with the target name 'MyUserCred'.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/SecurityFever
#>

function Get-VaultCredential
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
        $credentials = [SecurityFever.CredentialManager.CredentialStore]::GetCredentials()

        foreach ($credential in $credentials)
        {
            Write-Output $credential
        }
    }
    else
    {
        [SecurityFever.CredentialManager.CredentialStore]::GetCredential($TargetName)
    }
}
