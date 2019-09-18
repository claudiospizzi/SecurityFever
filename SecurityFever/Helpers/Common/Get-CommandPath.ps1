
function Get-CommandPath
{
    [CmdletBinding()]
    param
    (
        # Name of the command.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        # Warning message to display if the command was not found.
        [Parameter(Mandatory = $false)]
        [System.String]
        $WarningMessage
    )

    try
    {
        Get-Command -Name $Name -CommandType 'Application' -ErrorAction 'Stop' |
            Select-Object -ExpandProperty 'Path'
    }
    catch
    {
        if ($PSBoundParameters.ContainsKey('WarningMessage'))
        {
            Write-Warning $WarningMessage
        }

        throw "The command $Name was not found!"
    }
}