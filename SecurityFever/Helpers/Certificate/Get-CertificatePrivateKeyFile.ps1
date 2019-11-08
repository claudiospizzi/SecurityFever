<#
    .SYNOPSIS
        Return the private key file or throw an exception.
#>
function Get-CertificatePrivateKeyFile
{
    [CmdletBinding()]
    param
    (
        # The target certificate object from the local certificate store.
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    if (-not $Certificate.HasPrivateKey)
    {
        throw "Certificate $Thumbprint has no private key!"
    }

    # Define the path to the RSa private key
    $path = Join-Path -Path "$Env:AllUsersProfile\Microsoft\Crypto\RSA\MachineKeys" -ChildPath $Certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName

    if (-not (Test-Path -Path $path))
    {
        throw "Certificate private key file $path not found!"
    }

    return $path
}
