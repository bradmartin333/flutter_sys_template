# Creating This Template
 
## Making the UI

- Make it's own directory, `UI`
- Make a simple navigator using the [DefaultTabController](https://api.flutter.dev/flutter/material/DefaultTabController-class.html)
- Create a simple BLoC structure

## Implementing C++ JSON Library (To test with)

- Download [`json.hpp`](https://github.com/nlohmann/json/releases) and put in `json_library\src`
- Create a bridge C++ class (Don't know if that is best practice or not... new to this) and `.def` file
- Create `json_library\CMakeLists.txt` and a build/generator script
- Create root level `.gitignore` for `*library/bin` and `*library/build`

## Implementing async FFI with native ports

- Download the contents of the `json_library\src\dart` directory from the [dart-lang repo](https://github.com/dart-lang/sdk/tree/master/runtime/include)
- Add `Dart_InitializeApiDL` to the `.def` file
- Make some test functions in `*bridge.cpp` and include them in `*bridge.hpp` and the `.def` file
- Add `C` as a a language to `json_library\CMakeLists.txt`
- Look for `*.c` and `*.h` files in `json_library\CMakeLists.txt`
- Implement the `ReceivePort` and required funtions in `UI\lib\native_json.dart` as per [this comment](https://github.com/flutter/flutter/issues/63255#issuecomment-671216406)
- Add `../json_library/src/dart/dart_api_dl.h` to entry points in `UI\config.yaml`
- Update `UI\android\app\CMakeLists.txt` in the same way

## Configure Flutter project for ffigen

- Add `ffigen` to `dev_dependencies` in `UI\pubspec.yaml`
- Create `UI\config.yaml` based off the file in this repo
- Create empty `UI\lib\generated_bindings.dart`
- Create wrapper like `UI\lib\native_json.dart`

## Platform Specific Setup Instructions

### ![android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) built from ![windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)

These steps assume that you have a working Windows build and a working Android Studio installation / android mobile emulator.

Make sure your JDK version supports gradle v8.14 (`java -version` vs [this matrix](https://docs.gradle.org/current/userguide/compatibility.html)) as defined in `UI\android\gradle\wrapper\gradle-wrapper.properties`. When updating the gradle version in the `.properties` file or in `settings.gradle`, make sure to `flutter clean` and then `cd UI\android` and run `.\gradlew.bat clean` to sync and better debug any errors.

1. Add `**/.cxx` to `UI\android\.gitignore`
1. Setup CMake for Android
    - `where.exe cmake` in PowerShell should yield `C:\Program Files\CMake\bin\cmake.exe`
    - Update `UI\android\local.properties` by adding `cmake.dir=C:\\Program Files\\CMake` (Make sure not to have trailing slashes or bin!)
1. Update `UI\android\build.gradle` by adding:
    ```
    android {
        ...
        externalNativeBuild {
            cmake {
                path = file("CMakeLists.txt")
            }
        }
    }
    ```
1. (Not sure if necessary) Update beginning of `UI\android\app\src\main\AndroidManifest.xml` with:
    ```
    <manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools">
        <application
            ...
            android:extractNativeLibs="true"
            tools:replace="android:extractNativeLibs">
        </application>
    ```
1. Create `UI\windows\CMakeLists.txt` based off the file in this repo

### ![android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) built from ![ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

- [Ubuntu Android Studio](https://github.com/mfonville/android-studio)
- [Linux Android Studio](https://developer.android.com/studio/install#linux) (Haven't tried this method)
