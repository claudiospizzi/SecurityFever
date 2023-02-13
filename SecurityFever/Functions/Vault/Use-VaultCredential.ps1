<#
    .SYNOPSIS
        Get the PSCredential object from the Windows Credential Manager vault or
        query the caller to enter the credentials. These credentials will be
        stored in the vault.

    .DESCRIPTION
        This cmdlet will load the target PSCredential object from the Windows
        Credential Manager vault by using Get-VaultCredential. If the vault
        entry does not exist,  and the current PowerShell session is in
        interactive mode, it will query the credential from the interactive
        user by using Get-Credential. If this was successful, the credential
        will be stored in the Windows Credential Manager vault by using the
        New-VaultEntry command and then returned to the pipeline. Else an
        exception will be thrown. If the process is in non interactive mode and
        the entry does not exist, nothing is returned.

    .INPUTS
        None.

    .OUTPUTS
        System.Management.Automation.PSCredential.

    .EXAMPLE
        PS C:\> Use-VaultCredential -TargetName 'MyUserCred' -Credential 'MyUsername'
        Return the PSCredential objects with the target name 'MyUserCred' from
        the vault or if it does not exist, query the user.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Use-VaultCredential
{
    [CmdletBinding()]
    [Alias('cred')]
    [OutputType([System.Management.Automation.PSCredential])]
    param
    (
        # The vault credential entry name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $TargetName,

        # The username to search in the vault or query the credential.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Username
    )

    # Only run Read-Host if the PowerShell process is in interactive mode. If
    # this is not the case, just return $null indicating
    $isInteractive = [Environment]::UserInteractive -and [Environment]::GetCommandLineArgs().Where({ $_ -like '-NonI*' }).Count -eq 0

    # Get all entries matching the parameters.
    $entries = @(Get-VaultEntry @PSBoundParameters)

    if ($entries.Count -eq 1)
    {
        # Exactly one entry found, return it
        Write-Output $entries[0].Credential
    }
    elseif ($entries.Count -gt 1)
    {
        # Multiple entries found, throw an exception
        throw 'Multiple entries found in the Credential Manager vault matching the parameters.'
    }
    elseif ($isInteractive)
    {
        # Get the credentials from the user
        if ($PSBoundParameters.ContainsKey('Username'))
        {
            $credential = Get-Credential -Message $TargetName -UserName $Username
        }
        else
        {
            $credential = Get-Credential -Message $TargetName
        }

        # If no credentials were specified, throw an exception
        if ($null -eq $credential)
        {
            throw 'No entry found in the Credential Manager and no credentials entered.'
        }

        # Add the credentials to the Credential Manager vault
        New-VaultEntry -TargetName $TargetName -Credential $credential | Out-Null

        Write-Output $credential
    }
}
