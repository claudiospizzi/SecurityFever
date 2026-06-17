
BeforeAll {

    $modulePath = Resolve-Path -Path "$PSScriptRoot\..\..\..\.." | Select-Object -ExpandProperty Path
    $moduleName = Resolve-Path -Path "$PSScriptRoot\..\..\.." | Get-Item | Select-Object -ExpandProperty BaseName

    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$modulePath\$moduleName" -Force
}

Describe 'Get-TimeBasedOneTimePassword' {

    $sharedSecret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ'
    $length       = 6
    $interval     = 30
    $timestamp    = [DateTime] '1970-01-01 00:00:00'

    $testCases = @(
        @{
            SharedSecret = $sharedSecret
            Length       = $length
            Interval     = $interval
            Timestamp    = $timestamp
            Round        = 0
            ExpectedTotp = '755224'
        }
        @{
            SharedSecret = $sharedSecret
            Length       = $length
            Interval     = $interval
            Timestamp    = $timestamp
            Round        = 1
            ExpectedTotp = '287082'
        }
        @{
            SharedSecret = $sharedSecret
            Length       = $length
            Interval     = $interval
            Timestamp    = $timestamp
            Round        = 2
            ExpectedTotp = '359152'
        }
        @{
            SharedSecret = $sharedSecret
            Length       = $length
            Interval     = $interval
            Timestamp    = $timestamp
            Round        = 3
            ExpectedTotp = '969429'
        }
        @{
            SharedSecret = $sharedSecret
            Length       = $length
            Interval     = $interval
            Timestamp    = $timestamp
            Round        = 4
            ExpectedTotp = '338314'
        }
        @{
            SharedSecret = $sharedSecret
            Length       = $length
            Interval     = $interval
            Timestamp    = $timestamp
            Round        = 5
            ExpectedTotp = '254676'
        }
        @{
            SharedSecret = $sharedSecret
            Length       = $length
            Interval     = $interval
            Timestamp    = $timestamp
            Round        = 6
            ExpectedTotp = '287922'
        }
        @{
            SharedSecret = $sharedSecret
            Length       = $length
            Interval     = $interval
            Timestamp    = $timestamp
            Round        = 7
            ExpectedTotp = '162583'
        }
        @{
            SharedSecret = $sharedSecret
            Length       = $length
            Interval     = $interval
            Timestamp    = $timestamp
            Round        = 8
            ExpectedTotp = '399871'
        }
        @{
            SharedSecret = $sharedSecret
            Length       = $length
            Interval     = $interval
            Timestamp    = $timestamp
            Round        = 9
            ExpectedTotp = '520489'
        }
    )

    Context 'Verify RFC 4648' {

        It 'Should return a valid TOTP for round <Round>' -TestCases $testCases {

            param ($SharedSecret, $Length, $Interval, $Timestamp, $Round, $ExpectedTotp)

            # Act
            $actual = Get-TimeBasedOneTimePassword -SharedSecret $SharedSecret -Timestamp $Timestamp.AddSeconds($Round * $Interval) -Length $Length -Interval $Interval

            # Assert
            $actual | Should -Be $ExpectedTotp
        }
    }
}
