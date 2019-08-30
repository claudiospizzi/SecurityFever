<#
    .SYNOPSIS
        Create a new certificate signed by an domain-based enterprise ca.

    .DESCRIPTION
        Use the tools certreq.exe and openssl.exe to request a domain signed
        certificate and export it as Windows (.cer, .pfx) and Linux (.pem, .key)
        formatted certificate.

    .EXAMPLE
        PS C:\> New-DomainSignedCertificate
        Create a new certificate. PowerShell will prompt for subject, dns name
        and password.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function New-DomainSignedCertificate
{
    [CmdletBinding()]
    param
    (
        # Subject of the certificate, without the 'CN=' prefix. This subject is
        # always included as dns name in the subject alternative name.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Subject,

        # Add dns names to the subject alternative name.
        [Parameter(Mandatory = $true, Position = 1)]
        [AllowEmptyCollection()]
        [System.String[]]
        $DnsName,

        # Add ip addresses to the subject alternative name.
        [Parameter(Mandatory = $false, Position = 2)]
        [AllowEmptyCollection()]
        [System.String[]]
        $IPAddress,

        # Specify the key usage extensions.
        [Parameter(Mandatory = $false)]
        [ValidateSet('ServerAuthentication', 'ClientAuthentication')]
        [System.String]
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

        # Overwrite the existing files.
        [Parameter(Mandatory = $false)]
        [switch]
        $Force,

        # Path to the working folder where the files will be stored.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Path = (Get-Location).Path,

        # Keep all extra files like the policy definition or request file.
        [Parameter(Mandatory = $false)]
        [switch]
        $Keep
    )

    $ErrorActionPreference = 'Stop'

    try
    {
        Write-Progress -Activity "Generate Certificate for CN=$Subject" -Status 'Setup' -PercentComplete 0

        # Policy template definitions
        $enhancedKeyUsageOidMap = @{
            'ServerAuthentication' = '1.3.6.1.5.5.7.3.1'
            'ClientAuthentication' = '1.3.6.1.5.5.7.3.2'
        }

        # Check if the current user is admin
        if (-not (Test-AdministratorRole))
        {
            throw 'Access denied. Restart this command as administrator.'
        }

        # Check and get native commands
        $certReqCmd  = Get-CommandPath -Name 'certreq.exe'
        $openSslCmd  = Get-CommandPath -Name 'openssl.exe' -WarningMessage 'Download OpenSSL for Windows from https://slproweb.com/products/Win32OpenSSL.html'

        # Trim the path and cleanup existing files
        $Path = $Path.TrimEnd('\')
        foreach ($extension in 'cer', 'inf', 'key', 'pem', 'pfx', 'req', 'rsp')
        {
            $filePath ="$Path\$Subject.$extension"
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
            $policy += 'OID = {0}' -f $enhancedKeyUsageOidMap[$currentEnhancedKeyUsage]
        }
        $policy += ''
        $policy += '[Extensions]'
        $policy += '2.5.29.17 = "{text}"'
        foreach ($currentDnsName in $DnsName)
        {
            $policy += '_continue_ = "DNS={0}&"' -f $currentDnsName
        }
        foreach ($currentIPAddress in $IPAddress)
        {
            $policy += '_continue_ = "IPAddress={0}&"' -f $currentIPAddress
        }
        $policy += ''
        $policy += '[RequestAttributes]'
        $policy += 'CertificateTemplate = {0}' -f $CertificateTemplate


        # Step 1
        # Store the policy file

        Write-Verbose "Create policy file $Subject.inf"

        Write-Progress -Activity "Generate Certificate for CN=$Subject" -Status "Create policy file $Subject.inf" -PercentComplete 14

        Set-Content -Path "$Path\$Subject.inf" -Value $policy


        # Step 2
        # Create a certificate request and store the private key in the user session

        Write-Verbose "Create request file $Subject.req"
        Write-Verbose "  certreq.exe -new -q -f `"$Path\$Subject.inf`" `"$Path\$Subject.req`""

        Write-Progress -Activity "Generate Certificate for CN=$Subject" -Status "Create request file $Subject.req" -PercentComplete 28

        $result = (& $certReqCmd -new -q -f "`"$Path\$Subject.inf`"" "`"$Path\$Subject.req`"")

        if ($Global:LASTEXITCODE -ne 0)
        {
            throw "Failed to create the certificate request!`n`n$result"
        }


        # Step 3
        # Submit the certificate request to the CA

        Write-Verbose "Sign request and export to $Subject.cer"
        Write-Verbose "  certreq.exe -submit -q -f `"$Path\$Subject.req`" `"$Path\$Subject.cer`""

        Write-Progress -Activity "Generate Certificate for CN=$Subject" -Status "Sign request and export to $Subject.cer" -PercentComplete 28

        $result = (& $certReqCmd -submit -q -f "`"$Path\$Subject.req`"" "`"$Path\$Subject.cer`"")

        if ($Global:LASTEXITCODE -ne 0)
        {
            throw "Failed to submit the certificate request!`n`n$result"
        }


        # Step 4
        # Accept the request and import it into the local cert store

        Write-Verbose "Accept and import signed certificate $Subject.cer"
        Write-Verbose "  certreq.exe -accept -q `"$Path\$Subject.cer`""

        Write-Progress -Activity "Generate Certificate for CN=$Subject" -Status "Accept and import signed certificate $Subject.cer" -PercentComplete 42

        $result = (& $certReqCmd -accept -q "`"$Path\$Subject.cer`"")

        if ($Global:LASTEXITCODE -ne 0)
        {
            throw "Failed to accept the certificate request!`n`n$result"
        }


        # Step 5
        # Export certificate as PFX file

        Write-Verbose "Export the certificate as PFX to $Subject.pfx"

        Write-Progress -Activity "Generate Certificate for CN=$Subject" -Status "Export the certificate as PFX to $Subject.pfx" -PercentComplete 56

        # Extract thumbprint from the cer file
        $thumbprint = Get-PfxCertificate -FilePath "$Path\$Subject.cer" | Select-Object -ExpandProperty 'Thumbprint'

        # Export the pfx protected by a password
        Get-Item -Path "Cert:\LocalMachine\My\$thumbprint" | Export-PfxCertificate -FilePath "$Path\$Subject.pfx" -Password $Password | Out-Null


        # Step 6
        # Export certificate as PEM file

        Write-Verbose "Export the certificate as PEM to $Subject.pem"
        Write-Verbose "  openssl.exe pkcs12 -passin pass:`"***`" -in `"$Path\$Subject.pfx`" -clcerts -nokeys -out `"$Path\$Subject.pem`""
        Write-Verbose "  openssl.exe x509 -in `"$Path\$Subject.pem`" -out `"$Path\$Subject.pem`""

        Write-Progress -Activity "Generate Certificate for CN=$Subject" -Status "Export the certificate as PEM to $Subject.pem" -PercentComplete 70

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


        # Step 7
        # Export certificate as KEY file

        Write-Verbose "Export the certificate as KEY to $Subject.key"
        Write-Verbose "  openssl.exe pkcs12 -passin pass:`"***`" -in `"$Path\$Subject.pfx`" -nocerts -out `"$Path\$Subject.key`" -nodes"
        Write-Verbose "  openssl.exe rsa -in `"$Path\$Subject.key`" -out `"$Path\$Subject.key`""

        Write-Progress -Activity "Generate Certificate for CN=$Subject" -Status "Export the certificate as KEY to $Subject.key" -PercentComplete 84

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

        if (-not $Keep.IsPresent)
        {
            Get-Item -Path "Cert:\LocalMachine\My\$thumbprint"

            Remove-Item -Path "$Path\$Subject.inf" -Force -Confirm:$false
            Remove-Item -Path "$Path\$Subject.req" -Force -Confirm:$false
            Remove-Item -Path "$Path\$Subject.rsp" -Force -Confirm:$false
        }
    }
    catch
    {
        throw $_
    }
    finally
    {
        Write-Progress -Activity "Generate Certificate for CN=$Subject" -PercentComplete 100 -Completed
    }
}
