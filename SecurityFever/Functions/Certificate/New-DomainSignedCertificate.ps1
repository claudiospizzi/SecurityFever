<#
    .SYNOPSIS
        Create a new certificate signed by a domain-based enterprise CA.

    .DESCRIPTION
        Use the tools certreq.exe and optionally openssl.exe to request a domain
        signed certificate. The certificate is always a SAN certificate where
        wildcard entries and e.g. IP adressess are allowed. The subject is
        inserted at the first position of the SAN list.
        The certificate will be exported in Windows compatible binary formats as
        X.509 DER (.cer) and PKCS #12 (.pfx). If the flag -Base64 is specified,
        the certificate is converted into Linux/Unix compatible Base64 PEM format
        as X.509 PEM (.pem) and RSA (.key).

    .EXAMPLE
        PS C:\> New-DomainSignedCertificate
        Create a new certificate. PowerShell will prompt for subject, dns name
        and password.

    .EXAMPLE
        PS C:\> New-DomainSignedCertificate -Subject 'contoso.com' -DnsName 'contoso.com', '*.contoso.com'
        Create a new wildcard SAN certificate for contoso.

    .EXAMPLE
        PS C:\> New-DomainSignedCertificate -Subject 'contoso.com' -DnsName 'contoso.com', '*.contoso.com' -Base64
        Create a new wildcard SAN certificate for contoso and include Linux/Unix
        formatted certificate and key files.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function New-DomainSignedCertificate
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param
    (
        # Subject of the certificate, without the 'CN=' prefix. This subject is
        # always included as dns name or IP address in the subject alternative
        # name.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Subject,

        # Add dns names to the subject alternative name.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [System.String[]]
        $DnsName,

        # Add IP addresses to the subject alternative name.
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [System.String[]]
        $IPAddress,

        # Optional friendly name to set on the imported certificate.
        [Parameter(Mandatory = $false)]
        [System.String]
        $FriendlyName,

        # Specify the key usage extensions.
        [Parameter(Mandatory = $false)]
        [ValidateSet('ServerAuthentication', 'ClientAuthentication')]
        [System.String[]]
        $EnhancedKeyUsage = 'ServerAuthentication',

        # Length of the private key, by default 2048.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $KeyLength = 2048,

        # Name of the CA certificate template to use.
        [Parameter(Mandatory = $false)]
        [System.String]
        $CertificateTemplate = 'InternalWebServer',

        # Password to encrypt the pfx file.
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]
        $Password,

        # Option to export the certificate as Base64. Requires openssl.exe.
        [Parameter(Mandatory = $false)]
        [switch]
        $Base64,

        # Path to the working folder where the files will be stored.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Path = (Get-Location).Path,

        # Overwrite the existing files.
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    $ErrorActionPreference = 'Stop'

    try
    {
        $activity = "Generate Certificate for CN=$Subject"
        Write-Progress -Activity $activity -Status 'Setup' -PercentComplete 0

        # Check if the current user is admin. This is required to request the
        # certificate and create the private key.
        if (-not (Test-AdministratorRole))
        {
            throw 'Access denied. Restart this command as administrator.'
        }

        # Check and get native commands
        $certReqCmd = Get-CommandPath -Name 'certreq.exe'
        if ($Base64.IsPresent)
        {
            $openSslCmd = Get-CommandPath -Name 'openssl.exe' -WarningMessage 'Download OpenSSL for Windows from https://slproweb.com/products/Win32OpenSSL.html'
        }

        # If the friendly name wasn't specified, use the subject
        if (-not $PSBoundParameters.ContainsKey('FriendlyName'))
        {
            $FriendlyName = $Subject
        }

        # Append subject to the dns name or ip address
        if ($Subject -match '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
        {
            if ($IPAddress -notcontains $Subject)
            {
                $IPAddress = @($Subject) + $IPAddress
            }
        }
        else
        {
            if ($DnsName -notcontains $Subject)
            {
                $DnsName = @($Subject) + $DnsName
            }
        }

        # Prepare certificate definition
        $policy = @()
        $policy += '[Version]'
        $policy += 'Signature = "$Windows NT$"'
        $policy += ''
        $policy += '[NewRequest]'
        $policy += 'Subject = "CN={0}"' -f $Subject
        $policy += 'Exportable = TRUE'
        $policy += 'KeyLength = {0}' -f $KeyLength
        $policy += 'KeySpec = 1'
        $policy += 'KeyUsage = 0xA0'
        $policy += 'MachineKeySet = True'
        $policy += 'ProviderName = "Microsoft RSA SChannel Cryptographic Provider"'
        $policy += 'RequestType = PKCS10'
        $policy += ''
        $policy += '[EnhancedKeyUsageExtension]'
        foreach ($currentEnhancedKeyUsage in $EnhancedKeyUsage)
        {
            switch ($currentEnhancedKeyUsage)
            {
                'ServerAuthentication' { $policy += 'OID = 1.3.6.1.5.5.7.3.1' }
                'ClientAuthentication' { $policy += 'OID = 1.3.6.1.5.5.7.3.2' }
            }
        }
        $policy += ''
        $policy += '[Extensions]'
        $policy += '2.5.29.17 = "{text}"'
        foreach ($currentDnsName in $DnsName)
        {
            if (-not [System.String]::IsNullOrEmpty($currentDnsName))
            {
                $policy += '_continue_ = "DNS={0}&"' -f $currentDnsName
            }
        }
        foreach ($currentIPAddress in $IPAddress)
        {
            if (-not [System.String]::IsNullOrEmpty($currentIPAddress))
            {
                $policy += '_continue_ = "IPAddress={0}&"' -f $currentIPAddress
            }
        }
        $policy += ''
        $policy += '[RequestAttributes]'
        $policy += 'CertificateTemplate = {0}' -f $CertificateTemplate

        if ($PSCmdlet.ShouldProcess("CN=$Subject", 'Create'))
        {
            # Trim the path and cleanup existing files if the -Force parameter
            # is specified. Else stop the script with an exception.
            $Path = $Path.TrimEnd('\')
            $extensions = 'inf', 'req', 'rsp', 'cer', 'pfx'
            if ($Base64.IsPresent)
            {
                $extensions += 'pem', 'key'
            }
            foreach ($extension in $extensions)
            {
                $filePath = "$Path\$Subject.$extension"
                if (Test-Path -Path $filePath)
                {
                    if ($Force.IsPresent)
                    {
                        Remove-Item -Path $filePath -Force -Confirm:$false
                    }
                    else
                    {
                        throw "The file $filePath already exists!"
                    }
                }
            }


            # Step 1
            # Store the policy file

            Write-Verbose "Create policy file $Subject.inf"

            Write-Progress -Activity $activity -Status "Create policy file $Subject.inf" -PercentComplete 14

            Set-Content -Path "$Path\$Subject.inf" -Value $policy


            # Step 2
            # Create a certificate request and store the private key in the
            # current user or computer session (if admin)

            Write-Verbose "Create request file $Subject.req"
            Write-Verbose "> certreq.exe -new -q -f `"$Path\$Subject.inf`" `"$Path\$Subject.req`""

            Write-Progress -Activity $activity -Status "Create request file $Subject.req" -PercentComplete 28

            $result = (& $certReqCmd -new -q -f "`"$Path\$Subject.inf`"" "`"$Path\$Subject.req`"")

            if ($Global:LASTEXITCODE -ne 0)
            {
                throw "Failed to create the certificate request!`n`n$result"
            }


            # Step 3
            # Submit the certificate request to the CA

            Write-Verbose "Sign request and export to $Subject.cer"
            Write-Verbose "> certreq.exe -submit -f `"$Path\$Subject.req`" `"$Path\$Subject.cer`""

            Write-Progress -Activity $activity -Status "Sign request and export to $Subject.cer" -PercentComplete 28

            $result = (& $certReqCmd -submit -f "`"$Path\$Subject.req`"" "`"$Path\$Subject.cer`"")

            if ($Global:LASTEXITCODE -ne 0)
            {
                throw "Failed to submit the certificate request!`n`n$result"
            }


            # Step 4
            # Accept the request and import it into the local cert store

            Write-Verbose "Accept and import signed certificate $Subject.cer"
            Write-Verbose "> certreq.exe -accept -q `"$Path\$Subject.cer`""

            Write-Progress -Activity $activity -Status "Accept and import signed certificate $Subject.cer" -PercentComplete 42

            $result = (& $certReqCmd -accept -q "`"$Path\$Subject.cer`"")

            if ($Global:LASTEXITCODE -ne 0)
            {
                throw "Failed to accept the certificate request!`n`n$result"
            }


            # Step 5
            # Export certificate as PKCS #12 (.pfx) file

            Write-Verbose "Export the certificate as PKCS #12 to $Subject.pfx"
            Write-Verbose "> Export-PfxCertificate -FilePath '$Path\$Subject.pfx'"

            Write-Progress -Activity $activity -Status "Export the certificate as PKCS #12 to $Subject.pfx" -PercentComplete 56

            # Extract thumbprint from the cer file
            $thumbprint = Get-PfxCertificate -FilePath "$Path\$Subject.cer" | Select-Object -ExpandProperty 'Thumbprint'

            # Export the pfx protected by a password
            Get-Item -Path "Cert:\LocalMachine\My\$thumbprint" | Export-PfxCertificate -FilePath "$Path\$Subject.pfx" -Password $Password | Out-Null


            # Step 6
            # Export certificate as X.509 PEM (.pem) file

            if ($Base64.IsPresent)
            {
                Write-Verbose "Export the certificate as X.509 PEM to $Subject.pem"
                Write-Verbose "> openssl.exe pkcs12 -passin pass:`"***`" -in `"$Path\$Subject.pfx`" -clcerts -nokeys -out `"$Path\$Subject.pem`""
                Write-Verbose "> openssl.exe x509 -in `"$Path\$Subject.pem`" -out `"$Path\$Subject.pem`""

                Write-Progress -Activity $activity -Status "Export the certificate as X.509 PEM to $Subject.pem" -PercentComplete 70

                $result = (& $openSslCmd pkcs12 -passin "pass:`"$(Unprotect-SecureString -SecureString $Password)`"" -in "`"$Path\$Subject.pfx`"" -clcerts -nokeys -out "`"$Path\$Subject.pem`"")

                if ($Global:LASTEXITCODE -ne 0)
                {
                    throw "Failed to convert the certificate from pfx to pem!"
                }

                $result = (& $openSslCmd x509 -in "`"$Path\$Subject.pem`"" -out "`"$Path\$Subject.pem`"")

                if ($Global:LASTEXITCODE -ne 0)
                {
                    throw "Failed to convert the certificate from pfx to pem!"
                }
            }


            # Step 7
            # Export certificate as RSA (.key) file

            if ($Base64.IsPresent)
            {
                Write-Verbose "Export the certificate as RSA to $Subject.key"
                Write-Verbose "> openssl.exe pkcs12 -passin pass:`"***`" -in `"$Path\$Subject.pfx`" -nocerts -out `"$Path\$Subject.key`" -nodes"
                Write-Verbose "> openssl.exe rsa -in `"$Path\$Subject.key`" -out `"$Path\$Subject.key`""

                Write-Progress -Activity $activity -Status "Export the certificate as RSA to $Subject.key" -PercentComplete 84

                $result = (& $openSslCmd pkcs12 -passin "pass:`"$(Unprotect-SecureString -SecureString $Password)`"" -in "`"$Path\$Subject.pfx`"" -nocerts -out "`"$Path\$Subject.key`"" -nodes)

                if ($Global:LASTEXITCODE -ne 0)
                {
                    throw "Failed to convert the certificate from pfx to key!"
                }

                $ErrorActionPreference = 'SilentlyContinue'
                $result = (& $openSslCmd rsa -in "`"$Path\$Subject.key`"" -out "`"$Path\$Subject.key`"" 2>&1)
                $ErrorActionPreference = 'Stop'

                if ($Global:LASTEXITCODE -ne 0)
                {
                    throw "Failed to convert the certificate from pfx to key!"
                }
            }


            # Finally, update the friendly name, get the certificate object and
            # return it to the pipeline
            $certificate = Get-Item -Path "Cert:\LocalMachine\My\$thumbprint"
            $certificate.FriendlyName = $FriendlyName
            Write-Output $certificate
        }
    }
    catch
    {
        throw $_
    }
    finally
    {
        Write-Progress -Activity $activity -PercentComplete 100 -Completed
    }
}
