function ConvertTo-ScheduledTaskTrigger {
    <#
    .SYNOPSIS
        Converts interval specification to ScheduledTaskTrigger.

    .DESCRIPTION
        Creates a New-ScheduledTaskTrigger object based on interval type and time.

    .PARAMETER Interval
        Interval type: Once, Daily, Weekly, Hourly

    .PARAMETER At
        Time of day for Daily/Weekly intervals (e.g., "3:00 AM")

    .PARAMETER DaysInterval
        Number of days between Daily triggers (default: 1)

    .PARAMETER WeeksInterval
        Number of weeks between Weekly triggers (default: 1)

    .PARAMETER DaysOfWeek
        Days of week for Weekly triggers

    .PARAMETER RepetitionInterval
        TimeSpan for repeating triggers (e.g., for Hourly)

    .OUTPUTS
        CimInstance representing trigger
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Once', 'Daily', 'Weekly', 'Hourly', 'AtStartup', 'AtLogon')]
        [string]$Interval,

        [Parameter()]
        [datetime]$At = (Get-Date "3:00 AM"),

        [Parameter()]
        [int]$DaysInterval = 1,

        [Parameter()]
        [int]$WeeksInterval = 1,

        [Parameter()]
        [ValidateSet('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')]
        [string[]]$DaysOfWeek = @('Sunday'),

        [Parameter()]
        [timespan]$RepetitionInterval
    )

    $triggerParams = @{}

    switch ($Interval) {
        'Once' {
            $triggerParams['Once'] = $true
            $triggerParams['At'] = $At
        }
        'Daily' {
            $triggerParams['Daily'] = $true
            $triggerParams['At'] = $At
            $triggerParams['DaysInterval'] = $DaysInterval
        }
        'Weekly' {
            $triggerParams['Weekly'] = $true
            $triggerParams['At'] = $At
            $triggerParams['WeeksInterval'] = $WeeksInterval
            $triggerParams['DaysOfWeek'] = $DaysOfWeek
        }
        'Hourly' {
            $triggerParams['Once'] = $true
            $triggerParams['At'] = $At
            $triggerParams['RepetitionInterval'] = if ($RepetitionInterval) { $RepetitionInterval } else { New-TimeSpan -Hours 1 }
        }
        'AtStartup' {
            $triggerParams['AtStartup'] = $true
        }
        'AtLogon' {
            $triggerParams['AtLogon'] = $true
        }
    }

    return New-ScheduledTaskTrigger @triggerParams
}
