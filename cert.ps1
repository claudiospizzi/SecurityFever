
Write-Host ''
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion.ToString())"

. "$PSScriptRoot\SecurityFever\Functions\Certificate\Export-CertificatePrivateKey.ps1"

$filePath = "$PSScriptRoot\SecurityFever\Tests\Unit\Certificate\TestData\ca-aes.pfx"
$filePath
$filePath = resolve-Path $filePath
$storePath = 'Cert:\CurrentUser\My\2F929746E6670A9453678D0C49B8566540AD64C7'
$password = ConvertTo-SecureString 'Passw0rd' -AsPlainText -Force

$certificates = @()
$certificates += @{
    Name        = 'File'
    Certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($filePath, $password)
}
$certificates += @{
    Name        = 'File (Exportable)'
    Certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($filePath, $password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
}
$certificates += @{
    Name        = 'Store'
    Certificate = Get-Item -Path $storePath
}

foreach ($certificate in $certificates)
{
    Write-Host ''
    Write-Host "Certificate: $($certificate.Name)" -ForegroundColor Magenta
    Write-Host ('*************' + ('*' * $certificate.Name.Length)) -ForegroundColor Magenta
    Write-Host ''
    Write-Host "Type Name        : $($certificate.Certificate.GetType().FullName)"
    Write-Host "Has Private Key  : $($certificate.Certificate.HasPrivateKey)"
    Write-Host "Private Key Type : $(try { $certificate.Certificate.PrivateKey.GetType().FullName } catch { 'N/A' })"
    Write-Host ''
    Write-Host "Private Key AllowExport          : $(try { $certificate.Certificate.PrivateKey.Key.ExportPolicy -contains [System.Security.Cryptography.CngExportPolicies]::AllowExport } catch { 'N/A' })"
    Write-Host "Private Key AllowPlaintextExport : $(try { $certificate.Certificate.PrivateKey.Key.ExportPolicy -contains [System.Security.Cryptography.CngExportPolicies]::AllowPlaintextExport } catch { 'N/A' })"
    Write-Host ''
    Write-Host 'Exporting Private Key Parameters'
    try
    {
        # Export-CertificatePrivateKey -Certificate $certificate.Certificate
        $certificate.Certificate.PrivateKey.ExportParameters($true) | Format-List
    }
    catch
    {
        Write-Host ">> Failed: $_" -ForegroundColor Red
    }
}
# $certificateDefault = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($filePath, $password)
# Write-Host ''
# Write-Host 'Certificate (Default)'
# Write-Host "  Type Name        : $($certificateDefault.GetType().FullName)"
# Write-Host "  Has Private Key  : $($certificateDefault.HasPrivateKey)"
# Write-Host "  Private Key Type : $($certificateDefault.PrivateKey.GetType().FullName)"

# $certificateExportable = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($filePath, $password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
# Write-Host ''
# Write-Host 'Certificate (Exportable)'
# Write-Host "  Type Name        : $($certificateExportable.GetType().FullName)"
# Write-Host "  Has Private Key  : $($certificateExportable.HasPrivateKey)"
# Write-Host "  Private Key Type : $($certificateExportable.PrivateKey.GetType().FullName)"

# $certificateStore = Get-Item -Path $storePath


# Write-Host ''
# Write-Host 'Certificate (Default)'
# Write-Host 'Exporting Private Key Parameters'
# $certificateDefault.PrivateKey.ExportParameters($true)

# Write-Host ''
# Write-Host 'Certificate (Exportable)'
# Write-Host 'Exporting Private Key Parameters'
# $certificateExportable.PrivateKey.ExportParameters($true)
