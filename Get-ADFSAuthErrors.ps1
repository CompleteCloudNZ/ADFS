PARAM ($PastDays = 1, $PastHours) 
#************************************************ 
# ADFSBadUserCredSearch.ps1 
# Version 1.0 
# Date: 6-20-2016 
# Author: Tim Springston [MSFT] 
# Description: This script will parse the ADFS server's (not proxy) Admin events 
#  for events which indicate an incorrectly entered username or password. The script can specify a 
#  past period to search the log for and it defaults to the past 24 hours. The time and message of the event  
#  will be placed into a text file and displayed at the console. 
#************************************************ 
 
cls 
if ($PastHours -gt 0) 
    {$PastPeriod = (Get-Date).AddHours(-($PastHours))} 
    else 
        {$PastPeriod = (Get-Date).AddDays(-($PastDays))    } 
     
$CS = get-wmiobject -class win32_computersystem 
$Hostname = $CS.Name + '.' + $CS.Domain 
$Instances = @{} 
$OSVersion = gwmi win32_operatingsystem 
if ($OSVersion.Buildnumber -lt 9200){$LogName = "AD FS 2.0/Admin"} 
    else {$LogName = "AD FS/Admin"} 
 
$events = @()
 
$events = Get-Winevent -FilterHashTable @{LogName= $LogName; StartTime=$PastPeriod; ID=342} -ErrorAction SilentlyContinue | Where-Object  {$_.Message -match "The user name or password is incorrect"} 
$events +=Get-Winevent -FilterHashTable @{LogName= $LogName; StartTime=$PastPeriod; ID=111} -ErrorAction SilentlyContinue | Where-Object  {$_.Message -match "unknown user name or bad password"} 

$customevents = @()

foreach($event in $events)
{
    $lines = $event.Message -split "[\r\n]"
    $line = $lines -match "-The user name or password is incorrect"
    $Object = New-Object PSObject -Property @{            
        Time       = $event.TimeCreated               
        user       = ($line.split("-"))[0]
        error      = ($line.split("-"))[1]    
    }               
    $customevents += $Object
    $Object
}

$customevents |Export-Csv .\badusers.csv -NoTypeInformation 