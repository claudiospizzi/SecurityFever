<#
    .SYNOPSIS
        Get the PSCredential objects from the Windows Credential Manager vault.

    .DESCRIPTION
        This cmdlet uses the native unmanaged Win32 api to retrieve all entries
        from the Windows Credential Manager vault. The entries are of type
        PSCredential. To get the full credential entries with all properties
        like target name, use the Get-VaultEntry cmdlet.

    .INPUTS
        None.

    .OUTPUTS
        System.Management.Automation.PSCredential.

    .EXAMPLE
        PS C:\> Get-VaultCredential -TargetName 'MyUserCred'
        Return the PSCredential objects with the target name 'MyUserCred'.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-VaultCredential
{
    [CmdletBinding()]
    [Alias('Get-VaultEntryCredential')]
    [OutputType([System.Management.Automation.PSCredential])]
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
        Write-Output $credentialEntry.Credential
    }
}
