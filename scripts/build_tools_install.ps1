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
    $cacheDir = "$env:TEMP"
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir | Out-Null
    }
    if (-not $FILENAME) {
        $tokens    = $URL -split '/'
        $FILENAME  = $tokens[-1]
    }
    $destination = Join-Path $cacheDir $FILENAME
    if (Test-Path $destination -PathType Leaf) {
        Write-Host "Using cached $FILENAME from provisioned files"
        return $destination
    }

    Write-Host "File $FILENAME not found in cache, downloading..."
    Write-Host "$FILENAME Download Started"
try {
    Invoke-WebRequest -Uri $URL -OutFile $destination
    Write-Host "$FILENAME Download Finished"
}
    catch {
        Write-Host "Failed to download $FILENAME : $_"
        throw
    }
    return $destination
}

cd ${HOME}

# Installer
Install-WindowsFeature -name Web-Server -IncludeManagementTools -ErrorAction Stop

$URL = "https://download.microsoft.com/download/E/9/8/E9849D6A-020E-47E4-9FD0-A023E99B54EB/requestRouter_amd64.msi"
$FILENAME = Download $URL
Start-Process -FilePath msiexec.exe -ArgumentList "/i $FILENAME /passive /norestart" -Wait

$URL = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
$FILENAME = Download $URL
Start-Process -FilePath msiexec.exe -ArgumentList "/i $FILENAME /passive /norestart" -Wait

# Java JDK
$URL = "https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.exe" 
$FILENAME = Download $URL
Start-Process -FilePath $FILENAME -ArgumentList "/s ADDLOCAL=ALL" -Wait

# Set JAVA_HOME and add to PATH for JNI headers
$JAVA_HOME = (Get-ChildItem "C:\Program Files\Java" -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName
[Environment]::SetEnvironmentVariable("JAVA_HOME", $JAVA_HOME, [System.EnvironmentVariableTarget]::Machine)
AddToPath "$JAVA_HOME\bin"

Write-Host "JAVA_HOME set to: $JAVA_HOME"
Write-Host "JNI headers should be available at: $JAVA_HOME\include" 


if ($clientToolsOnly) {
    return
}


# Visual Studio 
$URL = "https://aka.ms/vs/17/release/vs_community.exe"
$FILENAME = Download $URL
Start-Process -FilePath $FILENAME -Wait -ArgumentList '--wait --norestart --nocache --passive --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" --add Microsoft.VisualStudio.Component.CoreEditor --add Microsoft.VisualStudio.Workload.CoreEditor --add Microsoft.Net.Component.4.8.SDK --add Microsoft.Net.Component.4.7.2.TargetingPack --add Microsoft.Net.ComponentGroup.DevelopmentPrerequisites --add Microsoft.VisualStudio.Component.JavaScript.Diagnostics --add Microsoft.VisualStudio.Component.Roslyn.Compiler --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Component.Roslyn.LanguageServices --add Microsoft.VisualStudio.Component.TextTemplating --add Microsoft.VisualStudio.Component.SQL.LocalDB.Runtime --add Microsoft.VisualStudio.Component.SQL.CLR --add Microsoft.Component.ClickOnce --add Microsoft.VisualStudio.Component.ManagedDesktop.Core --add Microsoft.NetCore.Component.Runtime.6.0 --add Microsoft.NetCore.Component.Runtime.7.0 --add Microsoft.NetCore.Component.SDK --add Microsoft.Component.PythonTools --add Component.CPython39.x64 --add Microsoft.VisualStudio.Component.VC.CoreIde --add Microsoft.VisualStudio.Component.Windows10SDK --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Graphics.Tools --add Microsoft.VisualStudio.Component.VC.DiagnosticTools --add Microsoft.VisualStudio.Component.Windows11SDK.22000 --add Microsoft.ComponentGroup.PythonTools.NativeDevelopment --add Microsoft.VisualStudio.Workload.Python --add Microsoft.VisualStudio.Component.ManagedDesktop.Prerequisites --add Microsoft.VisualStudio.Component.DotNetModelBuilder --add Microsoft.ComponentGroup.Blend --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NativeDesktop --add Microsoft.VisualStudio.Component.VC.ATL --add Microsoft.VisualStudio.Component.VC.CMake.Project --add Microsoft.VisualStudio.Component.VC.TestAdapterForBoostTest --add Microsoft.VisualStudio.Component.VC.TestAdapterForGoogleTest --add Microsoft.VisualStudio.Component.VC.Tools.ARM --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest --add Microsoft.VisualStudio.Component.VC.CLI.Support --add Microsoft.VisualStudio.Component.VC.Modules.x86.x64 --add Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.20348'
[Environment]::SetEnvironmentVariable("CL", "/std:c++20", [System.EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("_CL_", "/std:c++20", [System.EnvironmentVariableTarget]::Machine)
    
# Set up JNI include paths for compilation
$JAVA_HOME_SET = [Environment]::GetEnvironmentVariable("JAVA_HOME", [System.EnvironmentVariableTarget]::Machine)
if ($JAVA_HOME_SET) {
    [Environment]::SetEnvironmentVariable("INCLUDE", "$JAVA_HOME_SET\include;$JAVA_HOME_SET\include\win32;$env:INCLUDE", [System.EnvironmentVariableTarget]::Machine)
    Write-Host "Added JNI include paths to INCLUDE environment variable"
}

# VS Code
$URL = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
$FILENAME = "VSCodeSetup-x64.exe"
$FILENAME = Download $URL $FILENAME
Start-Process -FilePath $FILENAME -ArgumentList "/SILENT /NORESTART /MERGETASKS=!runcode" -Wait
AddToPath "C:\Program Files\Microsoft VS Code\bin"

# Set the environment variable to suppress Node.js warnings during extension installation
$env:NODE_OPTIONS = "--force-node-api-uncaught-exceptions-policy=true"

# Install extensions with warning suppression
code --install-extension ms-vscode.cpptools-extension-pack
code --install-extension matepek.vscode-catch2-test-adapter
code --install-extension chouzz.vscode-innosetup
code --install-extension alefragnani.pascal
code --install-extension alefragnani.pascal-formatter

# Clear the environment variable after installation
$env:NODE_OPTIONS = ""

# CMake 
$URL = "https://github.com/Kitware/CMake/releases/download/v3.26.4/cmake-3.26.4-windows-x86_64.msi"
$FILENAME = Download $URL
Start-Process -FilePath msiexec.exe -ArgumentList "/i $FILENAME /passive /norestart" -Wait
AddToPath "C:\Program Files\CMake\bin"

# Git
$GIT_VERSION = "2.49.0"
$URL = "https://github.com/git-for-windows/git/releases/download/v$GIT_VERSION.windows.1/Git-$GIT_VERSION-64-bit.exe"
$FILENAME = Download $URL
Start-Process -FilePath $FILENAME -ArgumentList "/SP- /SILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS" -Wait
AddToPath "C:\Program Files\Git\bin"

# Strawberry Perl
$STRAWBERRY_VERSION = "5.32.1.1"
$URL = "https://strawberryperl.com/download/$STRAWBERRY_VERSION/strawberry-perl-$STRAWBERRY_VERSION-64bit.msi"
$FILENAME = Download $URL
$INSTALL_DIR = "C:\StrawberryPerl"
Start-Process -FilePath msiexec.exe -ArgumentList "/i $FILENAME /passive INSTALLDIR=$INSTALL_DIR" -Wait
AddToPath "C:\StrawberryPerl\perl\bin\"

# OpenSSL
$OPENSSL_VERSION = "1_1_1w"
$URL = "https://slproweb.com/download/Win64OpenSSL-$OPENSSL_VERSION.exe"
$FILENAME = Download $URL
Start-Process -FilePath $FILENAME -ArgumentList "/SILENT /NORESTART /passive ADDLOCAL=ALL" -Wait
AddToPath "C:\Program Files\OpenSSL-Win64\bin"

# Rust
$URL = "https://static.rust-lang.org/rustup/dist/i686-pc-windows-gnu/rustup-init.exe"
$FILENAME = Download $URL
Start-Process -FilePath $FILENAME -ArgumentList "-q -y" -Wait

# Inno Setup
$URL = "https://jrsoftware.org/download.php/is.exe"
$FILENAME = "innosetup.exe"
$FILENAME = Download $URL $FILENAME
Start-Process -FilePath $FILENAME -ArgumentList "/SILENT /ALLUSERS /NORESTART" -Wait
AddToPath "C:\Program Files (x86)\Inno Setup 6\"

$URL = "https://www.kymoto.org/downloads/ISStudio_Latest.exe"
$FILENAME = Download $URL
Start-Process -FilePath $FILENAME -ArgumentList "/SILENT /NORESTART" -Wait
