<#
    .SYNOPSIS
        Convert certificates files into other formats.

    .DESCRIPTION
        Function to convert certificate files. This function is using native
        crypto functions and does not required external dependencies.

        The following overview should give a short introduction about
        certificates and their file formats:

        - X.509/DER (.cer)
            Contains the public part of a single X.509 certificate in the
            binary DER format. Used primary on Windows systems.

        - X.509/PEM (.pem)
            Contains the public part of a single X.509 certificate in the
            Base64 encoded PEM format. Used primary on Linux systems.

        - X.509/PKCS#7 (.p7b)
            Contains the public part of one or more X.509 certificates in the
            Base64 encoded PKCS#7 format. Used primary on Windows systems.

        - PKCS#12 (.pfx/.p12)
            Contains the public and private part of one or more X.509
            certificates in the binary PKCS#12 format. Used primary on Windows
            systems. Because it's a mix of public and private keys, it is not
            only an X.509 certificate but more container.

        Input certificate formats supported by this command:
        - X.509/DER
        - X.509/PEM
        - PKCS#7 (.p7b)
        - PKCS#12 (AES/3DES password encrypted)

        Output certificate formats supported by this command:
        - X.509/DER
        - X.509/PEM

        Ideas but not yet implemented certificate formats:
        - PKCS#1 private key
        - PKCS#8 private key

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
        [ValidateScript({ Test-Path -Path $_ })]
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

        # Type of the output certificate file.
        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateSet('X.509/DER', 'X.509/PEM')]
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
                $certificateThumbprint = $certificate.Thumbprint.ToLower()
                $exportFiles += @{
                    Certificate = $certificate
                    OutPath     = [System.IO.Path]::Combine($outDirectory, "$outBaseName-$certificateThumbprint$outExtension")
                }
            }
        }
    }
    else
    {
        Write-Verbose "[Convert-Certificate] Read the certificate file '$InPath' as a basic X.509 certificate."

        # Single export file, nothing special here
        $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($InPath)
        $exportFiles += @{
            Certificate = $certificate
            OutPath     = $OutPath
        }
    }

    function ConvertTo-Base64 ([System.Byte[]] $Byte)
    {
        $straight = [System.Convert]::ToBase64String($Byte)

        # Convert the string to base64 junks with a maximum length of 64
        # characters per line.
        $formatted = [System.Text.StringBuilder]::new()
        for ($i = 0; $i -lt $straight.Length; $i += 64)
        {
            $formatted.AppendLine($straight.Substring($i, [System.Math]::Min(64, $straight.Length - $i))) | Out-Null
        }

        # Remove the new lines for the last empty line and store it as a simple
        # string with newlines, no string array.
        $formattedString = $formatted.ToString().TrimEnd("`n`r")

        return $formattedString
    }

    foreach ($exportFile in $exportFiles)
    {
        Write-Verbose "[Convert-Certificate] Exporting certificate '$($exportFile.Certificate.Subject)' with thumbprint '$($exportFile.Certificate.Thumbprint)' to file '$($exportFile.OutPath)' as '$OutType'."

        switch ($OutType)
        {
            'X.509/DER'
            {
                $certificateBytes  = $exportFile.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
                [System.IO.File]::WriteAllBytes($exportFile.OutPath, $certificateBytes)
            }

            'X.509/PEM'
            {
                $certificateBytes  = $exportFile.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
                $certificateBase64 = ConvertTo-Base64 -Byte $certificateBytes

                $outStringBuilder = [System.Text.StringBuilder]::new()
                $outStringBuilder.AppendLine("-----BEGIN CERTIFICATE-----") | Out-Null
                $outStringBuilder.AppendLine($certificateBase64) | Out-Null
                $outStringBuilder.Append("-----END CERTIFICATE-----") | Out-Null

                Set-Content -Path $exportFile.OutPath -Value $outStringBuilder.ToString()
            }
        }
    }
}
