<#
    .SYNOPSIS
        Get one audit policy setting on the local system.

    .DESCRIPTION
        This command uses the auditpol.exe command to get the current audit
        policy setting for the local system and parses the output for the target
        setting.

    .INPUTS
        None.

    .OUTPUTS
        System.Boolean. Return true if the audit policy is enabled, false if not.

    .EXAMPLE
        PS C:\> Get-SecurityAuditPolicySetting -Category 'Object Access' -Subcategory 'File System' -Setting 'Success'
        Returns the current setting for success audit on the file system object
        access audit policy.

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

    $auditPolicies = Get-SecurityAuditPolicy

    foreach ($auditPolicy in $auditPolicies)
    {
        if ($auditPolicy.Category -eq $Category -and $auditPolicy.Subcategory -eq $Subcategory)
        {
            switch ($Setting)
            {
                'Success' { return $auditPolicy.AuditSuccess }
                'Failure' { return $auditPolicy.AuditFailure }
            }
        }
    }

    throw "No audit policy found for category $Category and subcategory $Subcategory."
}
