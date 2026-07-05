<#
    .SYNOPSIS
        Convert certificate files into other formats.

    .DESCRIPTION
        Function to convert certificate files. This function is using native
        crypto functions and does not required external dependencies.

        The following overview should give a short introduction about
        certificates and their file formats:

        - X.509/DER
            Contains the public part of a single X.509 certificate in the
            binary DER format. Used primary on Windows systems.

        - X.509/PEM
            Contains the public part of a single X.509 certificate in the
            Base64 encoded PEM format. Used primary on Linux systems.

        - PKCS#7 (.p7b, .p7c, .p7m, .p7r, .p7s)
            This is a file archive container for storing one or more X.509
            certificates. The certificate files only contain the public part of
            the certificates. On Windows these files are normally formatted as
            DER binary files.

        - PKCS#12 (.pfx/.p12)
            This is a file archive container for storing one or more X.509
            certificates with their public and private key parts. On Windows
            these files are normally formatted as DER binary files and can be
            password protected with AES or 3DES encryption.

        - PKCS#1 Private Key (-----BEGIN RSA PRIVATE KEY-----)
            Contains the private part of a single RSA key in the Base64 encoded
            PKCS#1 format. Used primary on Linux systems.

        - PKCS#8 Private Key (-----BEGIN PRIVATE KEY-----)
            Contains the private part of a key in the Base64 encoded PKCS#8
            format. Compared to the PKCS#1 format, this format can contain keys
            of different algorithms. Used primary on Linux systems.

        Supported input certificate formats:
        - X.509/DER certificate
        - X.509/PEM certificate
        - PKCS#7 certificate container
        - PKCS#12 certificate container (AES/3DES password encrypted)

        Currently NOT supported input certificate formats:
        - PKCS#1 private key
        - PKCS#8 private key

        Supported output certificate formats:
        - X.509/DER certificate
        - X.509/PEM certificate
        - PKCS#1 private key
        - PKCS#8 private key

        Currently NOT supported output certificate formats:
        - PKCS#7 certificate container
        - PKCS#12 certificate container

    .EXAMPLE
        PS C:\> Convert-Certificate -InPath 'cert.cer' -OutPath 'cert.pem' -OutType 'X.509/PEM'
        Convert a X.509/DER certificate file to a X.509/PEM certificate file.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Convert-Certificate
{
    [CmdletBinding()]
    param
    (
        # Path to the input certificate file.
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('In', 'InFile')]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
        [System.String]
        $InPath,

        # Optional password to read the input file.
        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]
        $InPassword,

        # Path to the output certificate file.
        [Parameter(Mandatory = $true, Position = 1)]
        [Alias('Out', 'OutFile')]
        [System.String]
        $OutPath,

        # Optional password to write the output file.
        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]
        $OutPassword,

        # Type of the output certificate or private key file.
        # - X.509/DER or CertificateBinary: Binary DER encoded X.509 certificate
        # - X.509/PEM or CertificateBase64: Base64 PEM encoded X.509 certificate
        # - PKCS#1 or RsaPrivateKey: Base64 PEM encoded PKCS#1 private key
        # - PKCS#8 or PrivateKey: Base64 PEM encoded PKCS#8 private key
        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateSet('X.509/DER', 'CertificateBinary', 'X.509/PEM', 'CertificateBase64', 'PKCS#1', 'RsaPrivateKey', 'PKCS#8', 'PrivateKey')]
        [System.String]
        $OutType
    )

    # Resolve the path to the actual provider path e.g. for TestDrive:\ in
    # Pester or other relative paths and PSDrives. The Resolve-Path cmdlet will
    # throw if the file does not exist.
    $InPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InPath)
    $OutPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutPath)

    # Detect the certificate input type based on the file extension. The default
    # is X.509 if not a special container.
    $InType = 'X.509'
    switch -wildcard ($InPath)
    {
        '*.p7b' { $InType = 'PKCS#7' }
        '*.p7c' { $InType = 'PKCS#7' }
        '*.p7m' { $InType = 'PKCS#7' }
        '*.p7r' { $InType = 'PKCS#7' }
        '*.p7s' { $InType = 'PKCS#7' }
        '*.pfx' { $InType = 'PKCS#12' }
        '*.p12' { $InType = 'PKCS#12' }
    }

    $exportFiles = @()
    if ($InType -eq 'PKCS#12')
    {
        Write-Verbose "[Convert-Certificate] Read the certificate file '$InPath' as a PKCS#12 container file."

        # Check if the required input password is provided, else encrypted
        # PKCS#12 files cannot be read and converted.
        if (-not $PSBoundParameters.ContainsKey('InPassword'))
        {
            throw "The input certificate file '$InPath' is a PKCS#12 container file and requires a password to decrypt and read it."
        }

        # Single export file
        $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($InPath, $InPassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
        $exportFiles += @{
            Certificate = $certificate
            OutPath     = $OutPath
        }
    }
    elseif ($InType -eq 'PKCS#7')
    {
        Write-Verbose "[Convert-Certificate] Read the certificate file '$InPath' as a PKCS#7 container file."

        # PKCS#7 files can contain multiple certificates, so we need to read all
        # of them into a collection. Reading them as just a single certificate
        # will fail with "Cannot find the original signer.".
        $certificates = [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]::new()
        $certificates.Import($InPath)

        # Ensure that the PKCS#7 container file contains at least one
        # certificate to convert.
        if ($certificates.Count -le 0)
        {
            throw "The input certificate file '$InPath' is a PKCS#7 container file but does not contain any certificates."
        }

        # If the PKCS#7 container file contains exactly one certificate, we can
        # just export it to the specified output file.
        elseif ($certificates.Count -eq 1)
        {
            $exportFiles += @{
                Certificate = $certificates[0]
                OutPath     = $OutPath
            }
        }

        # If the PKCS#7 container file contains multiple certificates, we need
        # to export each certificate into a separate output file. The output
        # file name will be the specified output file name with the certificate
        # thumbprint appended to it.
        else
        {
            Write-Warning "The input certificate file '$InPath' is a PKCS#7 container file and contains multiple certificates. Each certificate will be exported to a separate output file with the thumbprint appended to the file name."

            $outDirectory = [System.IO.Path]::GetDirectoryName($OutPath)
            $outBaseName  = [System.IO.Path]::GetFileNameWithoutExtension($OutPath)
            $outExtension = [System.IO.Path]::GetExtension($OutPath)

            foreach ($certificate in $certificates)
            {
                $certificateId = $certificate.Thumbprint.ToLower().Substring(0, 7)
                $outFileName = '{0}-{1}{2}' -f $outBaseName, $certificateId, $outExtension

                $exportFiles += @{
                    Certificate = $certificate
                    OutPath     = [System.IO.Path]::Combine($outDirectory, $outFileName)
                }
            }
        }
    }
    else
    {
        Write-Verbose "[Convert-Certificate] Read the certificate file '$InPath' as a basic X.509 certificate."

        # Try to detect unsupported input certificates. A common issue could be,
        # that a private key is provided as input file, which cannot be
        # converted
        $inFileContent = [System.IO.File]::ReadAllText($InPath)
        if ($inFileContent -match '-----BEGIN PRIVATE KEY-----' -or
            $inFileContent -match '-----BEGIN RSA PRIVATE KEY-----')
        {
            throw "The input certificate file '$InPath' is a private key file and cannot be converted. Only X.509 certificates and PKCS#7/PKCS#12 container files can be converted."
        }

        # Single export file, nothing special here
        $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($InPath)
        $exportFiles += @{
            Certificate = $certificate
            OutPath     = $OutPath
        }
    }

    foreach ($exportFile in $exportFiles)
    {
        if ($OutType -in 'X.509/DER', 'CertificateBinary')
        {
            Write-Verbose "[Convert-Certificate] Exporting certificate '$($exportFile.Certificate.Subject)' with thumbprint '$($exportFile.Certificate.Thumbprint)' to file '$($exportFile.OutPath)' as binary 'X.509/DER' format."

            $certificateBytes = $exportFile.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)

            [System.IO.File]::WriteAllBytes($exportFile.OutPath, $certificateBytes)
        }

        if ($OutType -in 'X.509/PEM', 'CertificateBase64')
        {
            Write-Verbose "[Convert-Certificate] Exporting certificate '$($exportFile.Certificate.Subject)' with thumbprint '$($exportFile.Certificate.Thumbprint)' to file '$($exportFile.OutPath)' as base64 'X.509/PEM' format."

            $certificateBytes = $exportFile.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
            $certificateBase64 = $certificateBytes | ConvertTo-CertificateBase64 -Type 'CERTIFICATE'

            [System.IO.File]::WriteAllText($exportFile.OutPath, $certificateBase64)
        }

        if ($OutType -in 'PKCS#1', 'RsaPrivateKey')
        {
            Write-Verbose "[Convert-Certificate] Exporting private key of certificate '$($exportFile.Certificate.Subject)' with thumbprint '$($exportFile.Certificate.Thumbprint)' to file '$($exportFile.OutPath)' as base64 'PKCS#1' format."

            Export-CertificatePrivateKey -Certificate $exportFile.Certificate -OutPath $exportFile.OutPath -OutFormat 'PKCS#1'
        }

        if ($OutType -in 'PKCS#8', 'PrivateKey')
        {
            Write-Verbose "[Convert-Certificate] Exporting private key of certificate '$($exportFile.Certificate.Subject)' with thumbprint '$($exportFile.Certificate.Thumbprint)' to file '$($exportFile.OutPath)' as base64 'PKCS#8' format."

            Export-CertificatePrivateKey -Certificate $exportFile.Certificate -OutPath $exportFile.OutPath -OutFormat 'PKCS#8'
        }
    }
}
