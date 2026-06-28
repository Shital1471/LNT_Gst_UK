# gst_invoice

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.





Option 1: The Easiest Way (Zip and Share)

When you build the app for Windows, Flutter compiles the executable along with resources and DLL files that the app needs to run.

First, build the release package by running:
powershell

flutter build windows --release


Navigate to this folder on your computer: E:\Gst Invoice\build\windows\x64\runner\
You will see a folder named Release.
Right-click the Release folder $\rightarrow$ select Send to $\rightarrow$ Compressed (zipped) folder (or use WinRAR/7-Zip to create a .zip file).
Share this .zip file with the other person.
How the other person runs it:
They must Extract (unzip) the file first.
Inside the extracted folder, they just double-click gst_invoice.exe to run the app.
Note: Tell them they must not move gst_invoice.exe out of that folder because it needs the data folder and .dll files next to it to run!




<!-- **************************************************** -->


Option 2: Create a Single Windows Installer (.msix file)
If you want to send them a single, professional installer file (like a setup file) that installs the app directly onto their PC:


Add the msix tool to your project's dev dependencies:


powershell
flutter pub add dev:msix

Build and package the installer with this single command:
powershell
flutter pub run msix:create



This will generate a single .msix installer file inside:
build/windows/x64/runner/Release/
Send them that .msix file. They can double-click it, click Install, and the application will be installed on their PC just like a standard Microsoft Store app!