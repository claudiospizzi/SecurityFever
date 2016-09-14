
function Invoke-AuditPolListSubcategoryAllCsv
{
    [CmdletBinding()]
    param ()

    (auditpol.exe /list /subcategory:* /r) |
        Where-Object { -not [String]::IsNullOrEmpty($_) }
}
