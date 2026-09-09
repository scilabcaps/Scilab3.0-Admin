$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $root 'build\windows\x64\runner\Debug'
$staging = Join-Path $root 'packaging\staging\ScilabReserve'
$output = Join-Path $root 'dist\ScilabReserve-Setup.exe'
$logo = Join-Path $root 'assets\images\Scilab_Logo.png'

if (-not (Test-Path (Join-Path $runner 'admin_scalib.exe'))) {
  throw "Compiled Windows application not found: $runner"
}

New-Item -ItemType Directory -Force -Path $staging, (Split-Path $output) | Out-Null
if (Test-Path $staging) { Get-ChildItem -LiteralPath $staging -Force | Remove-Item -Recurse -Force }
Copy-Item -LiteralPath (Join-Path $runner '*') -Destination $staging -Recurse -Force
Copy-Item -LiteralPath $logo -Destination (Join-Path $staging 'Scilab_Logo.png') -Force

$installScript = Join-Path $staging 'install.ps1'
$installScriptContent = @'
$ErrorActionPreference = 'Stop'
$target = Join-Path ${env:ProgramFiles} 'ScilabReserve'
New-Item -ItemType Directory -Force -Path $target | Out-Null
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
Copy-Item -LiteralPath (Join-Path $source '*') -Destination $target -Recurse -Force -Exclude 'install.ps1','uninstall.ps1'
$shortcut = Join-Path ([Environment]::GetFolderPath('CommonDesktopDirectory')) 'ScilabReserve.lnk'
$shell = New-Object -ComObject WScript.Shell
$link = $shell.CreateShortcut($shortcut)
$link.TargetPath = Join-Path $target 'admin_scalib.exe'
$link.WorkingDirectory = $target
$link.Description = 'ScilabReserve Lab Management'
$link.Save()
Start-Process (Join-Path $target 'admin_scalib.exe')
'@'
Set-Content -LiteralPath $installScript -Value $installScriptContent -Encoding UTF8

$uninstallScript = Join-Path $staging 'uninstall.ps1'
Set-Content -LiteralPath $uninstallScript -Value @'
$target = Join-Path ${env:ProgramFiles} 'ScilabReserve'
$shortcut = Join-Path ([Environment]::GetFolderPath('CommonDesktopDirectory')) 'ScilabReserve.lnk'
Remove-Item -LiteralPath $shortcut -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
'@ -Encoding UTF8

$directive = Join-Path $root 'packaging\iexpress-directive.txt'
$payload = Get-ChildItem -LiteralPath $staging -File | Where-Object Name -notin @('install.ps1','uninstall.ps1') | ForEach-Object { '"' + $_.FullName + '"' }
$directiveContent = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=1
CAB_Fixed_Size=0
CAB_Resv_CodeSigning=0
RebootMode=N
InstallPrompt=This will install ScilabReserve Lab Management.
DisplayLicense=
FinishMessage=ScilabReserve has been installed.
TargetName=$output
FriendlyName=ScilabReserve Setup
AppLaunched=powershell.exe -NoProfile -ExecutionPolicy Bypass -File install.ps1
PostInstallCmd=<None>
SourceFiles=SourceFiles
[SourceFiles]
SourceFiles0=$staging
[SourceFiles0]
$($payload -join "`r`n")
"@
Set-Content -LiteralPath $directive -Value $directiveContent -Encoding ASCII

& iexpress.exe /N $directive
if (-not (Test-Path $output)) { throw "IExpress did not produce $output" }
Write-Output "Created $output"
