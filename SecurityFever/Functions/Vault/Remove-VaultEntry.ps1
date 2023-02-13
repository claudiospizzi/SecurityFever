<#
    .SYNOPSIS
        Removes an existing entry in the Windows Credential Manager vault.

    .DESCRIPTION
        This cmdlet uses the native unmanaged Win32 api to remove a existing
        entry in the Windows Credential Manager vault.

    .INPUTS
        None.

    .OUTPUTS
        None.

    .EXAMPLE
        PS C:\> Get-VaultEntry -TargetName 'MyUserCred' -Type 'DomainPassword' -Persist 'Session' | Remove-VaultEntry
        Remove the Credential Manager vault entry which was piped to the cmdlet.

    .EXAMPLE
        PS C:\> Remove-VaultEntry -TargetName 'MyUserCred' -Type 'DomainPassword'
        Remove the Credential Manager vault entry with the specified target name
        and type.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Remove-VaultEntry
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        # The target entry to delete as objects.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Object')]
        [SecurityFever.CredentialManager.CredentialEntry[]]
        $InputObject,

        # The name of the target entry to delete.
        [Parameter(Mandatory = $true, ParameterSetName = 'Properties')]
        [System.String]
        $TargetName,

        # The type of the target entry to delete.
        [Parameter(Mandatory = $true, ParameterSetName = 'Properties')]
        [SecurityFever.CredentialManager.CredentialType]
        $Type,

        # Force the removal.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'Properties')
        {
            [SecurityFever.CredentialManager.CredentialStore]::RemoveCredential($TargetName, $Type)
        }
        else
        {
            foreach ($object in $InputObject)
            {
                if ($Force.IsPresent -or $PSCmdlet.ShouldProcess("$($object.TargetName) ($($object.Type))", "Remove Entry"))
                {
                    [SecurityFever.CredentialManager.CredentialStore]::RemoveCredential($object.TargetName, $object.Type)
                }
            }
        }
    }
}
