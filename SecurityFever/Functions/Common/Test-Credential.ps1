<#
    .SYNOPSIS
        Test the provided credentials with the choosen test method against the
        local system or Active Directory.

    .DESCRIPTION
        Test the provided credentials against the local system by starting a
        simple process or against Active Directory by binding to the root via
        ADSI.

    .INPUTS
        System.Management.Automation.PSCredential

    .OUTPUTS
        System.Management.Automation.PSCredential
        System.Boolean

    .EXAMPLE
        PS C:\> Test-Credential -Credential 'DOMAIN\user'
        Test the interactive provided credentials against the local system. If
        the credential are not valid, an exception is thrown.

    .EXAMPLE
        PS C:\> Test-Credential -Credential 'DOMAIN\user' -Quiet
        Test the interactive provided credentials against the local system and
        return $true if the credentials are valid, else return $false.

    .EXAMPLE
        PS C:\> Test-Credential -Username $Username -Password $Password -Method ActiveDirectory
        Test the provided username and password pair against the Active
        Directory.

    .EXAMPLE
        PS C:\> $cred = Get-Credential 'DOMAIN\user' | Test-Credential
        Request the user to enter the password for DOMAIN\user and test it
        immediately with Test-Credential against the local system. If the
        credentials are valid, they are returned and stored in $cred. If not, an
        terminating exception is thrown.

    .NOTES
        Author     : Claudio Spizzi
        License    : MIT License

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Test-Credential
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    [OutputType([System.Management.Automation.PSCredential])]
    param
    (
        # PowerShell credentials object to test.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ParameterSetName = 'Credential')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        # The username to validate. Specify password too.
        [Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
        [System.String]
        $Username,

        # The password to validate. Specify username too.
        [Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
        [System.Security.SecureString]
        $Password,

        # Validation method.
        [Parameter(Mandatory = $false)]
        [ValidateSet('StartProcess', 'ActiveDirectory')]
        [System.String]
        $Method = 'StartProcess',

        # Return a boolean value which indicates if the credentials are valid.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]
        $Quiet
    )

    begin
    {
        if ($PSCmdlet.ParameterSetName -eq 'UsernamePassword')
        {
            $Credential = New-Object -TypeName PSCredential -ArgumentList $Username, $Password
        }
    }

    process
    {
        $exception = $null

        if ($Method -eq 'StartProcess')
        {
            Write-Verbose "Test credentials $($Credential.UserName) by starting a local cmd.exe process"

            try
            {
                # Create a new local process with the given credentials. This
                # does not validate the credentials against an external target
                # system, but tests if they are valid locally. Of courese, it's
                # possible to validate domain credentials too.
                $startInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo
                $startInfo.FileName         = 'cmd.exe'
                $startInfo.WorkingDirectory = $env:SystemRoot
                $startInfo.Arguments        = '/C', 'echo %USERDOMAIN%\%USERNAME%'
                $startInfo.Domain           = $Credential.GetNetworkCredential().Domain
                $startInfo.UserName         = $Credential.GetNetworkCredential().UserName
                $startInfo.Password         = $Credential.GetNetworkCredential().SecurePassword
                $startInfo.WindowStyle      = [System.Diagnostics.ProcessWindowStyle]::Hidden
                $startInfo.CreateNoWindow   = $true
                $startInfo.UseShellExecute  = $false

                $process = New-Object -TypeName  System.Diagnostics.Process
                $process.StartInfo = $startInfo
                $process.Start() | Out-Null

                # If the process start does not throw an exception, the
                # credentials are valid.
            }
            catch
            {
                # Hide the $process.Start() method call exception, by expanding
                # the inner exception.
                if ($_.Exception.Message -like 'Exception calling "Start" with "0" argument(s):*')
                {
                    $exception = $_.Exception.InnerException
                }
                else
                {
                    $exception = $_.Exception
                }
            }
        }

        if ($Method -eq 'ActiveDirectory')
        {
            Write-Verbose "Test credentials $($Credential.UserName) by binding the default domain with ADSI"

            try
            {
                # We use an empty path, because we just test the credential
                # binding and not any object access in Active Directory.
                $directoryEntryArgs = @{
                        TypeName     = 'System.DirectoryServices.DirectoryEntry'
                        ArgumentList = '', # Bind to the local default domain
                                       $Credential.GetNetworkCredential().UserName,
                                       $Credential.GetNetworkCredential().Password
                }
                $directoryEntry = New-Object @directoryEntryArgs -ErrorAction Stop

                if ($null -eq $directoryEntry -or [String]::IsNullOrEmpty($directoryEntry.distinguishedName))
                {
                    throw 'Unable to create an ADSI connection.'
                }
            }
            catch
            {
                $exception = $_.Exception
            }
        }

        # Check the exception variable if an exception occured and return a
        # boolean or the credentials. In case of an exception, throw a custom
        # exception.
        if ($Quiet.IsPresent)
        {
            Write-Output ($null -eq $exception)
        }
        else
        {
            if ($null -eq $exception)
            {
                Write-Output $Credential
            }
            else
            {
                $errorRecordArgs = $exception, '0', [System.Management.Automation.ErrorCategory]::AuthenticationError, $Credential
                $errorRecord     = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList $errorRecordArgs

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }
    }
}
