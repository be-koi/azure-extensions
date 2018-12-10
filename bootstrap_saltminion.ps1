param([string]$MasterHost)


Install-PackageProvider -name Nuget -MinimumVersion 2.8.5.201 -force
Install-Module PSWindowsUpdate -Scope AllUsers -Force
Get-WindowsUpdate -AcceptAll -Confirm -Download -Install -IsInstalled -MicrosoftUpdate -Severity Unspecified -UpdateType Software -WindowsUpdate -Silent
Install-WindowsUpdate -AcceptAll -Install -IgnoreReboot -WindowsUpdate



$SourceURI = 'https://repo.saltstack.com/windows/Salt-Minion-2017.7.2-Py2-AMD64-Setup.exe'

Write-Verbose 'Installing Salt... please wait'
$InstallerFile = 'C:\Packages\Salt.exe'

Write-Verbose "Downloading salt installer from $SourceURI to $InstallerFile"
$WebClient = New-Object System.Net.WebClient
$webclient.DownloadFile($SourceURI, $InstallerFile)
Write-Verbose 'Salt installer downloaded.'

Write-Verbose 'Installing Salt'

$minionId = $env:COMPUTERNAME.ToLower()

Start-Process $InstallerFile -Wait `
                             -NoNewWindow `
                             -PassThru `
                             -ArgumentList "/S /master=$MasterHost /minion-name=$minionId"
Write-Verbose "Salt is installed"

Start-Process salt-call -Wait -NoNewWindow -Passthru -ArgumentList "state.highstate"
Start-Process salt-call -Wait -NoNewWindow -Passthru -ArgumentList "pkg.refresh_db"
Start-Process salt-call -Wait -NoNewWindow -Passthru -ArgumentList "state.highstate"
Start-Process gpupdate -Wait -NoNewWindow -Passthru -ArgumentList "/force"
Start-Process ipconfig -Wait -NoNewWindow -Passthru -ArgumentList "/registerdns"
Start-Process salt-call -Wait -NoNewWindow -Passthru -ArgumentList "state.highstate"

