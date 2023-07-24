
$modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
$moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
Import-Module -Name "$modulePath\$moduleName" -Force

Describe 'Get-TimeBasedOneTimePassword' {

    $sharedSecret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ'
    $length       = 6
    $interval     = 30
    $timestamp    = [DateTime] '1970-01-01 00:00:00'

    $testData = @(
        '755224' # Round 0
        '287082' # Round 1
        '359152' # Round 2
        '969429' # Round 3
        '338314' # Round 4
        '254676' # Round 5
        '287922' # Round 6
        '162583' # Round 7
        '399871' # Round 8
        '520489' # Round 9
    )

    Context 'Verify RFC 4648' {

        for ($round = 0; $round -lt $testData.Count; $round++)
        {
            It "should return a valid TOTP ($round)" {

                # Arrange
                $expectedTotp = $testData[$round]

                # Act
                $actualTotp = Get-TimeBasedOneTimePassword -SharedSecret $sharedSecret -Timestamp $timestamp.AddSeconds($round * $interval) -Length $length -Interval $interval

                # Assert
                $actualTotp | Should -Be $expectedTotp
            }
        }
    }
}
