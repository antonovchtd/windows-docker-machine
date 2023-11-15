param (
    [switch]$clientToolsOnly
)

function AddToPath([string]$PathToAdd) {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

    if ($currentPath -split ";" -notcontains $PathToAdd) {
        $newPath = "$currentPath;$PathToAdd"
        [Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
        Write-Host "Added '$PathToAdd' to the PATH environment variable."
    } else {
        Write-Host "'$PathToAdd' already exists in the PATH environment variable."
    }
}

function Download {
    param(
        [string]$URL,
        [string]$FILENAME
    )

    if (-not $FILENAME) {
        $tokens = $URL -split '/'
        $FILENAME = $tokens[-1]
    }

    if (Test-Path "$env:TEMP\files\$FILENAME" -PathType Leaf) {
        return "$env:TEMP\files\$FILENAME"
    }

    Write-Host "$FILENAME Download Started" 
    Invoke-WebRequest -Uri $URL -OutFile $FILENAME 
    Write-Host "$FILENAME Download Finished"

    return $FILENAME
}

cd ${HOME}

# Installer
Install-WindowsFeature -name Web-Server -IncludeManagementTools

$URL = "https://download.microsoft.com/download/E/9/8/E9849D6A-020E-47E4-9FD0-A023E99B54EB/requestRouter_amd64.msi"
$FILENAME = Download $URL
Start-Process -FilePath msiexec.exe -ArgumentList "/i $FILENAME /passive /norestart" -Wait
rm $FILENAME

$URL = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
$FILENAME = Download $URL
Start-Process -FilePath msiexec.exe -ArgumentList "/i $FILENAME /passive /norestart" -Wait
rm $FILENAME

# Java
$URL = "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.exe" 
$FILENAME = Download $URL
Start-Process -FilePath $FILENAME -ArgumentList "/s ADDLOCAL=ALL" -Wait 
rm $FILENAME


if ($clientToolsOnly) {
    return
}


# Visual Studio
$URL = "https://aka.ms/vs/17/release/vs_community.exe"
$FILENAME = Download $URL
Start-Process -FilePath $FILENAME -Wait -ArgumentList '--wait --norestart --nocache --passive --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" --add Microsoft.VisualStudio.Component.CoreEditor --add Microsoft.VisualStudio.Workload.CoreEditor --add Microsoft.Net.Component.4.8.SDK --add Microsoft.Net.Component.4.7.2.TargetingPack --add Microsoft.Net.ComponentGroup.DevelopmentPrerequisites --add Microsoft.VisualStudio.Component.JavaScript.Diagnostics --add Microsoft.VisualStudio.Component.Roslyn.Compiler --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Component.Roslyn.LanguageServices --add Microsoft.VisualStudio.Component.TextTemplating --add Microsoft.VisualStudio.Component.SQL.LocalDB.Runtime --add Microsoft.VisualStudio.Component.SQL.CLR --add Microsoft.Component.ClickOnce --add Microsoft.VisualStudio.Component.ManagedDesktop.Core --add Microsoft.NetCore.Component.Runtime.6.0 --add Microsoft.NetCore.Component.Runtime.7.0 --add Microsoft.NetCore.Component.SDK --add Microsoft.Component.PythonTools --add Component.CPython39.x64 --add Microsoft.VisualStudio.Component.VC.CoreIde --add Microsoft.VisualStudio.Component.Windows10SDK --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Graphics.Tools --add Microsoft.VisualStudio.Component.VC.DiagnosticTools --add Microsoft.VisualStudio.Component.Windows11SDK.22000 --add Microsoft.ComponentGroup.PythonTools.NativeDevelopment --add Microsoft.VisualStudio.Workload.Python --add Microsoft.VisualStudio.Component.ManagedDesktop.Prerequisites --add Microsoft.VisualStudio.Component.DotNetModelBuilder --add Microsoft.ComponentGroup.Blend --add Microsoft.VisualStudio.Workload.ManagedDesktop'
rm $FILENAME

# VS Code
$URL = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
$FILENAME = "VSCodeSetup-x64.exe"
Download $URL $FILENAME
Start-Process -FilePath $FILENAME -ArgumentList "/SILENT /NORESTART /MERGETASKS=!runcode" -Wait
rm $FILENAME
$env:PATH = ";C:\Program Files\Microsoft VS Code\bin"
code --install-extension ms-vscode.cpptools-extension-pack
code --install-extension matepek.vscode-catch2-test-adapter
code --install-extension chouzz.vscode-innosetup
code --install-extension alefragnani.pascal
code --install-extension alefragnani.pascal-formatter

# CMake 
$URL = "https://github.com/Kitware/CMake/releases/download/v3.26.4/cmake-3.26.4-windows-x86_64.msi"
$FILENAME = Download $URL
Start-Process -FilePath msiexec.exe -ArgumentList "/i $FILENAME /passive /norestart" -Wait
rm $FILENAME
AddToPath "C:\Program Files\CMake\bin"

# Git
$GIT_VERSION = "2.41.0"
$URL = "https://github.com/git-for-windows/git/releases/download/v$GIT_VERSION.windows.1/Git-$GIT_VERSION-64-bit.exe" 
$FILENAME = Download $URL
Invoke-WebRequest -Uri $URL -OutFile $INSTALLER_PATH
Start-Process -FilePath $FILENAME -ArgumentList "/SP- /SILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS" -Wait
rm $FILENAME
AddToPath "C:\Program Files\Git\bin"

# Strawberry Perl
$STRAWBERRY_VERSION = "5.32.1.1"
$URL = "https://strawberryperl.com/download/$STRAWBERRY_VERSION/strawberry-perl-$STRAWBERRY_VERSION-64bit.msi"
$FILENAME = Download $URL
$INSTALL_DIR = "C:\StrawberryPerl"
Start-Process -FilePath msiexec.exe -ArgumentList "/i $FILENAME /passive INSTALLDIR=$INSTALL_DIR" -Wait
AddToPath "C:\StrawberryPerl\perl\bin\"
rm $FILENAME

# OpenSSL
$OPENSSL_VERSION = "1_1_1v"
$URL = "https://slproweb.com/download/Win64OpenSSL-$OPENSSL_VERSION.msi"
$FILENAME = Download $URL
Start-Process -FilePath msiexec.exe -ArgumentList "/i C:\home\aovcharenko\$FILENAME /passive ADDLOCAL=ALL" -Wait
AddToPath "C:\Program Files\OpenSSL-Win64\bin" 
rm $FILENAME

# Rust
$URL = "https://static.rust-lang.org/rustup/dist/i686-pc-windows-gnu/rustup-init.exe"
$FILENAME = Download $URL
Start-Process -FilePath $FILENAME -ArgumentList "-q -y" -Wait
rm $FILENAME

# Inno Setup

$URL = "https://jrsoftware.org/download.php/is.exe"
$FILENAME = Download $URL
Start-Process -FilePath $FILENAME -ArgumentList "/SILENT /ALLUSERS /NORESTART" -Wait
AddToPath "C:\Program Files (x86)\Inno Setup 6\"
rm $FILENAME

$URL = "https://www.kymoto.org/downloads/ISStudio_Latest.exe"
$FILENAME = Download $URL
Start-Process -FilePath $FILENAME -ArgumentList "/SILENT /NORESTART" -Wait
rm $FILENAME
