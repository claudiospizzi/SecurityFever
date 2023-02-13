<#
    .SYNOPSIS
        Add a permission entry on the certificate private key.

    .DESCRIPTION
        This command will resolve the certificate to it's corresponding private
        key file in C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys and add a
        new access entry for the specified identity.

    .INPUTS
        None.

    .OUTPUTS
        None.

    .EXAMPLE
        PS C:\> Add-CertificatePrivateKeyPermission -Thumbprint '10E6862E31114CD86C5CD3E675ED45F4CA6DF8A0 -Identity 'User' -Right 'Read'
        Set read permission on the specified certificate private key.

    .EXAMPLE
        PS C:\> Add-CertificatePrivateKeyPermission -Thumbprint '10E6862E31114CD86C5CD3E675ED45F4CA6DF8A0 -Identity 'NT SERVICE\MSSQL$INST01'
        Set full control permission on the specified certificate private key
        for the SQL service account.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Add-CertificatePrivateKeyPermission
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        # The target certificate object from the local certificate store.
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate', ValueFromPipeline = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        # Certificate thumbprint, must be imported in the local certificate store.
        [Parameter(Mandatory = $true, ParameterSetName = 'Thumbprint')]
        [System.String]
        $Thumbprint,

        # The identity to grant.
        [Parameter(Mandatory = $true)]
        [System.Security.Principal.NTAccount]
        $Identity,

        # the rights to grant.
        [Parameter(Mandatory = $false)]
        [System.Security.AccessControl.FileSystemRights]
        $Right = 'FullControl'
    )

    begin
    {
        Test-AdministratorRole -Throw
    }

    process
    {
        # Find the certificate, if the thumbprint was specified
        if ($PSCmdlet.ParameterSetName -eq 'Thumbprint')
        {
            $Certificate = Get-ChildItem -Path 'Cert:\' -Recurse | Where-Object { $_.Thumbprint -eq $Thumbprint } | Select-Object -First 1

            if ($null -eq $Certificate)
            {
                throw "Certificate with thumbprint $Thumbprint not found!"
            }
        }

        $path = Get-CertificatePrivateKeyFile -Certificate $Certificate

        $acl = Get-Acl -Path $path

        if ($acl.Access.Where({ $_.IdentityReference -eq $Identity -and $_.FileSystemRights -eq $Right }).Count -eq 0)
        {
            Write-Verbose "Add $Right permission to $Identity on $path"

            $ace = [System.Security.AccessControl.FileSystemAccessRule]::new($Identity, $Right, 'Allow')
            $acl.AddAccessRule($ace) | Out-Null
            $acl | Set-Acl -Path $Path
        }
    }
}
