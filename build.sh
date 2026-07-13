#!/bin/bash
# ==============================================================================
# SCRIPT:       build.sh
# DESCRIPTION:  Automates the compilation of the deb-progress-installer
#               into a standard Debian package (.deb) with desktop integration,
#               copyright metadata, and a standardized changelog.
# ==============================================================================

# Halt script execution on any unexpected error
set -e

# Define packaging metadata
PACKAGE_NAME="deb-progress-installer"
VERSION="1.1.5"
ARCH="all"
BUILD_DIR="${PACKAGE_NAME}_${VERSION}_${ARCH}"
SRC_SCRIPT="deb-progress-installer.sh"

echo "=========================================="
echo " Starting Build Pipeline: v${VERSION}"
echo "=========================================="

# 1. Guard check: Ensure source script exists
if [ ! -f "$SRC_SCRIPT" ]; then
    echo "[-] Error: Source script '$SRC_SCRIPT' not found in current directory."
    echo "    Please make sure it is named correctly and lies in this folder."
    exit 1
fi

# 2. Workspace cleanup: Remove stale build environments
if [ -d "$BUILD_DIR" ]; then
    echo "[*] Cleaning up old directory layout..."
    rm -rf "$BUILD_DIR"
fi
rm -f "${BUILD_DIR}.deb"

# 3. Create the packaging structure
echo "[+] Constructing Debian filesystem layout..."
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/local/bin"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/doc/${PACKAGE_NAME}"

# 4. Deploy source payload & assign execution privileges
echo "[+] Copying application script to local system layout..."
cp "$SRC_SCRIPT" "$BUILD_DIR/usr/local/bin/deb-progress-installer"
chmod 755 "$BUILD_DIR/usr/local/bin/deb-progress-installer"

# 5. Generate the .desktop shortcut file
echo "[+] Generating desktop environment shortcut integration..."
cat << EOF > "$BUILD_DIR/usr/share/applications/deb-progress-installer.desktop"
[Desktop Entry]
Version=${VERSION}
Type=Application
Name=DEB Progress Installer
Comment=Install and manage Debian packages with a progress UI
Exec=deb-progress-installer %f
Icon=system-software-install
Terminal=false
Categories=System;Utility;
MimeType=application/vnd.debian.binary-package;
NoDisplay=false
EOF

chmod 644 "$BUILD_DIR/usr/share/applications/deb-progress-installer.desktop"

# 6. Write out the Debian control manifest
echo "[+] Writing packaging blueprint..."
cat << EOF > "$BUILD_DIR/DEBIAN/control"
Package: ${PACKAGE_NAME}
Version: ${VERSION}
Architecture: ${ARCH}
Maintainer: cybermaxpower <carber.maxpower@gmail.com>
Depends: zenity, apt, dpkg
Section: utils
Priority: optional
Description: A lightweight graphical utility using Zenity for visual package management.
EOF

# Ensure there are no accidental spaces or tabs before fields in control file
sed -i 's/^[ \t]*Package:/Package:/' "$BUILD_DIR/DEBIAN/control"
sed -i 's/^[ \t]*Version:/Version:/' "$BUILD_DIR/DEBIAN/control"
sed -i 's/^[ \t]*Architecture:/Architecture:/' "$BUILD_DIR/DEBIAN/control"
sed -i 's/^[ \t]*Maintainer:/Maintainer:/' "$BUILD_DIR/DEBIAN/control"
sed -i 's/^[ \t]*Depends:/Depends:/' "$BUILD_DIR/DEBIAN/control"
sed -i 's/^[ \t]*Section:/Section:/' "$BUILD_DIR/DEBIAN/control"
sed -i 's/^[ \t]*Priority:/Priority:/' "$BUILD_DIR/DEBIAN/control"
sed -i 's/^[ \t]*Description:/Description:/' "$BUILD_DIR/DEBIAN/control"

# 7. Generate and place the copyright manifest in standard system docs
echo "[+] Generating copyright manifest..."
cat << 'EOF' > "$BUILD_DIR/usr/share/doc/${PACKAGE_NAME}/copyright"
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: deb-progress-installer
Source: https://github.com/cybermaxpower/deb-progress-installer

Files: *
Copyright: 2026 Matt <carber.maxpower@gmail.com>
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
EOF

chmod 644 "$BUILD_DIR/usr/share/doc/${PACKAGE_NAME}/copyright"

# 8. Generate and compress the Debian Changelog
echo "[+] Generating and compressing standard changelog..."
cat << 'EOF' > "$BUILD_DIR/usr/share/doc/${PACKAGE_NAME}/changelog.Debian"
deb-progress-installer (1.1.5) stable; urgency=low

  * Initial release of the streamlined GTK progress installer.
  * Stripped theme-forcing overrides and GTK custom configuration fixing.
  * Added automated dependency simulation checking.
  * Added smart upgrade, reinstall, and uninstall state detection flows.
  * Integrated standard copyright manifest, changelog, and desktop shortcut.

 -- cybermaxpower <carber.maxpower@gmail.com>  Mon, 13 Jul 2026 21:00:00 +0100
EOF

# Compress the changelog to Debian specifications (.gz format)
chmod 644 "$BUILD_DIR/usr/share/doc/${PACKAGE_NAME}/changelog.Debian"
gzip -9 -n "$BUILD_DIR/usr/share/doc/${PACKAGE_NAME}/changelog.Debian"

# 9. Apply system structure permissions
chmod 755 "$BUILD_DIR/DEBIAN"

# 10. Compile the project (forces root ownership on build files safely)
echo "[+] Compiling layout into production-ready .deb payload..."
dpkg-deb --root-owner-group --build "$BUILD_DIR" > /dev/null

# 11. Clean up workspace
echo "[*] Post-build cleanup of intermediate files..."
rm -rf "$BUILD_DIR"

echo "=========================================="
echo " SUCCESS: Created ${BUILD_DIR}.deb"
echo "=========================================="
