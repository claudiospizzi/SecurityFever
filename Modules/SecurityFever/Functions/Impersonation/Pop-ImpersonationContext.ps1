<#
    .SYNOPSIS
    

    .DESCRIPTION


    .INPUTS
    None.

    .OUTPUTS
    The current impersonation context.

    .EXAMPLE
    PS C:\> 
    

    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/SecurityFever
#>

function Pop-ImpersonationContext
{
    [CmdletBinding()]
    param ()
    
    Initialize-ImpersonationContext

    # Get the global impersonation context
    $globalImpersonationContext = Get-Variable -Name 'ImpersonationContext' -Scope 'Global'

    if ($globalImpersonationContext.Count -gt 0)
    {
        # Get the latest impersonation context
        $impersonationContext = $globalImpersonationContext.Pop()

        # Undo the impersonation
        $impersonationContext.Undo()
    }
}
