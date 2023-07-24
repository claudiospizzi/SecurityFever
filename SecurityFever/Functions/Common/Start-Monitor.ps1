<#
    .SYNOPSIS
        Start a PowerShell monitoring based on a script block.

    .DESCRIPTION
        The script block will be invoked for every interval and is checked for
        the boolean return value. If the value is $true, everything is okay. If
        the value is $false, an error is shown. If the state changes, a desktop
        toast notification is displayed.

    .EXAMPLE
        PS C:\> Start-Monitor -ScriptBlock { Test-Path -Path 'C:\Temp\File.txt' }
        Monitor if a file exists.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Start-Monitor
{
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    param
    (
        # The script block to test if the state is ok.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        # Sleep duration between the tests.
        [Parameter(Mandatory = $false)]
        [System.TimeSpan]
        $Interval = '00:00:01',

        # Beep if the state is not ok.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Beep
    )

    do
    {
        $result = & $ScriptBlock

        if ($null -eq $result)
        {
            Write-Warning 'Script block returned nothing ($null).'
            if ($Beep.IsPresent)
            {
                [System.Console]::Beep(880, 500)
            }
            continue
        }

        $resultType = $result.GetType().FullName
        if ($resultType -ne 'System.Boolean')
        {
            Write-Warning "Script block returned [$resultType] but not [System.Boolean]."
            if ($Beep.IsPresent)
            {
                [System.Console]::Beep(880, 500)
            }
            continue
        }

        Write-Host -Object ('{0:dd.MM.yyyy HH:mm:ss} => ' -f (Get-Date)) -NoNewline
        if ($result)
        {
            Write-Host 'Ok' -ForegroundColor 'DarkGreen'
        }
        else
        {
            Write-Host 'Failed' -ForegroundColor 'Red'
            if ($Beep.IsPresent)
            {
                [System.Console]::Beep(440, 500)
                [System.Console]::Beep(440, 500)
            }
        }
    }
    while (-not (Start-Sleep -Seconds $Interval.TotalSeconds))
}
