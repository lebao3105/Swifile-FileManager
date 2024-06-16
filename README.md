<div align="right">
	<img src="https://raw.githubusercontent.com/lebao3105/Swifile-FileManager/main/logo.svg">
</div>

# Swifile

Swifile is a simple SwiftUI application for managing files and folders on your device. 

> This application is meant for jailbroken devices. A personal (just me, @lebao3105) work is underway for more platforms.

Swifile provides a user-friendly interface to browse, search, and manage files and folders on your device. It allows you to toggle file size visibility, sort files by various criteria, and perform actions such as opening, deleting, and sharing files.

## Features

- Browse files and folders in a directory
- Toggle file size visibility
- Sort files by name, Alphabetical, size, or modification date
- Search files by name
- Delete files and folders

- Planned future updates:
  - File sharing
  - File modifications
  - Sharing files
  - Recycling bin
  - Open files in external applications
  - **Class Dump** (Generate Objective-C headers from Mach-O files)

## Installation

Your phone: iOS 15+ with TrollStore for (t)ipa builds or just jailbreak the phone.

### Built binaries

Just obtain a release from either Releases page or [lebao3105](https://github.com/lebao3105)'s [repo](https://lebao3105.github.io/repo).

### Build from source

Requires these to build from source:

* macOS with recent Xcode installation
* [HomeBrew](https://brew.sh)
* [Theos](https://theos.dev)
* Cross [Free Pascal Compiler](https://freepascal.org) FOR iOS : optional, read [this](https://forum.lazarus.freepascal.org/index.php?topic=66249.0) for the installation

Clone this repository.

> Set the `SYSROOT` environment variable to your preferred SDK, `ARCHS` to either `arm64`, `arm64e` or both for the target build architecture

> Set `USE_FPC` environment variable to 1 to use the root helper (which does file operations) written in Pascal

> IPA builds are not working (no root permission for the helper right now). Set `PACKAGE_FORMAT` to `ipa` to make .ipa.

Send the file to your phone (on macOS use AirDrop), install with TrollStore.

Or you can setup Theos and run:

* `make package` to make a deb
* `make do` to make a deb and install it onto your phone
* `make` to build the project

> Note: The root helper by default will have both arm64 and arm64e Mach-O in it. Modify the `ARCHS` variable as said above to change this. This is **only** known for the C++ helper.

All binaries are placed in packages/ unless you changed it somehow.

Look at Theos documentation for useful environment variables and options (you will need them).

Profit!

### Use with FridaCodeManager (SparkCode)

FridaCodeManager by SparkleChan + SeanIsNotAConstant is a way to build, make, run Swift and ObjectiveC{,++}.

This app is originally made in SparkCode!

Currently as this is not confirmed to work with SparkCode yet, as the new C++ helper came along with support for them in SparkCode, also new features, also nobody try it yet (as far as we know).

You can try packing the source code to a ZIP with the right structure that fits Frida, import it.

## Screenshots

![IMG_8261](https://github.com/speedyfriend67/Swifile-FileManager/assets/82425907/8d25a2e3-9e33-4476-9001-fee0cd7bd671)

More screenshots required.

## Author & Helpers

Originally made by [speedyfriend67](https://github.com/speedyfriend67)

TIPA build script made with the help of [Geranium](https://github.com/c22dev/Geranium)

Thanks to [AppinstalleriOS](https://github.com/AppInstalleriOSGH) and [lebao3105](https://github.com/lebao3105) for many great contributions!

Thanks to [TigiSoftware](https://www.tigisoftware.com/default/) for their [Filza](https://www.tigisoftware.com/default/?page_id=78) - also ideas for this app!

Thanks everyone behind FridaCodeManager for their convenient code editor + builder!

## License

This project is licensed under the [MIT License](LICENSE).
