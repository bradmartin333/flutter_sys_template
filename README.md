# The most detailed systems template

Instructions for setting up this template and for mobile builds can be found in [DESIGN.md](DESIGN.md)

## Features and Examples

- Android, Windows and Linux (More possible) support
- FFI
    - Dart to C++
    - C++ to Dart
    - [JSON Compatible](https://github.com/nlohmann/json)
- [State Management](https://docs.flutter.dev/data-and-backend/state-mgmt/simple)
- [Tab Controller](https://api.flutter.dev/flutter/material/TabController-class.html)
- [A* Path Generation](https://github.com/leethomason/MicroPather)
- [Key-value data persistence](https://docs.flutter.dev/cookbook/persistence/key-value)

## Build Instructions

These instructions assume you have a working Flutter installation. If not, follow the instructions at [flutter.dev](https://flutter.dev/docs/get-started/install).

### ![windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)

1. Download and install [CMake](https://cmake.org/download/) and make sure to add to path during installation
1. Download and install [VS2022 Build Tools](https://aka.ms/vs/17/release/vs_BuildTools.exe)
1. Open PowerShell and run `where.exe /R C:\ msbuild` and confirm that `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe` is present
1. Add `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin` to Environment Variables PATH
1. `winget install -e --id LLVM.LLVM` (For dart ffigen)
1. Restart any open shells
1. run `json_library\build.bat` as an example (This also runs ffigen)

### ![ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

1. `sudo apt install cmake clang lldb lld`
1. `cd json_library/`
1. `./build.sh` (Not `sudo` or paths will be wrong!)

# TODO

- Refactor UI for Flutter version layout changes
- Add macOS build instructions
- Add iOS build instructions
- Add custom icons
- Add custom splash screens
- Create GitHub templates for issues and PRs
- Add CI/CD workflows
- Add unit tests
- Add integration tests
- Add localization support
- Add database integration examples
