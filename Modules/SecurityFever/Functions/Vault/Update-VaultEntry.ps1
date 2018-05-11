<#
    .SYNOPSIS
        Update an existing entry in the Windows Credential Manager vault.

    .DESCRIPTION
        This cmdlet uses the native unmanaged Win32 api to update an existing
        entry in the Windows Credential Manager vault. Use a entry object or the
        target name and type combination to identity the entry to update.
        It is possible to update the persist location, the credentials, the
        username and the password. If you specify new credentials, new username
        and password will be ignored.

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.CredentialManager.CredentialEntry.

    .EXAMPLE
        PS C:\> Update-VaultEntry -TargetName 'MyUserCred' -Type 'DomainPassword' -NewCredential $cred

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Update-VaultEntry
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([SecurityFever.CredentialManager.CredentialEntry])]
    param
    (
        # The target entry to update as objects.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Object')]
        [SecurityFever.CredentialManager.CredentialEntry[]]
        $InputObject,

        # The name of the target entry to update.
        [Parameter(Mandatory = $true, ParameterSetName = 'Properties')]
        [System.String]
        $TargetName,

        # The type of the target entry to update.
        [Parameter(Mandatory = $true, ParameterSetName = 'Properties')]
        [SecurityFever.CredentialManager.CredentialType]
        $Type,

        # The entry persist location.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [SecurityFever.CredentialManager.CredentialPersist]
        $NewPersist,

        # The credential object to store in the vault.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $NewCredential,

        # The username to store in the vault. Specify password too.
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [System.String]
        $NewUsername,

        # The password to store in the vault. Specify username too.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Security.SecureString]
        $NewPassword,

        # Force the update.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'Properties')
        {
            $InputObject = [SecurityFever.CredentialManager.CredentialStore]::GetCredential($TargetName, $Type)
        }

        foreach ($object in $InputObject)
        {
            if (([SecurityFever.CredentialManager.CredentialStore]::ExistCredential($object.TargetName, $object.Type)))
            {
                # If no new persist was specified, use the current value.
                if (-not $PSBoundParameters.ContainsKey('NewPersist'))
                {
                    $NewPersist = $object.Persist
                }

                # If no new credentials were specified, check if the username or
                # password was updated and create a new credentials object.
                if (-not $PSBoundParameters.ContainsKey('NewCredential'))
                {
                    $NewCredential = $object.Credential

                    if ($PSBoundParameters.ContainsKey('NewUsername'))
                    {
                        $NewCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $NewUsername, $NewCredential.Password
                    }
                    if ($PSBoundParameters.ContainsKey('NewPassword'))
                    {
                        $NewCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $NewCredential.Username, $NewPassword
                    }
                }

                if ($Force.IsPresent -or $PSCmdlet.ShouldProcess("$($object.TargetName) ($($object.Type))", "Update Entry"))
                {
                    # Finally, invoke the NewCredential() method to update the
                    # credential entry.
                    $credentialEntry = [SecurityFever.CredentialManager.CredentialStore]::CreateCredential($object.TargetName, $object.Type, $NewPersist, $NewCredential)

                    Write-Output $credentialEntry
                }
            }
            else
            {
                throw "Entry with target name $($object.TargetName) and type $($object.Type) already exists!"
            }
        }
    }
}
