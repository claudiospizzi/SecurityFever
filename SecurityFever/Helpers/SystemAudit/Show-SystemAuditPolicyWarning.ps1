<#
    .SYNOPSIS
        Test if the audit policy setting is enabled.
#>
function Show-SystemAuditPolicyWarning
{
    [CmdletBinding()]
    param
    (
        # Audit policy category
        [Parameter(Mandatory = $true)]
        [System.String]
        $Category,

        # Audit policy subcategory
        [Parameter(Mandatory = $true)]
        [System.String]
        $Subcategory,

        # Audit policy setting
        [Parameter(Mandatory = $true)]
        [ValidateSet('Success', 'Failure')]
        [System.String]
        $Setting,

        # Hide the warning messages, don't test the prerequisites.
        [Parameter(Mandatory = $false)]
        [Switch]
        $HideWarning
    )

    if ($HideWarning.IsPresent)
    {
        return
    }

    if (-not (Get-SecurityAuditPolicySetting -Category $Category -Subcategory $Subcategory -Setting $Setting))
    {
        Write-Warning ('Audit Policy setting for {0} {1} in category {2} is not enabled!' -f $Setting, $Subcategory, $Category)
    }
}
