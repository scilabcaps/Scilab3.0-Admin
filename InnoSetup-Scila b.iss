[Setup]
AppName=Scilab
AppVersion=1.0.1
DefaultDirName={autopf}\Scilab
DefaultGroupName=Scilab
OutputDir=C:\Users\trick\OneDrive\Documents\Projects\Scilab\Scilab3.0-Admin\build\installer
OutputBaseFilename=Scilab_Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
SetupIconFile=C:\Users\trick\OneDrive\Documents\Projects\Scilab\Scilab3.0-Admin\assets\images\LOGO_ICO.ico
UninstallDisplayIcon={app}\admin_scalib.exe

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "C:\Users\trick\OneDrive\Documents\Projects\Scilab\Scilab3.0-Admin\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Scilab"; Filename: "{app}\admin_scalib.exe"; IconFilename: "{app}\admin_scalib.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\Scilab"; Filename: "{app}\admin_scalib.exe"; IconFilename: "{app}\admin_scalib.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\admin_scalib.exe"; Description: "{cm:LaunchProgram,Scilab}"; Flags: nowait postinstall skipifsilent