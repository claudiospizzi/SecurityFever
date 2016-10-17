<#
    .SYNOPSIS
    Test the provided credentials with the choosen test method.

    .DESCRIPTION
    Test the provided credentials against the local system by starting a simple
    process or against Active Directory by binding to the root via ADSI.

    .INPUTS
    None.

    .OUTPUTS
    System.Boolean. Indicates if the credentials are valid or not.

    .EXAMPLE
    PS C:\> Test-Credential -Credential 'DOMAIN\user'
    Test the interactive provided credentials against the local system.

    .EXAMPLE
    PS C:\> Test-Credential -Credential 'DOMAIN\user' -Throw
    Test the interactive provided credentials against the local system, and
    throws an exception if the credentials are not valid.

    .EXAMPLE
    PS C:\> Test-Credential -Username $Username -Password $Password -Method ActiveDirectory
    Test the provided username and password pair against the Active Directory.

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

        # Throw an terminating exception if the credentials are not valid.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]
        $Throw
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
        try
        {
            if ($Method -eq 'StartProcess')
            {
                # Create a new local process with the given credentials. This
                # does not validate the credentials against an external target
                # system, but tests if they are valid locally. Of courese, it's
                # possible to validate domain credentials too.
                $startInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo
                $startInfo.FileName        = 'cmd.exe'
                $startInfo.Arguments       = '/C', 'echo %USERDOMAIN%\%USERNAME%'
                $startInfo.Domain          = $Credential.GetNetworkCredential().Domain
                $startInfo.UserName        = $Credential.GetNetworkCredential().UserName
                $startInfo.Password        = $Credential.GetNetworkCredential().SecurePassword
                $startInfo.WindowStyle     = [System.Diagnostics.ProcessWindowStyle]::Hidden
                $startInfo.CreateNoWindow  = $true
                $startInfo.UseShellExecute = $false

                $process = New-Object -TypeName  System.Diagnostics.Process
                $process.StartInfo = $startInfo
                $process.Start() | Out-Null
            }

            if ($Method -eq 'ActiveDirectory')
            {
                # We use an empty path, because we just test the credential
                # binding and not any object access in Active Directory.
                $directoryEntryArgs = @{
                     TypeName     = 'System.DirectoryServices.DirectoryEntry'
                     ArgumentList = '',
                                    $Credential.GetNetworkCredential().UserName,
                                    $Credential.GetNetworkCredential().Password
                }
                $directoryEntry = New-Object @directoryEntryArgs

                if ($null -eq $directoryEntry)
                {
                    throw 'Unable to create an ADSI connection.'
                }
            }

            if (-not $Throw.IsPresent)
            {
                return $true
            }
        }
        catch
        {
            Write-Warning -Message "Credential validation failed: $_"

            if ($Throw.IsPresent)
            {
                throw "Credential validation failed: $_"
            }
            else
            {
                return $false
            }
        }
    }
}
