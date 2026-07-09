
# Deb-progress-installer

<p align="center">
  <img src="Live-Preview.png?v=2" alt="Application Preview" width="100%">
</p>


A lightweight graphical utility using [Zenity](https://github.com/GNOME/zenity) for seamless visual management (install, reinstall, remove) of local Debian (`.deb`) packages.

## ✨ Features

**Deb-progress-installer** brings full package lifecycle management to your desktop by wrapping native, robust backend systems (`apt` and `dpkg`) into a clean, modern user interface.

* **📥 Seamless Local Installation:** Easily install any local `.deb` package without manually opening a terminal. The tool safely intercepts administrative hooks to resolve and download missing system dependencies automatically.
* **🔄 Quick Reinstallation:** If the application is already on your system, the interface automatically detects it and provides an option to force a clean reinstallation—perfect for fixing broken binaries or resetting software states.
* **❌ Clean Uninstallation / Removal:** No need to jump into a separate app store or run terminal commands to delete software. If the package is present, you can choose to purge and remove it completely right from the prompt.
* **📊 Real-Time Progress Tracking:** Translates dense terminal status lines into a smooth, readable graphical progress bar using `Zenity`, providing terminal-free visual feedback.
* **🧠 Dynamic System Audits:** Simulates package layouts before executing any changes to alert you of potential system conflicts or dependency errors before they occur.
  

## 💡 Motivation: Why This Was Created

Traditional GUI installers used to be the go-to standard, but they've been abandoned for years. Running that legacy code on modern systems like Ubuntu 26.04 frequently leads to frustrating freezes and crashes. To make matters worse, official Software Centers have become sluggish and bloated, often trying to force-feed users Snaps instead of just handling a simple local .deb file.


---


## 🚀 One-Time Setup

### Manual Download (Ubuntu / Zorin / Debian / LMDE)

You can install the package directly without needing to manage external repositories. This works perfectly on Ubuntu, Debian, and all major derivative distributions:

[![Download .deb Installer](https://img.shields.io/badge/Download-.deb_Installer-blue?style=for-the-badge&logo=ubuntu)](https://github.com/cybermaxpower/deb-progress-installer/releases/latest)

#### Method A: Graphical Install (Easiest)
1. Click the **Download .deb Installer** badge above to go to the latest release page.
2. Click on the `.deb` file under the **Assets** section to download it.
3. Double-click the downloaded file in your **Downloads** folder to launch your system's default Software Store, then click **Install**.

Markdown
### Method B: Quick Terminal Install

If you prefer the command line, copy and paste this single command. It queries the GitHub API to dynamically fetch the latest versioned package, downloads it safely to your temporary directory, and configures all required system dependencies automatically:

```bash
wget -O /tmp/installer.deb $(curl -s [https://api.github.com/repos/cybermaxpower/deb-progress-installer/releases/latest](https://api.github.com/repos/cybermaxpower/deb-progress-installer/releases/latest) | grep -o 'https://[^"]*\.deb' | head -n 1) && sudo apt install /tmp/installer.deb && rm /tmp/installer.deb

```

## 🛠️ How to Enable & Use It
Once installed, you need to tell your file manager to use this tool to open Debian packages. You only have to do this once!

### Step 1: Set the Default Handler
Find any .deb file on your computer (for example, in your Downloads folder).

Right-click the .deb file.

Select Open With Other Application (or Properties -> Open With, depending on your desktop layout).

Look through the list and select Deb Installer.

Click the Set as Default button.

### Step 2: Run an Installation
From now on, whenever you want to install a software package:

Simply double-click or right-click -> Open With any .deb file.

A clean, visual Zenity progress bar will pop up to show you exactly how the installation is progressing!

## 🔍 How It Works (Extended Description)
Standard command-line tools like dpkg don't natively provide a graphical progress readout, which can leave desktop users wondering if an installation is stuck.

deb-progress-installer acts as an intelligent, lightweight wrapper that bridges the gap between the Debian package management backend and the desktop environment.

## How It Differs From Tools Like `deb-get`:
* **A GUI-First Experience:** Unlike CLI utilities like `deb-get`—which focus on downloading popular third-party software from the terminal—`deb-progress-installer` acts as a native desktop mouse-click handler. It is designed for those who just want to double-click a local file in their file manager.
* **Granular Progress Tracking:** Standard command-line tools often hide what they are doing behind dense text walls. This tool uses a clean, visual Zenity progress bar that parses the installation frame-by-frame, tracking granular stages like data unpacking, dependency resolution, and real-time backend configuration so you are never left guessing if your installation is stuck.

`deb-progress-installer` fills this gap perfectly: a dead-simple, blazing-fast, and reliable native tool that does one thing and does it well—installing your local packages with beautiful, real-time graphical progress tracking without any of the baggage.

Behind the Scenes:
Root Privilege Handling: The application leverages pkexec or sudo to securely elevate permissions, ensuring safe package execution.

Terminal Parsing: It triggers a non-interactive dpkg installation process and actively intercepts the standard output (stdout) streams.

Regex Status Filtering: The core script monitors specific packaging triggers, such as unpacking, setting up, and configuring dependencies.

Zenity UI Generation: It parses those terminal triggers in real-time, instantly converting raw text percentages into a smooth, native GTK graphical progress bar via zenity.


## ⚖️ Disclaimer & Warranty


### PROVIDED "AS IS" — NO WARRANTY
This software application is provided by the copyright holders and contributors "as is" and any express or implied warranties, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose are completely disclaimed. In no event shall the developer or contributors be liable for any direct, indirect, incidental, special, exemplary, or consequential damages (including, but not limited to, procurement of substitute goods or services; loss of use, data, or profits; or business interruption) however caused and on any theory of liability, whether in contract, strict liability, or tort (including negligence or otherwise) arising in any way out of the use of this software, even if advised of the possibility of such damage.

### SYSTEM MODIFICATIONS & RISK
System-Wide Access: Unlike sandboxed container formats (such as Flatpak or Snap), this tool handles native Debian (.deb) packages. These packages are extracted and executed system-wide using elevated administrative privileges (pkexec). Running installations through this frontend will directly alter core system directories, modify shared infrastructure libraries, and manipulate your base operating system configuration.

Purge Operations: Utilizing the "Remove (Uninstall)" feature executes a complete system purge (apt-get purge). This process will permanently delete system-wide configuration files and local assets associated with that package.

### USER RESPONSIBILITY
The end-user assumes absolute and full responsibility for any software operations, updates, or removals executed using this application frontend.

Because native package management interacts directly with the core operating system layer, you must carefully verify the source, integrity, and dependency requirements of any .deb file before confirming administrative authentication. The author holds no liability or responsibility for broken system packages, unresolved dependency conflicts, accidental software removal, or any misuse of this scripting automation.
