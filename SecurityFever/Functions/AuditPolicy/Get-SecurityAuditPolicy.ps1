<#
    .SYNOPSIS
        List the current audit policy setting on the local system.

    .DESCRIPTION
        This command uses the auditpol.exe command to get the current audit
        policy setting for the local system and parses the output into a custom
        object.

    .INPUTS
        None.

    .OUTPUTS
        SecurityFever.AuditPolicy. Array of custom audit policy objects.

    .EXAMPLE
        PS C:\> Get-SecurityAuditPolicy
        Return all local security audit policies.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Get-SecurityAuditPolicy
{
    [CmdletBinding()]
    param ()

    # Because the auditpol.exe cmdlet need administration permission, verify if
    # the current session is startet as administrator.
    if (-not (Test-AdministratorRole))
    {
        throw 'Access denied. Please start this functions as an administrator.'
    }

    # Use the helper functions to execute the auditpol.exe queries.
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
                PSTypeName      = 'SecurityFever.AuditPolicy'
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
