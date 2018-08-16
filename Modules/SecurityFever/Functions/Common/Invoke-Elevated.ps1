<#
    .SYNOPSIS
        Runs the specified command in an elevated context.

    .DESCRIPTION
        Runs the specified command in an elevated context. This is useful on
        Windows systems where the user account control is enabled. Input object
        and result objects are serialized using XML.
        It's important, the command does use the current user context. This
        means, the current user needs administrative permissions on the local
        system. If no file path or script block is specified, the current
        running process will be run as administrator.

    .INPUTS
        None.

    .OUTPUTS
        Output of the invoked script block or command.

    .EXAMPLE
        PS C:\> Invoke-Elevated
        Will start the current process, e.g. PowerShell Console or ISE, in an
        elevated session as Administrator.

    .EXAMPLE
        PS C:\> Invoke-Elevated -FilePath 'C:\Temp\script.ps1'
        Start the script in an elevated session and return the result.

    .EXAMPLE
        PS C:\> Invoke-Elevated -ScriptBlock { Get-DscLocalConfigurationManager }
        Start the script in an elevated session and return the result.

    .EXAMPLE
        PS C:\> Invoke-Elevated -ScriptBlock { param ($Path) Remove-Item -Path $Path } -ArgumentList 'C:\Windows\test.txt'
        Delete a file from the program files folder with elevated permission,
        beacuse a normal user account has no permissions.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Invoke-Elevated
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    [Alias('sudo')]
    param
    (
        # The path to an executable program.
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'FilePath')]
        [ValidateScript({Test-Path -Path $_})]
        [System.String]
        $FilePath,

        # The script block to execute in an elevated context.
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'ScriptBlock')]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        # Optional argument list for the program or the script block.
        [Parameter(Mandatory = $false, Position = 1)]
        [System.Object[]]
        $ArgumentList
    )

    if ($PSCmdlet.ParameterSetName -eq 'None')
    {
        # If no file path and script block was specified, just elevate the
        # current session for interactive use. For this, use the start info
        # object of the current process and start an elevated new one.
        $currentProcess = Get-Process -Id $PID

        $processStart = $currentProcess.StartInfo
        $processStart.FileName = $currentProcess.Path
        $processStart.Verb     = 'RunAs'

        $process = New-Object -TypeName System.Diagnostics.Process
        $process.StartInfo = $processStart
        $process.Start() | Out-Null
    }

    if ($PSCmdlet.ParameterSetName -eq 'FilePath')
    {
        # If a file path instead of a script block was specified, just load the
        # file content and parse it as script block.
        $ScriptBlock = [System.Management.Automation.ScriptBlock]::Create((Get-Content -Path $FilePath -ErrorAction Stop -Raw))
    }

    if ($PSCmdlet.ParameterSetName -eq 'FilePath' -or $PSCmdlet.ParameterSetName -eq 'ScriptBlock')
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

            # Get the current PowerShell drive. If this does not exist, it has
            # to be created in the session. Switch to the system drive, to
            # prevent errors for missing drives.
            $drive = Get-Location | Select-Object -ExpandProperty 'Drive'
            Push-Location -Path "$Env:SystemDrive\"

            # Create a command string which contains all command executed in the
            # elevated session. The wrapper of the script block is needed to
            # pass the parameters and return all outputs objects and errors.
            $commandString = ''
            $commandString += 'if ($null -eq (Get-PSDrive -Name "{0}" -ErrorAction SilentlyContinue)) {{ New-PSDrive -Name "{0}" -PSProvider "{1}" -Root "{2}" }};' -f $drive.Name, $drive.Provider.Name, $drive.Root
            $commandString += 'Set-Location -Path "{0}:\{1}";' -f $drive.Name, $drive.CurrentLocation
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

            Pop-Location

            Remove-Item -Path $scriptBlockFile   -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $argumentListFile  -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $commandOutputFile -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $commandErrorFile  -Force -ErrorAction SilentlyContinue
        }
    }
}
