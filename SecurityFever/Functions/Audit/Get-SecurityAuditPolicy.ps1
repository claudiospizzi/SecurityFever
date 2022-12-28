<#
    .SYNOPSIS
        List the current audit policy setting on the local system.

    .DESCRIPTION
        This command uses the auditpol.exe command to get the current audit
        policy setting for the local system and parse the output into a custom
        object.

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.Audit.Policy. Array of custom audit policy objects.

    .EXAMPLE
        PS C:\> Get-SecurityAuditPolicy
        Return all local security audit policies.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-SecurityAuditPolicy
{
    [CmdletBinding()]
    param ()

    # Because the auditpol.exe command needs administrative permission, verify
    # if the current session is startet as administrator.
    Test-AdministratorRole -Throw

    # Use the helper functions to execute the auditpol.exe queries. The
    # functions are used so that testing and mocking is possible.
    $csvAuditCategories = Invoke-AuditPolListSubcategoryAllCsv | ConvertFrom-Csv
    $csvAuditSettings   = Invoke-AuditPolGetCategoryAllCsv | ConvertFrom-Csv

    foreach ($csvAuditCategory in $csvAuditCategories)
    {
        # If the Category/Subcategory field starts with two blanks, it is a
        # subcategory entry - else a category entry.
        if ($csvAuditCategory.'GUID' -like '{*-797A-11D9-BED3-505054503030}')
        {
            $lastCategory     = $csvAuditCategory.'Category/Subcategory'
            $lastCategoryGuid = $csvAuditCategory.GUID
        }
        else
        {
            $csvAuditSetting = $csvAuditSettings | Where-Object { $_.'Subcategory GUID' -eq $csvAuditCategory.GUID }

            # Return the result object
            [PSCustomObject] @{
                PSTypeName      = 'SecurityFever.Audit.Policy'
                ComputerName    = $csvAuditSetting.'Machine Name'
                Category        = $lastCategory
                CategoryGuid    = $lastCategoryGuid
                Subcategory     = $csvAuditSetting.'Subcategory'
                SubcategoryGuid = $csvAuditSetting.'Subcategory GUID'
                AuditSuccess    = $csvAuditSetting.'Inclusion Setting' -like '*Success*'
                AuditFailure    = $csvAuditSetting.'Inclusion Setting' -like '*Failure*'
            }
        }
    }
}
