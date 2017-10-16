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

    if ($Global:ImpersonationContext.Count -gt 0)
    {
        # Get the latest impersonation context
        $impersonationContext = $Global:ImpersonationContext.Pop()

        # Undo the impersonation
        $impersonationContext.Undo()
    }
}
