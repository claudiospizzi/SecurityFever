
function Invoke-AuditPolGetCategoryAllCsv
{
    [CmdletBinding()]
    param ()

    (auditpol.exe /get /category:* /r) |
        Where-Object { -not [String]::IsNullOrEmpty($_) }
}
