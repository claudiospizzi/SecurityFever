<#
    .SYNOPSIS


    .DESCRIPTION


    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    PS C:\>


    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/SecurityFever
#>

function Get-SecurityAuditPolicySetting
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
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
        $Setting
    )

    $AuditPolicies = Get-SecurityAuditPolicy

    foreach ($AuditPolicy in $AuditPolicies)
    {
        if ($AuditPolicy.Category -eq $Category -and $AuditPolicy.Subcategory -eq $Subcategory)
        {
            switch ($Setting)
            {
                'Success' { return $AuditPolicy.AuditSuccess }
                'Failure' { return $AuditPolicy.AuditFailure }
            }
        }
    }

    throw "No audit policy found for category $Category and subcategory $Subcategory."
}
