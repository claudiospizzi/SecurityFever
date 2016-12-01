
<#
    .SYNOPSIS
    Get a PSCredential object from the Windows Credential Manager vault.

    .DESCRIPTION
    This cmdlet uses the native unmanaged Win32 api to retrieve an entry from
    the Windows Credential Manager vault. The entry is of type PSCredential. To
    get the full credential entry with all properties like target name, use the
    Get-VaultEntry cmdlet.

    .INPUTS
    None.

    .OUTPUTS
    System.Management.Automation.PSCredential.

    .EXAMPLE
    PS C:\> Get-VaultEntryCredential -TargetName 'MyUserCred'
    Return the PSCredential object with the target name 'MyUserCred'.

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/SecurityFever
#>

function Get-VaultEntryCredential
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCredential])]
    param
    (
        # Use the target name to get one credential. Does not support wildcards.
        [Parameter(Mandatory = $true)]
        [System.String]
        $TargetName
    )

    $credentialEntry = [SecurityFever.CredentialManager.CredentialStore]::GetCredential($TargetName)

    Write-Output $credentialEntry.Credential
}
