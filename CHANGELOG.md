# Changelog

All notable changes to this project will be documented in this file.

## [1.1.6] 2026-08-02

⚙️ Non-Interactive Execution Safeguards: Added DEBIAN_FRONTEND=noninteractive and dpkg configuration flags (--force-confdef, --force-confold). This prevents the application from hanging silently in the background when installing wrapper packages or software that triggers post-install web fetches and terminal keyboard prompts.

🔖 Metadata & Header Bump: Updated all internal metadata and script headers cleanly across the codebase to v1.1.6.

## [1.1.5] - 2026-07-13

### Added
- Automated dependency simulation checking.
- Smart upgrade, reinstall, and uninstall state detection flows.

### Removed
- All theme-forcing overrides and GTK custom styling configuration workarounds (theme management is now fully delegated to the user's system compositor).

## [1.1.0] - 2026-07-06

### ✨ Added
* **Smart Version Upgrade Detection:** Implemented `dpkg --compare-versions` to automatically trigger seamless upgrades when a newer local `.deb` file is supplied, bypassing unnecessary reinstall/remove prompts.
* **Localization Guardrails:** Forced background processing utilities to fallback to the standard C locale (`LC_ALL=C`) to ensure text-based dependency parsing works flawlessly across all international system languages.

### ⚡ Changed
* **Performance Optimization (Cairo Backend):** Switched the core GTK pipeline engine to use the 2D Cairo renderer (`GSK_RENDERER=cairo`) to drastically reduce CPU overhead and eliminate UI stuttering during progress tracking.

### 🛠️ Fixed
* **Theme Rendering Fix:** Resolved visibility glitches on certain X11 configurations where custom desktop themes made the Zenity window render transparently. Added a temporary custom CSS property at startup to explicitly enforce a solid background color using standard GTK style overrides.

All notable changes to this project will be documented in this file.
## [1.0.7] - 2026-07-05

### 🐛 Bug Fixes & Rendering Stability
* **X11/Compiz Transparency Fix:** Resolved a severe hardware-acceleration issue where the UI would render completely transparently or only become opaque upon mouse hover on certain desktop environments. Added an explicit `GSK_RENDERER=cairo` fallback engine pipeline to force clean rendering on non-GNOME X11 compositors.
* **Native Theme Enforcement:** Completely removed experimental sandboxed CSS overrides that inadvertently stripped native desktop dark/light mode configurations. The application now gracefully inherits global desktop theme choices (like *Yaru* or *Adwaita*).
* **Selection Box Clearance:** Natively expanded the choice list window framework parameters to `--width=480 --height=320`. This grants full vertical row clearance to selection options, preventing text clipping on the uninstallation/reinstallation dialogue under heavy desktop system font scaling.
* **Code Optimization:** Cleaned up redundant dependency logic checks to streamline script execution performance.

## [1.0.5] - 2026-07-04

### ✨ New Features & Package Management
* **Intelligent State Detection:** Added an automated system check using backend `dpkg` queries to determine if a targeted `.deb` package is already present on the host system before executing an installation path.
* **Interactive Maintenance UI:** Introduced a dynamic Zenity dialogue box that triggers when an existing package is detected. Instead of failing or blindly overwriting, the interface now gives users explicit options to either **reinstall** or **remove (uninstall)** the application.
* **Streamlined Routing Logic:** Refactored the underlying script flow to dynamically pivot between native `apt install --reinstall` and `apt purge/remove` sequences based on the user's graphical selection.

## [1.0.4] - 2026-05-29

### 🚀 Changed
* **Real-Time Progress Streaming:** Rebuilt the core tracking engine to use a direct live descriptor pipe (`3>&1`). Progress data is now parsed concurrently alongside `apt` actions, replacing the old behavior where the bar sat at 0% and jumped straight to 100% at the end.
* **Database-Driven Verification:** Swapped the generic installer exit-code verification check for a direct `dpkg-query` database inspection. The utility now marks an installation as successful if the core package is safely registered, successfully bypassing non-critical upstream post-install script warnings.

### 🐛 Fixed
* **Polkit Cancellation Logic:** Added explicit tracking for the `Request dismissed` error string emitted by `pkexec` via `${PIPESTATUS[0]}`. Hitting "Cancel" or denying permissions now cleanly exits with an informative, friendly message instead of a red "Installation Failed" system error.
* **Self-Dependency Prompt:** Fixed a logic bug where local packages falsely identified themselves as missing online dependencies. The pre-check sequence now uses `dpkg-deb -f` to query the true internal Debian package name and successfully strips it from the external download queue.
* **Subshell Auth Crash:** Restructured the execution layout to keep `pkexec` securely in the foreground, fixing an issue where the interface would unexpectedly vanish on certain Wayland/X11 display server configurations.
