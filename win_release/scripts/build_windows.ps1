$currentDir = Get-Location
$buildDir = (Get-Item $currentDir).Parent.FullName
$rootDir = (Get-Item $currentDir).Parent.Parent.FullName

# Get a list of all directories in the parent directory
$oldBuildDirs = Get-ChildItem -Path $buildDir -Directory

# Delete relevant directories in the parent directory
$delDirList = @("bin", "json_library")
foreach ($dir in $oldBuildDirs) {
    if ($delDirList.Contains($dir.BaseName)) {
        Remove-Item -Path $dir.FullName -Recurse -Force
    }
}

# Build flutter and copy build
Start-Process -FilePath "flutter" -ArgumentList "build windows --release" -WorkingDirectory (Join-Path -Path $rootDir -ChildPath "UI") -NoNewWindow -Wait
Copy-Item -Force -Recurse (Join-Path -Path $rootDir -ChildPath "UI\build\windows\x64\runner\Release") -Destination $buildDir
Rename-Item -Path (Join-Path -Path $buildDir -ChildPath "Release") -NewName "bin"

# Copy C++ libs
Copy-Item -Force -Recurse -Verbose (Join-Path -Path $rootDir -ChildPath "json_library") -Destination $buildDir

# Zip dir
Compress-Archive -Force -Path $buildDir -DestinationPath (Join-Path -Path $rootDir -ChildPath "template_app_win_x64.zip")