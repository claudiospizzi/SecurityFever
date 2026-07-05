<#
    .SYNOPSIS
        Exports the private key of a certificate.

    .DESCRIPTION
        This function allows you to export the private key of a certificate to
        a specified file path. The private key can be exported in different
        formats such as PKCS#1 (RSA private key) or PKCS#8 (private key).

        The following overview should give a short introduction about the
        private key file formats:

        - PKCS#1 Private Key (-----BEGIN RSA PRIVATE KEY-----)
            Contains the private part of a single RSA key in the Base64 encoded
            PKCS#1 format. Used primary on Linux systems.

        - PKCS#8 Private Key (-----BEGIN PRIVATE KEY-----)
            Contains the private part of a key in the Base64 encoded PKCS#8
            format. Compared to the PKCS#1 format, this format can contain keys
            of different algorithms. Used primary on Linux systems.

    .INPUTS
        System.Security.Cryptography.X509Certificates.X509Certificate2

    .EXAMPLE
        PS C:\> Export-CertificatePrivateKey -InPath $certFile
        This will export the private key of the certificate file to the pipeline returning in the default PKCS#8 format.

    .EXAMPLE
        PS C:\> $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new('cert.pfx', '***', 'Exportable')
        PS C:\> Export-CertificatePrivateKey -Certificate $cert -OutFormat 'PKCS#1' -OutPath '\privatekey.pem'
        This will export the private key of the certificate to the specified file path in the PKCS#1 format.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Export-CertificatePrivateKey
{
    [CmdletBinding()]
    param
    (
        # The certificate file from which to export the private key.
        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [Alias('In', 'InFile')]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
        [System.String]
        $InPath,

        # Password to read the input file.
        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [System.Security.SecureString]
        $InPassword,

        # The certificate from which to export the private key.
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [Alias('Cert', 'Certificate', 'X509Certificate', 'X509Certificate2')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $InCertificate,

        # The path to the output file where the private key will be exported.
        [Parameter(Mandatory = $true)]
        [Alias('Out', 'OutFile')]
        [System.String]
        $OutPath,

        # Format of the output private key file.
        # - PKCS#1 or RsaPrivateKey: Base64 PEM encoded PKCS#1 private key
        # - PKCS#8 or PrivateKey: Base64 PEM encoded PKCS#8 private key
        [ValidateSet('PKCS#1', 'RsaPrivateKey', 'PKCS#8', 'PrivateKey')]
        [System.String]
        $OutFormat = 'PKCS#8'
    )

    # Resolve the path to the actual provider path e.g. for TestDrive:\ in
    # Pester or other relative paths and PSDrives. The Resolve-Path cmdlet will
    # throw if the file does not exist.
    $InPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InPath)
    $OutPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutPath)

    # Import the certificate from the specified file path if it was specified by
    # using the -InPath and -InPassword parameters.
    if ($PSCmdlet.ParameterSetName -eq 'File')
    {
        $InCertificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($InPath, $InPassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
    }

    # Check if the certificate has a private key and if the private key is not
    # null. Give a hint for Windows PowerShell 5.1 users using Get-Item.
    if (-not $InCertificate.HasPrivateKey)
    {
        throw "The certificate does not have a private key."
    }
    if ($null -eq $InCertificate.PrivateKey)
    {
        if ($PSVersionTable.PSVersion.Major -le 5)
        {
            throw "The certificate's private key is null. Hint: On Windows PowerShell 5.1, the private key is not accessible when getting the certificate using `Get-Item -Path 'Cert:\CurrentUser\My\<Thumbprint>'`."
        }
        else
        {
            throw "The certificate's private key is null."
        }
    }

    # Depending on the .NET version, the RSA based private key is represented by
    # one of the following types:
    # - System.Security.Cryptography.RSACryptoServiceProvider
    #     This is the legacy type used in .NET Framework and .NET Core 2.x.
    # - System.Security.Cryptography.RSACng
    #     This is the modern .NET alternative to replace the old type.
    if ($InCertificate.PrivateKey -isnot [System.Security.Cryptography.RSACryptoServiceProvider] -and
        $InCertificate.PrivateKey -isnot [System.Security.Cryptography.RSACng])
    {
        throw "The certificate's private key is not an RSA key. Only RSA private keys are supported."
    }

    ## Required?!?
    # $rsaPrivateKey = $InCertificate.PrivateKey -as [System.Security.Cryptography.RSACng]
    # if ($null -eq $rsaPrivateKey)
    # {
    #     throw "The certificate's private key is not an RSA key or is not exportable."
    # }
    # if ($rsaPrivateKey.Key.ExportPolicy -notcontains [System.Security.Cryptography.CngExportPolicies]::AllowExport -and
    #     $rsaPrivateKey.Key.ExportPolicy -notcontains [System.Security.Cryptography.CngExportPolicies]::AllowPlaintextExport)
    # {
    #     throw "The certificate's private key is not marked as exportable."
    # }

    $rsaPrivateKey = $InCertificate.PrivateKey
    $rsaParameters = $rsaPrivateKey.ExportParameters($true)

    # The generation of the PKCS#1 is required for both the PKCS#1 and PKCS#8
    # formats, because the PKCS#8 format contains the PKCS#1 format as a nested
    # structure.
    $pkcs1Bytes = @()
    $pkcs1Stream = [System.IO.MemoryStream]::new()
    try
    {
        $pkcs1Writer = [System.IO.BinaryWriter]::new($pkcs1Stream)
        try
        {
            $pkcs1Writer.Write([System.Byte]0x30) # SEQUENCE

            $pkcs1InnerStream = [System.IO.MemoryStream]::new()
            try
            {
                $pkcs1InnerWriter = [System.IO.BinaryWriter]::new($pkcs1InnerStream)
                try
                {
                    $pkcs1InnerWriter | Write-CertificateDerIntegerBigEndian -Value @([System.Byte]0x00) # VERSION
                    $pkcs1InnerWriter | Write-CertificateDerIntegerBigEndian -Value $rsaParameters.Modulus
                    $pkcs1InnerWriter | Write-CertificateDerIntegerBigEndian -Value $rsaParameters.Exponent
                    $pkcs1InnerWriter | Write-CertificateDerIntegerBigEndian -Value $rsaParameters.D
                    $pkcs1InnerWriter | Write-CertificateDerIntegerBigEndian -Value $rsaParameters.P
                    $pkcs1InnerWriter | Write-CertificateDerIntegerBigEndian -Value $rsaParameters.Q
                    $pkcs1InnerWriter | Write-CertificateDerIntegerBigEndian -Value $rsaParameters.DP
                    $pkcs1InnerWriter | Write-CertificateDerIntegerBigEndian -Value $rsaParameters.DQ
                    $pkcs1InnerWriter | Write-CertificateDerIntegerBigEndian -Value $rsaParameters.InverseQ

                    $pkcs1InnerLength = [System.Convert]::ToInt32($pkcs1InnerStream.Length)
                    $pkcs1Writer | Write-CertificateDerLength -Length $pkcs1InnerLength
                    $pkcs1Writer.Write($pkcs1InnerStream.GetBuffer(), 0, $pkcs1InnerLength)
                }
                finally
                {
                    $pkcs1InnerWriter.Dispose()
                }
            }
            finally
            {
                $pkcs1InnerStream.Dispose()
            }

            $pkcs1Bytes = $pkcs1Stream.ToArray()
        }
        finally
        {
            $pkcs1Writer.Dispose()
        }
    }
    finally
    {
        $pkcs1Stream.Dispose()
    }

    # For the PKCS#1 format, we can directly write the Base64 encoded private
    # key to the specified output file path and exit.
    if ($OutFormat -in 'PKCS#1', 'RsaPrivateKey')
    {
        $pkcs1Base64 = ConvertTo-CertificateBase64 -Type 'RSA PRIVATE KEY' -Byte $pkcs1Bytes
        [System.IO.File]::WriteAllText($OutPath, $pkcs1Base64)
    }

    # For the PKCS#8 format, we need to wrap the PKCS#1 private key in a PKCS#8
    # structure. The PKCS#8 format is a generic format that can contain private
    # keys of different algorithms. The PKCS#8 structure contains the PKCS#1
    # structure as a nested structure.
    if ($OutFormat -in 'PKCS#8', 'PrivateKey')
    {
        $pkcs8Bytes = @()
        $pkcs8Stream = [System.IO.MemoryStream]::new()
        try
        {
            $pkcs8Writer = [System.IO.BinaryWriter]::new($pkcs8Stream)
            try
            {
                $pkcs8Writer.Write([System.Byte]0x30) # SEQUENCE

                $pkcs8InnerStream = [System.IO.MemoryStream]::new()
                try
                {
                    $pkcs8InnerWriter = [System.IO.BinaryWriter]::new($pkcs8InnerStream)
                    try
                    {
                        $pkcs8InnerWriter | Write-CertificateDerIntegerBigEndian -Value @([System.Byte]0x00) # VERSION

                        $pkcs8InnerWriter.Write([System.Byte]0x30) # SEQUENCE
                        $pkcs8InnerWriter | Write-CertificateDerLength -Length 13
                        $pkcs8InnerWriter.Write([System.Byte]0x06) # OBJECT IDENTIFIER
                        $pkcs8InnerWriter | Write-CertificateDerLength -Length 9
                        $pkcs8InnerWriter.Write(@([System.Byte]0x2A, [System.Byte]0x86, [System.Byte]0x48, [System.Byte]0x86, [System.Byte]0xF7, [System.Byte]0x0D, [System.Byte]0x01, [System.Byte]0x01, [System.Byte]0x01), 0, 9)
                        $pkcs8InnerWriter.Write([System.Byte]0x05) # NULL
                        $pkcs8InnerWriter | Write-CertificateDerLength -Length 0

                        $pkcs8InnerWriter.Write([System.Byte]0x04) # OCTET STRING
                        $pkcs8InnerWriter | Write-CertificateDerLength -Length $pkcs1Bytes.Length
                        $pkcs8InnerWriter.Write($pkcs1Bytes, 0, $pkcs1Bytes.Length)

                        $pkcs8InnerLength = [System.Convert]::ToInt32($pkcs8InnerStream.Length)
                        $pkcs8Writer | Write-CertificateDerLength -Length $pkcs8InnerLength
                        $pkcs8Writer.Write($pkcs8InnerStream.GetBuffer(), 0, $pkcs8InnerLength)
                    }
                    finally
                    {
                        $pkcs8InnerWriter.Dispose()
                    }
                }
                finally
                {
                    $pkcs8InnerStream.Dispose()
                }

                $pkcs1Bytes = $pkcs8Stream.ToArray()
            }
            finally
            {
                $pkcs8Writer.Dispose()
            }
        }
        finally
        {
            $pkcs8Stream.Dispose()
        }

        # Write the Base64 encoded PKCS#8 private key to the specified output
        # file path containing the PKCS#1 private key as a nested structure.
        $pkcs8Base64 = ConvertTo-CertificateBase64 -Type 'PRIVATE KEY' -Byte $pkcs8Stream.ToArray()
        [System.IO.File]::WriteAllText($OutPath, $pkcs8Base64)
    }
}
