<#
    .SYNOPSIS
        Start a new PowerShell Console session.

    .DESCRIPTION
        Start a new PowerShell Console session with alternative credentials. It
        uses the Start-Process cmdlet and use the system drive as a working
        directory.

    .INPUTS
        None.

    .OUTPUTS
        None.

    .EXAMPLE
        PS C:\> Invoke-PowerShell -Credential 'DOMAIN\user'
        Start a new PowerShell Console session with alternative credentials.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Invoke-PowerShell
{
    [CmdletBinding()]
    [Alias('posh')]
    param
    (
        # Alternative credentials to start a PowerShell Console session.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    Start-Process -FilePath "$PSHOME\powershell.exe" -WorkingDirectory $Env:SystemDrive -Credential $Credential
}
