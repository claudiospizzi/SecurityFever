<#
    .SYNOPSIS
        Create a new entry in the Windows Credential Manager vault.

    .DESCRIPTION
        This cmdlet uses the native unmanaged Win32 api to create a new entry in
        the Windows Credential Manager vault. The credential type and persist
        location can be specified. By default, a generic entry with no special
        purpose is created on the local machine persist location.

        Use one of the following persist locations:
        - Session
          The credential persists for the life of the logon session. It will not
          be visible to other logon sessions of this same user. It will not
          exist after this user logs off and back on.
        - LocalMachine
          The credential persists for all subsequent logon sessions on this same
          computer. It is visible to other logon sessions of this same user on
          this same computer and not visible to logon sessions for this user on
          other computers.
        - Enterprise
          The credential persists for all subsequent logon sessions on this same
          computer. It is visible to other logon sessions of this same user on
          this same computer and to logon sessions for this user on other
          computers.

        Use on of the following types:
        - Generic
          The credential is a generic credential. The credential will not be
          used by any particular authentication package. The credential will be
          stored securely but has no other significant characteristics.
        - DomainPassword
          The credential is a password credential and is specific to Microsoft's
          authentication packages. The NTLM, Kerberos, and Negotiate
          authentication packages will automatically use this credential when
          connecting to the named target.
        - DomainCertificate
          The credential is a certificate credential and is specific to
          Microsoft's authentication packages. The Kerberos, Negotiate, and
          Schannel authentication packages automatically use this credential
          when connecting to the named target.
        - DomainVisiblePassword
          This value is no longer supported. The credential is a password
          credential and is specific to authentication packages from Microsoft.
          The Passport authentication package will automatically use this
          credential when connecting to the named target.
        - GenericCertificate
          The credential is a certificate credential that is a generic
          authentication package.
        - DomainExtended
          The credential is supported by extended Negotiate packages.
        - Maximum
          The maximum number of supported credential types.
        - MaximumEx
          The extended maximum number of supported credential types that now
          allow new applications to run on older operating systems.

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.CredentialManager.CredentialEntry.

    .EXAMPLE
        PS C:\> New-VaultEntry -TargetName 'MyUserCred' -Credential $credential
        Create a new entry in the Credential Manager vault with the name
        MyUserCred and the credentials specified in the variable.

    .EXAMPLE
        PS C:\> New-VaultEntry -TargetName 'MyUserCred' -Username 'DOMAIN\user' -Password $secretPassword
        Create a new entry in the Credential Manager vault with the name
        MyUserCred, the username user and the password specified in the
        variable.

    .EXAMPLE
        PS C:\> New-VaultEntry -TargetName 'MyUserCred' -Type 'DomainPassword' -Persist 'Session' -Credential $credential
        Create a new entry in the Credential Manager vault with a custom type
        and persist options. Check the description for detailed information
        about the types and persist locations.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function New-VaultEntry
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([SecurityFever.CredentialManager.CredentialEntry])]
    param
    (
        # The entry target name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $TargetName,

        # The entry type.
        [Parameter(Mandatory = $false)]
        [SecurityFever.CredentialManager.CredentialType]
        $Type = 'Generic',

        # The entry persist location.
        [Parameter(Mandatory = $false)]
        [SecurityFever.CredentialManager.CredentialPersist]
        $Persist = 'LocalMachine',

        # The credential object to store in the vault.
        [Parameter(Mandatory = $true, ParameterSetName = 'Credential')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # The username to store in the vault. Specify password too.
        [Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
        [System.String]
        $Username,

        # The password to store in the vault. Specify username too.
        [Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
        [System.Security.SecureString]
        $Password,

        # Override any existing entry.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    if ((-not $Force.IsPresent) -and ([SecurityFever.CredentialManager.CredentialStore]::ExistCredential($TargetName, $Type)))
    {
        throw "Entry with target name $TargetName and type $Type already exists!"
    }

    if ($PSCmdlet.ParameterSetName -eq 'UsernamePassword')
    {
        $Credential = New-Object -TypeName PSCredential -ArgumentList $Username, $Password
    }

    if ($Force.IsPresent -or $PSCmdlet.ShouldProcess("$TargetName ($Type)", "Create Entry"))
    {
        $credentialEntry = [SecurityFever.CredentialManager.CredentialStore]::CreateCredential($TargetName, $Type, $Persist, $Credential)

        Write-Output $credentialEntry
    }
}
