
function Convert-EventLogObjectId4625
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        $Record,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Map
    )

    # Definition: Types
    $typeMap = @{
        '2'  = 'Interactive'
        '3'  = 'Network'
        '4'  = 'Batch'
        '5'  = 'Service'
        '7'  = 'Unlock'
        '8'  = 'NetworkCleartext'
        '9'  = 'NewCredentials'
        '10' = 'RemoteInteractive'
        '11' = 'CachedInteractive'
    }

    # Definition: Reasons
    $reasonMap = @{
        0xC0000064 = 'Username does not exist'
        0xC000006A = 'Username is correct but the password is wrong'
        0xC0000234 = 'User is currently locked out'
        0xC0000072 = 'Account is currently disabled'
        0xC000006F = 'User tried to logon outside his day of week or time of day restrictions'
        0xC0000070 = 'Workstation restriction, or authentication policy silo violation'
        0xC0000193 = 'Account expiration'
        0xC0000071 = 'Expired password'
        0xC0000133 = 'Clocks between DC and other computer too far out of sync'
        0xC0000224 = 'User is required to change password at next logon'
        0xC0000225 = 'Evidently a bug in Windows and not a risk'
        0xc000015b = 'The user has not been granted the requested logon type (aka logon right) at this machine'
    }

    $activity = Convert-EventLogObject -Record $Record -Map $Map

    # Grab record properties
    $recordType     = $Record.Properties[10].Value.ToString().Trim()
    $recordUser     = $Record.Properties[6].Value + '\' + $Record.Properties[5].Value
    $recordComputer = $Record.Properties[13].Value
    $recordReason   = $Record.Properties[7].Value
    $recordReason2  = $Record.Properties[9].Value
    $recordProcess  = $Record.Properties[11].Value.Trim()
    $recordAuth     = $Record.Properties[12].Value.ToString().Trim()
    $recordAuth2    = $Record.Properties[15].Value.ToString().Trim()

    # Set default values
    $activity.Type         = "Unknown ($recordType)"
    $activity.Reason       = "$recordReason ($recordReason2)"
    $activity.Username     = $recordUser
    $activity.Computer     = $recordComputer
    $activity.Process      = $recordProcess
    $activity.Comment      = "$recordAuth ($recordAuth2)"

    # Populate the type
    if ($typeMap.ContainsKey($recordType))
    {
        $activity.Type = $typeMap[$recordType]
    }

    # Cleanup comment
    $activity.Comment = $activity.Comment.Replace(' (-)', '')

    # Populate reason
    if ($reasonMap.ContainsKey($recordReason))
    {
        $recordReason = $reasonMap[$recordReason]
    }
    if ($reasonMap.ContainsKey($recordReason2))
    {
        $recordReason2 = $reasonMap[$recordReason2]
    }
    $activity.Reason = "$recordReason ($recordReason2)"

    Write-Output $activity



<#

    try
    {
        $reason1 = $reasonMap[$reason1]
    }
    catch { }

    try
    {
        $reason2 = $reasonMap[$reason2]
    }
    catch { }

    $reason = @()
    if (-not [String]::IsNullOrEmpty($reason1) -and $reason1 -ne '-')
    {
        $reason += $reason1
    }
    if (-not [String]::IsNullOrEmpty($reason2) -and $reason2 -ne '-')
    {
        $reason += $reason2
    }
#4625 = @{ Type   = 'Logon'; Log    = 'Security'; Event  = 'Logon Failed' }# An account failed to log on.

    $activity.Detail = $activity.Detail -f $type, $user, $computer, ($reason -join ' / '), $process, $auth
#>
}
