<#
    .SYNOPSIS
        Return all permissions entries of a certificate private key.

    .DESCRIPTION
        This command will resolve the certificate to it's corresponding private
        key file in C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys and return
        the access entries.

    .INPUTS
        None.

    .OUTPUTS
        System.Security.AccessControl.FileSystemAccessRule. Access control entries.

    .EXAMPLE
        PS C:\> Get-CertificatePrivateKeyPermission -Thumbprint '10E6862E31114CD86C5CD3E675ED45F4CA6DF8A0
        Get the certificate private key permissions.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-CertificatePrivateKeyPermission
{
    [CmdletBinding()]
    [OutputType([System.Security.AccessControl.FileSystemAccessRule])]
    param
    (
        # The target certificate object from the local certificate store.
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate', ValueFromPipeline = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        # Certificate thumbprint, must be imported in the local certificate store.
        [Parameter(Mandatory = $true, ParameterSetName = 'Thumbprint')]
        [System.String]
        $Thumbprint
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
            $Certificate = Get-ChildItem -Path 'Cert:\' -Recurse |
                            Where-Object { $_.Thumbprint -eq $Thumbprint } |
                                Select-Object -First 1

            if ($null -eq $Certificate)
            {
                throw "Certificate with thumbprint $Thumbprint not found!"
            }
        }

        $path = Get-CertificatePrivateKeyFile -Certificate $Certificate

        Get-Acl -Path $path | Select-Object -ExpandProperty 'Access'
    }
}