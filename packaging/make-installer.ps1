$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$staging = Join-Path $root 'packaging\staging\ScilabReserve'
$runner = Join-Path $root 'build\windows\x64\runner\Release'
$useExistingStaging = -not (Test-Path (Join-Path $runner 'admin_scalib.exe')) -and (Test-Path (Join-Path $staging 'admin_scalib.exe'))
$output = Join-Path $root 'dist\ScilabReserve-Setup.exe'
$logo = Join-Path $root 'assets\images\Scilab_Logo.png'
if (-not (Test-Path (Join-Path $runner 'admin_scalib.exe')) -and -not $useExistingStaging) { throw "Compiled Windows application not found: $runner" }
New-Item -ItemType Directory -Force -Path $staging, (Split-Path $output) | Out-Null
if (-not $useExistingStaging) {
  Get-ChildItem -LiteralPath $staging -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
  Copy-Item -Path (Join-Path $runner '*') -Destination $staging -Recurse -Force
  Copy-Item -LiteralPath $logo -Destination (Join-Path $staging 'Scilab_Logo.png') -Force
}
$install = Join-Path $staging 'install.cmd'
Set-Content -LiteralPath $install -Encoding ASCII -Value @('@echo off','set "TARGET=%ProgramFiles%\ScilabReserve"','if not exist "%TARGET%" mkdir "%TARGET%"','xcopy /E /I /Y "%~dp0*" "%TARGET%" >nul','start "" "%TARGET%\admin_scalib.exe"')
$directive = Join-Path $root 'packaging\iexpress-directive.txt'
$payload = Get-ChildItem -LiteralPath $staging -File -Recurse | ForEach-Object { $_.FullName.Substring($staging.Length + 1) }
$content = "[Version]`r`nClass=IEXPRESS`r`nSEDVersion=3`r`n[Options]`r`nPackagePurpose=InstallApp`r`nShowInstallProgramWindow=1`r`nHideExtractAnimation=1`r`nUseLongFileName=1`r`nInsideCompressed=1`r`nRebootMode=N`r`nInstallPrompt=This will install ScilabReserve.`r`nFinishMessage=ScilabReserve has been installed.`r`nTargetName=$output`r`nFriendlyName=ScilabReserve Setup`r`nAppLaunched=install.cmd`r`nPostInstallCmd=<None>`r`nSourceFiles=SourceFiles`r`n[SourceFiles]`r`nSourceFiles0=$staging`r`n[SourceFiles0]`r`n$($payload -join "`r`n")"
Set-Content -LiteralPath $directive -Value $content -Encoding ASCII
& iexpress.exe /N $directive
if (-not (Test-Path $output)) { throw "IExpress did not produce $output" }
Write-Output "Created $output"
