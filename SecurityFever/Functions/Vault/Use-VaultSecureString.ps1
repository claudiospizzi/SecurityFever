<#
    .SYNOPSIS
        Get the SecureString object from the Windows Credential Manager vault or
        query the caller to enter the string. These string will be stored in the
        vault.

    .DESCRIPTION
        This cmdlet will load the target SecureString object from the Windows
        Credential Manager vault by using Get-VaultSecureString. If the vault
        entry does not exist, and the current PowerShell session is in
        interactive mode, it will query the string from the interactive user by
        using Read-Host -AsSecureString. If this was successful, the string
        will be stored in the Windows Credential Manager vault by using the
        New-VaultEntry command and then returned to the pipeline. Else an
        exception will be thrown. If the process is in non interactive mode and
        the entry does not exist, nothing is returned.

    .INPUTS
        None.

    .OUTPUTS
        System.Security.SecureString.

    .EXAMPLE
        PS C:\> Use-VaultSecureString -TargetName 'MySecString'
        Return the SecureString objects with the target name 'MySecString' from
        the vault or if it does not exist, query the user.

    .LINK
        https://github.com/claudiospizzi/SecurityFever
#>
function Use-VaultSecureString
{
    [CmdletBinding()]
    [OutputType([System.Security.SecureString])]
    param
    (
        # The vault secure string entry name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $TargetName
    )

    # Only run Read-Host if the PowerShell process is in interactive mode. If
    # this is not the case, just return $null indicating
    $isInteractive = [Environment]::UserInteractive -and [Environment]::GetCommandLineArgs().Where({ $_ -like '-NonI*' }).Count -eq 0

    # Get all entries matching the parameters.
    $entries = @(Get-VaultEntry @PSBoundParameters)

    if ($entries.Count -eq 1)
    {
        # Exactly one entry found, return it
        Write-Output $entries[0].Password
    }
    elseif ($entries.Count -gt 1)
    {
        # Multiple entries found, throw an exception
        throw 'Multiple entries found in the Credential Manager vault matching the parameters.'
    }
    elseif ($isInteractive)
    {
        # Get the secure string from the user
        $secureString = Read-Host -Prompt $TargetName -AsSecureString

        # If no secure string was specified, throw an exception
        if ($null -eq $secureString)
        {
            throw 'No entry found in the Credential Manager and no secure string was entered.'
        }

        # Add the secure string to the Credential Manager vault
        New-VaultEntry -TargetName $TargetName -Username ' ' -Password $secureString | Out-Null

        Write-Output $secureString
    }
}
