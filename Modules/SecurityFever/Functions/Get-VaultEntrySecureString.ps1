
<#
    .SYNOPSIS
    Get a secure string object from the Windows Credential Manager vault.

    .DESCRIPTION
    This cmdlet uses the native unmanaged Win32 api to retrieve an entry from
    the Windows Credential Manager vault. The entry is of type secure string. To
    get the full credential entry with all properties like target name, use the
    Get-VaultEntry cmdlet.

    .INPUTS
    None.

    .OUTPUTS
    System.Security.SecureString.

    .EXAMPLE
    PS C:\> Get-VaultEntrySecureString -TargetName 'MyUserCred'
    Return the secure string object with the target name 'MyUserCred'.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/SecurityFever
#>

function Get-VaultEntrySecureString
{
    [CmdletBinding()]
    [OutputType([System.Security.SecureString])]
    param
    (
        # Use the target name to get one secure string. Does not support
        # wildcards.
        [Parameter(Mandatory = $true)]
        [System.String]
        $TargetName
    )

    $credentialEntry = [SecurityFever.CredentialManager.CredentialStore]::GetCredential($TargetName)

    Write-Output $credentialEntry.Credential.Password
}
