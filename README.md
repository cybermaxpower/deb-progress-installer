# deb-progress-installer

A lightweight graphical utility that uses Zenity to show a visual progress bar while installing local Debian (`.deb`) packages.

---

## 🚀 One-Time Setup

### Option 1: Ubuntu 26.04 PPA
To get the application installed and ensure you receive automatic background updates, open your terminal and run the following commands:

```Bash
sudo add-apt-repository ppa:cybermaxpower/deb-progress-installer
sudo apt update
sudo apt install deb-progress-installer
```

### Option 2: Manual Download (No PPA Required)
If you are using a non-Ubuntu distribution (like pure Debian or LMDE), or prefer not to add a PPA to your system, you can download and install the raw package manually:

Head over to the Latest Release page.

Download the .deb file from the Assets section at the bottom of the release.

Install it using your system's package manager or by running the following command in your terminal (replace version with the downloaded version number):

```Bash
sudo dpkg -i deb-progress-installer_version_all.deb
sudo apt-get install -f
```

## 🛠️ How to Enable & Use It
Once installed, you need to tell your file manager to use this tool to open Debian packages. You only have to do this once!

Step 1: Set the Default Handler
Find any .deb file on your computer (for example, in your Downloads folder).

Right-click the .deb file.

Select Open With Other Application (or Properties -> Open With, depending on your desktop layout).

Look through the list and select Deb Installer.

Click the Set as Default button.

Step 2: Run an Installation
From now on, whenever you want to install a software package:

Simply double-click or right-click -> Open With any .deb file.

A clean, visual Zenity progress bar will pop up to show you exactly how the installation is progressing!

## 🔍 How It Works (Extended Description)
Standard command-line tools like dpkg don't natively provide a graphical progress readout, which can leave desktop users wondering if an installation is stuck.

deb-progress-installer acts as an intelligent, lightweight wrapper that bridges the gap between the Debian package management backend and the desktop environment.

Behind the Scenes:
Root Privilege Handling: The application leverages pkexec or sudo to securely elevate permissions, ensuring safe package execution.

Terminal Parsing: It triggers a non-interactive dpkg installation process and actively intercepts the standard output (stdout) streams.

Regex Status Filtering: The core script monitors specific packaging triggers, such as unpacking, setting up, and configuring dependencies.

Zenity UI Generation: It parses those terminal triggers in real-time, instantly converting raw text percentages into a smooth, native GTK graphical progress bar via zenity.

## Development Notes
This application was designed and developed in collaboration with Google Gemini, utilizing AI-assisted software engineering to build the core utility and structure the native Debian packaging pipeline.
