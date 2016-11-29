
<#
    .SYNOPSIS
    Get the PSCredential objects from the Windows Credential Manager vault.

    .DESCRIPTION
    This cmdlet uses the native unmanaged Win32 api to retrieve all entries from
    the Windows Credential Manager vault. The entries are of type PSCredential.
    To get the full credential entry with all properties like target name, use
    the Get-VaultCredential cmdlet.

    .INPUTS
    None.

    .OUTPUTS
    System.Management.Automation.PSCredential.

    .EXAMPLE
    PS C:\> Get-VaultCredential
    Returns all available credentials as PSCredential objects.

    .EXAMPLE
    PS C:\> Get-VaultCredential -TargetName 'MyUserCred'
    Return the PSCredential object with the target name 'MyUserCred'.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/SecurityFever
#>

function Get-VaultCredentialValue
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCredential])]
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
            Write-Output $credential.Credential
        }
    }
    else
    {
        [SecurityFever.CredentialManager.CredentialStore]::GetCredential($TargetName).Credential
    }
}
