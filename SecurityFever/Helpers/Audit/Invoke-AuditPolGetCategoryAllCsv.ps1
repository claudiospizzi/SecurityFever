<#
    .SYNOPSIS
        Helper function for the audit policy commands.
#>
function Invoke-AuditPolGetCategoryAllCsv
{
    [CmdletBinding()]
    param ()

    Write-Verbose 'Invoke command: auditpol.exe /get /category:* /r'

    (auditpol.exe /get /category:* /r) | Where-Object { -not [String]::IsNullOrEmpty($_) }
}
