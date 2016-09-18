<#
    .SYNOPSIS
    Runs the specified command in an elevated context.

    .DESCRIPTION
    Runs the specified command in an elevated context. This is useful on Windows
    systems where the user account control is enabled. Input object and result
    objects are serialized using XML.

    .INPUTS
    None.

    .OUTPUTS
    Output of the invoked script block or command.

    .EXAMPLE
    PS C:\>


    .NOTES
    Author     : Claudio Spizzi
    License    : MIT License

    .LINK
    https://github.com/claudiospizzi/SecurityFever
#>

function Invoke-Elevated
{
    [CmdletBinding()]
    [Alias('sudo')]
    param
    (
        # The path to an executable program.
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'FilePath')]
        [System.String]
        $FilePath,

        # The script block to execute in an elevated context.
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        # Optional argument list for the program or the script block.
        [Parameter(Mandatory = $false, Position = 2)]
        [System.Object[]]
        $ArgumentList
    )

    if ($PSCmdlet.ParameterSetName -eq 'FilePath')
    {

    }

    if ($PSCmdlet.ParameterSetName -eq 'ScriptBlock')
    {
        try
        {
            # To transport the parameters, script outputs and the errors, we use
            # the CliXml object serialization and temporary files. This is
            # necessary because the elevated process runs in an elevated context
            $scriptBlockFile   = [System.IO.Path]::GetTempFileName() + '.xml'
            $argumentListFile  = [System.IO.Path]::GetTempFileName() + '.xml'
            $commandOutputFile = [System.IO.Path]::GetTempFileName() + '.xml'
            $commandErrorFile  = [System.IO.Path]::GetTempFileName() + '.xml'

            $ScriptBlock  | Export-Clixml -Path $scriptBlockFile
            $ArgumentList | Export-Clixml -Path $argumentListFile

            # Create a command string which contains all command executed in the
            # elevated session. The wrapper of the script block is needed to
            # pass the parameters and return all outputs objects and errors.
            $commandString = ''
            $commandString += 'Set-Location -Path "{0}";' -f $pwd.Path
            $commandString += '$scriptBlock  = [System.Management.Automation.ScriptBlock]::Create((Import-Clixml -Path "{0}"));' -f $scriptBlockFile
            $commandString += '$argumentList = [System.Object[]] (Import-Clixml -Path "{0}");' -f $argumentListFile
            $commandString += '$output = Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $argumentList;'
            $commandString += '$error | Export-Clixml -Path "{0}";' -f $commandErrorFile
            $commandString += '$output | Export-Clixml -Path "{0}";' -f $commandOutputFile

            $commandEncoded = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($commandString))

            $processStart = New-Object -TypeName System.Diagnostics.ProcessStartInfo -ArgumentList 'C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe'
            $processStart.Arguments   = '-NoProfile -NonInteractive -EncodedCommand {0}' -f $commandEncoded
            $processStart.Verb        = 'RunAs'
            $processStart.WindowStyle = 'Hidden'

            $process = New-Object -TypeName System.Diagnostics.Process
            $process.StartInfo = $processStart
            $process.Start() | Out-Null

            Write-Verbose "Elevated powershell.exe process started with id $($process.Id)."

            $process.WaitForExit()

            Write-Verbose "Elevated powershell.exe process stopped with exit code $($process.ExitCode)."

            if ((Test-Path -Path $commandErrorFile))
            {
                Import-Clixml -Path $commandErrorFile | ForEach-Object { Write-Error $_ }
            }

            if ((Test-Path -Path $commandOutputFile))
            {
                Import-Clixml -Path $commandOutputFile | Write-Output
            }
        }
        catch
        {
            throw $_
        }
        finally
        {
            if ($null -ne $process)
            {
                $process.Dispose()
            }

            Remove-Item -Path $scriptBlockFile   -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $argumentListFile  -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $commandOutputFile -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $commandErrorFile  -Force -ErrorAction SilentlyContinue
        }
    }
}
