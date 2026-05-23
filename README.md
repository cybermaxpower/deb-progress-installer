# Debian Package Progress Installer

A lightweight utility for Ubuntu, Ubuntu Cinnamon, and Zorin OS that shows a visual progress bar using Zenity when installing local `.deb` files.

---

## 🚀 One-Time Setup

To get the application installed and ensure you receive automatic background updates, open your terminal and run the following commands:

```bash
sudo add-apt-repository ppa:cybermaxpower/deb-progress-installer
sudo apt update
sudo apt install deb-progress-installer
```

🛠️ How to Enable & Use It
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
