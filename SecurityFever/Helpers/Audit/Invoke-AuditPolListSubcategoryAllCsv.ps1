<#
    .SYNOPSIS
        Helper function for the audit policy commands.
#>
function Invoke-AuditPolListSubcategoryAllCsv
{
    [CmdletBinding()]
    param ()

    Write-Verbose 'Invoke command: auditpol.exe /list /subcategory:* /r'

    (auditpol.exe /list /subcategory:* /r) | Where-Object { -not [String]::IsNullOrEmpty($_) }
}
