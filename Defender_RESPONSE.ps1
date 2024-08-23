<#
.NOTES
Defender_RESPONSE.ps1
doug.metz@magnetforensics.com
v1.1

.SYNOPSIS
This script can be used to leverage Magnet RESPONSE and the Microsoft Defender for Endpoint Live Response console to capture triage collections on remote endpoints.

Prerequisites:
- Defender Live Response Console - upload MagnetRESPONSE.exe to the Library
- Defender Live Response Console - upload Defender_RESPONSE.ps1 to the Library (to use Profiles enable "Script parametes")

Collection Profiles:
Included some of the profiles defined in MagnetResponsePowerShell script. It enables user to choose what information to collect without modifying the script.
To choose the profile, run script with "-Profile" parameter and profile name value.
If profile parameter is not provided during execution, default traige (ram, volatile, system files, extended process info) information will be collected.

Available profiles names:
- ram: only RAM
- volatile: RAM, Volatile
- triage: RAM, Volatile, system Files, Extended process info
- full: RAM, Page file, System files, Extended process info, Proc files


Operation:
1. 'connect' to endpoint in Live Response // establish connection with the endpoint
2. 'put MagnetRESPONSE.exe' // copies the exe to the target system
3. 'run Defender_RESPONSE.ps1' // where the magic happens

Alternative to 3. Choose profile.
3.alt. 'run Defender_RESPONSE.ps1 -parameters "-Profile <profile_name>"'

Retrieving the Data:

    Once the script has finished running, the zipped output will be saved at the location “C:\Temp\RESPONSE” on the remote machine.

    * 	Navigate to output folder using command — cd c:\Temp\RESPONSE
    * 	List files using “dir” command
    * 	Copy the zip filename <
filename.zip
>
    *   After the output filename is copied, collect the output by downloading it from the remote machine to your local system using the “Download” command. Download <
filename.zip
> &

#>
param (
    [string]$Profile="triage"
)

Write-Host ""
Write-Host  "Magnet RESPONSE v1.7
$([char]0x00A9)2021-2023 Magnet Forensics, LLC
"

switch($Profile){
    "ram" {
        $profile_info = ": RAM";
        $arguments = "/captureram"
    }
    "volatile" {
        $profile_info = ": RAM, Volatile"; 
        $arguments = "/captureram /capturevolatile"
    }
    "triage" {
        $profile_info = ": RAM, Volatile, System Files, Extended process info";
        $arguments = "/captureram /capturevolatile /capturesystemfiles /captureextendedprocessinfo"
    }
    "full" {
        $profile_info = ": Full collection";
        $arguments = "/captureram /capturepagefile /capturevolatile /capturesystemfiles /captureextendedprocessinfo /saveprocfiles"
    }
    Default {
        "Unkown profile. Available profile names: ram, volatile, systemfiles, triage, full.";
        Exit
    }
}

$OS = $(((gcim Win32_OperatingSystem -ComputerName $server.Name).Name).split('|')[0])
$arch = (get-wmiobject win32_operatingsystem).osarchitecture
$name = (get-wmiobject win32_operatingsystem).csname
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-host  "
Hostname: $name
Operating System: $OS
Architecture: $arch
"

./MagnetRESPONSE.exe /accepteula /unattended /output:C:\temp\RESPONSE /caseref:DefenderRESPONSE $arguments
# To include RAM capture, comment out (#) the above line and un-comment the line below
# When enabled it will ignore profile parameters
# ./MagnetRESPONSE.exe /accepteula /unattended /output:C:\temp\RESPONSE /caseref:DefenderRESPONSE /capturevolatile /capturesystemfiles /captureram
Write-Host  "[Collecting Arifacts$profile_info]"
Wait-Process -name "MagnetRESPONSE"
$null = $stopwatch.Elapsed
$Minutes = $StopWatch.Elapsed.Minutes
$Seconds = $StopWatch.Elapsed.Seconds
Write-Host  "** Acquisition Completed in $Minutes minutes and $Seconds seconds.**"
