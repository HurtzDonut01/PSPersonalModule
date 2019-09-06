<#
.Synopsis
    This will iterate through all your domain controllers by default and checks for event 4740 in event viewer. To use this, you must dot source the file and call the function.
    For updated help and examples refer to -Online version.
    
    
.DESCRIPTION
    This will go through all domain controllers by default and check to see if there are event ID for lockouts and display the information in table with Username, Time, Computername and CallerComputer.
    For updated help and examples refer to -Online version.
    
    
.NOTES  
    Name: Get-AccountLockoutStatus
    Author: The Sysadmin Channel
    Version: 1.01
    DateCreated: 2017-Apr-09
    DateUpdated: 2017-Apr-09
    
.LINK
    https://thesysadminchannel.com/get-account-lock-out-source-powershell -
    
    
.PARAMETER ComputerName
    By default all domain controllers are checked. If a computername is specified, it will check only that.
    
    .PARAMETER Username
    If a username is specified, it will only output events for that username.
    
    .PARAMETER DaysFromToday
    This will set the number of days to check in the event logs.  Default is 3 days.
    
    .EXAMPLE
    Get-AccountLockoutStatus
    
    Description:
    Will generate a list of lockout events on all domain controllers.
    
    .EXAMPLE
    Get-AccountLockoutStatus -ComputerName DC01, DC02
    
    Description:
    Will generate a list of lockout events on DC01 and DC02.
    
    .EXAMPLE
    Get-AccountLockoutStatus -Username Username
    
    Description:
    Will generate a list of lockout events on all domain controllers and filter that specific user.
    
    .EXAMPLE
    Get-AccountLockoutStatus -DaysFromToday 2
    
    Description:
    Will generate a list of lockout events on all domain controllers going back only 2 days.
    
#> 

Function Get-AccountLockoutStatus {
    #Requires -Modules ActiveDirectory    
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
            [String[]]$DomainController = (Get-ADDomainController -Filter *).Name,
    
        [Parameter()]
        [ValidateNotNullOrEmpty()]
            [String]$Username,
    
        [Parameter()]
        [ValidateNotNullOrEmpty()]
            [Int]$DaysFromToday = 3    
    )
    
    Process {
        Foreach ($Computer in $DomainController) {
            Write-Verbose ('DC : {0}' -F $Computer)
            Try {
                $WinEventSplat = @{
                    ComputerName    = $Computer
                    FilterHashtable = @{LogName='Security';ID=4740;StartTime=(Get-Date).AddDays(-$DaysFromToday)}
                    ErrorAction     = 'Stop'
                }
                $Event = Get-WinEvent @WinEventSplat | ForEach-Object {
                    [PSCustomObject][Ordered]@{
                        ComputerName    = $Computer
                        Time            = $PSItem.TimeCreated
                        UserName        = $PSItem.Properties.Value[0]
                        CallerComputer  = $PSItem.Properties.Value[1]
                    }
                }

                If ($UserName) {
                    $Event | Where-Object UserName -eq $Username
                }
            } Catch {
                Write-Error $PSItem.Exception.Message
            }
        }
    }    
} # Function Get-AccountLockoutStatus