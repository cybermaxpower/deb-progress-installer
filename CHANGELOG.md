# Changelog

All notable changes to this project will be documented in this file.
## [1.0.7] - 2026-07-05

### 🐛 Bug Fixes & Rendering Stability
* **X11/Compiz Transparency Fix:** Resolved a severe hardware-acceleration issue where the UI would render completely transparently or only become opaque upon mouse hover on certain desktop environments. Added an explicit `GSK_RENDERER=cairo` fallback engine pipeline to force clean rendering on non-GNOME X11 compositors.
* **Native Theme Enforcement:** Completely removed experimental sandboxed CSS overrides that inadvertently stripped native desktop dark/light mode configurations. The application now gracefully inherits global desktop theme choices (like *Yaru* or *Adwaita*).
* **Selection Box Clearance:** Natively expanded the choice list window framework parameters to `--width=480 --height=320`. This grants full vertical row clearance to selection options, preventing text clipping on the uninstallation/reinstallation dialogue under heavy desktop system font scaling.
* **Code Optimization:** Cleaned up redundant dependency logic checks to streamline script execution performance.

## [1.0.4] - 2026-05-29

### 🚀 Changed
* **Real-Time Progress Streaming:** Rebuilt the core tracking engine to use a direct live descriptor pipe (`3>&1`). Progress data is now parsed concurrently alongside `apt` actions, replacing the old behavior where the bar sat at 0% and jumped straight to 100% at the end.
* **Database-Driven Verification:** Swapped the generic installer exit-code verification check for a direct `dpkg-query` database inspection. The utility now marks an installation as successful if the core package is safely registered, successfully bypassing non-critical upstream post-install script warnings.

### 🐛 Fixed
* **Polkit Cancellation Logic:** Added explicit tracking for the `Request dismissed` error string emitted by `pkexec` via `${PIPESTATUS[0]}`. Hitting "Cancel" or denying permissions now cleanly exits with an informative, friendly message instead of a red "Installation Failed" system error.
* **Self-Dependency Prompt:** Fixed a logic bug where local packages falsely identified themselves as missing online dependencies. The pre-check sequence now uses `dpkg-deb -f` to query the true internal Debian package name and successfully strips it from the external download queue.
* **Subshell Auth Crash:** Restructured the execution layout to keep `pkexec` securely in the foreground, fixing an issue where the interface would unexpectedly vanish on certain Wayland/X11 display server configurations.
