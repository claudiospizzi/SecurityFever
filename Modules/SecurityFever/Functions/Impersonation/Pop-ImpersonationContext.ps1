<#
    .SYNOPSIS
    Leave the current impersonation context.

    .DESCRIPTION
    If the current session was impersonated with Push-ImpersonationContext, this
    command will leave the impersonation context.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    PS C:\> Pop-ImpersonationContext
    Leave the current impersonation context.

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
