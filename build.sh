#!/bin/bash
# Build script for Astro Moments
# Creates distribution packages for Windows, macOS, and Linux following LÖVE2D best practices
# Reference: https://love2d.org/wiki/Game_Distribution

set -e  # Exit on error

# Configuration
GAME_NAME="AstroMoments"
# Extract version from version.lua
GAME_VERSION=$(grep 'Version.current = ' version.lua | sed 's/.*"\(.*\)".*/\1/')
LOVE_VERSION="11.5"  # Update this to match your LÖVE version
BUILD_DIR="builds"
DIST_DIR="dist"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to download LÖVE binaries
download_love_binaries() {
    echo -e "\n${BLUE}Checking for LÖVE binaries...${NC}"

    local binaries_dir="love-binaries"
    local need_download=false

    # Check if binaries exist
    if [ ! -d "$binaries_dir/windows" ] || [ -z "$(ls -A $binaries_dir/windows 2>/dev/null)" ]; then
        echo -e "${YELLOW}Windows binaries not found${NC}"
        need_download=true
    fi

    if [ ! -d "$binaries_dir/macos/love.app" ]; then
        echo -e "${YELLOW}macOS binaries not found${NC}"
        need_download=true
    fi

    if [ ! -d "$binaries_dir/linux" ] || [ -z "$(ls -A $binaries_dir/linux 2>/dev/null)" ]; then
        echo -e "${YELLOW}Linux binaries not found${NC}"
        need_download=true
    fi

    if [ "$need_download" = false ]; then
        echo -e "${GREEN}✓ All LÖVE binaries found${NC}"
        return 0
    fi

    echo -e "\n${BLUE}Downloading LÖVE ${LOVE_VERSION} binaries...${NC}"
    echo -e "${YELLOW}This may take a few minutes depending on your connection${NC}\n"

    mkdir -p "$binaries_dir"
    cd "$binaries_dir"

    # Download Windows 64-bit
    if [ ! -d "windows" ] || [ -z "$(ls -A windows 2>/dev/null)" ]; then
        echo -e "${BLUE}Downloading Windows binaries...${NC}"
        curl -L -o love-win64.zip "https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-win64.zip"
        mkdir -p windows
        unzip -q love-win64.zip
        mv "love-${LOVE_VERSION}-win64"/* windows/
        rm -rf "love-${LOVE_VERSION}-win64" love-win64.zip
        echo -e "${GREEN}✓ Windows binaries downloaded${NC}"
    fi

    # Download macOS
    if [ ! -d "macos/love.app" ]; then
        echo -e "${BLUE}Downloading macOS binaries...${NC}"
        curl -L -o love-macos.zip "https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-macos.zip"
        mkdir -p macos
        unzip -q love-macos.zip -d macos/
        rm love-macos.zip
        echo -e "${GREEN}✓ macOS binaries downloaded${NC}"
    fi

    # Download Linux (we'll use AppImage approach)
    if [ ! -d "linux" ] || [ -z "$(ls -A linux 2>/dev/null)" ]; then
        echo -e "${BLUE}Downloading Linux binaries...${NC}"
        mkdir -p linux
        # For Linux, we'll just note that users can run the .love file directly
        # or we can provide instructions to install LÖVE from their package manager
        echo -e "${YELLOW}Note: Linux users can run the .love file directly with LÖVE installed${NC}"
        echo -e "${YELLOW}Or install via: sudo apt install love (Debian/Ubuntu)${NC}"
        touch linux/.placeholder
        echo -e "${GREEN}✓ Linux distribution ready (.love file)${NC}"
    fi

    cd ..
    echo -e "${GREEN}✓ LÖVE binaries setup complete${NC}\n"
}

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Astro Moments - Build Script${NC}"
echo -e "${BLUE}  Version: ${GAME_VERSION}${NC}"
echo -e "${BLUE}================================================${NC}"

# Download LÖVE binaries if needed
download_love_binaries

# Clean previous builds
echo -e "\n${GREEN}[1/5] Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# Create .love file
echo -e "\n${GREEN}[2/5] Creating .love file...${NC}"
LOVE_FILE="$BUILD_DIR/${GAME_NAME}.love"

# Create a temporary directory for the love file contents
TEMP_DIR=$(mktemp -d)

# Copy game files (excluding build artifacts and development files)
rsync -av --progress \
    --exclude="$BUILD_DIR" \
    --exclude="$DIST_DIR" \
    --exclude=".git" \
    --exclude=".gitignore" \
    --exclude="*.md" \
    --exclude="docs" \
    --exclude="build.sh" \
    --exclude="sprites/asepriteFiles" \
    --exclude="*.aseprite" \
    --exclude=".vscode" \
    ./ "$TEMP_DIR/"

# Create the .love file (ZIP archive with no compression for faster loading)
cd "$TEMP_DIR"
zip -9 -r "$OLDPWD/$LOVE_FILE" . -q
cd "$OLDPWD"

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✓ Created $LOVE_FILE${NC}"

# Package for each platform
echo -e "\n${GREEN}[3/5] Packaging for platforms...${NC}"

# ============================================
# WINDOWS BUILD
# ============================================
echo -e "\n${BLUE}Building for Windows...${NC}"
WINDOWS_DIR="$DIST_DIR/windows"
mkdir -p "$WINDOWS_DIR"

if [ -d "love-binaries/windows" ]; then
    # Copy LÖVE Windows binaries
    cp -r love-binaries/windows/* "$WINDOWS_DIR/"

    # Concatenate game with love.exe to create the executable
    cat "$WINDOWS_DIR/love.exe" "$LOVE_FILE" > "$WINDOWS_DIR/${GAME_NAME}.exe"

    # Remove the original love.exe
    rm "$WINDOWS_DIR/love.exe"

    echo -e "${GREEN}✓ Windows build complete${NC}"
else
    echo -e "${RED}⚠ Windows LÖVE binaries not found in love-binaries/windows${NC}"
    echo -e "${RED}  Download from: https://github.com/love2d/love/releases${NC}"
fi

# ============================================
# MACOS BUILD
# ============================================
echo -e "\n${BLUE}Building for macOS...${NC}"
MACOS_DIR="$DIST_DIR/macos"
mkdir -p "$MACOS_DIR"

if [ -d "love-binaries/macos/love.app" ]; then
    # Copy the LÖVE.app bundle
    cp -r "love-binaries/macos/love.app" "$MACOS_DIR/${GAME_NAME}.app"

    # Copy .love file into the app bundle
    mkdir -p "$MACOS_DIR/${GAME_NAME}.app/Contents/Resources"
    cp "$LOVE_FILE" "$MACOS_DIR/${GAME_NAME}.app/Contents/Resources/${GAME_NAME}.love"

    # Update Info.plist (only if PlistBuddy is available - macOS only)
    PLIST="$MACOS_DIR/${GAME_NAME}.app/Contents/Info.plist"
    if command -v /usr/libexec/PlistBuddy &> /dev/null; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleName $GAME_NAME" "$PLIST" 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :CFBundleName string $GAME_NAME" "$PLIST"
        /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.rodneygauna.astromoments" "$PLIST" 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.rodneygauna.astromoments" "$PLIST"
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $GAME_VERSION" "$PLIST" 2>/dev/null || \
            /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $GAME_VERSION" "$PLIST"
    else
        echo -e "${YELLOW}  Note: PlistBuddy not available (macOS tool) - Info.plist not updated${NC}"
    fi

    echo -e "${GREEN}✓ macOS build complete${NC}"
else
    echo -e "${RED}⚠ macOS LÖVE binaries not found in love-binaries/macos${NC}"
    echo -e "${RED}  Download from: https://github.com/love2d/love/releases${NC}"
fi

# ============================================
# LINUX BUILD (AppImage)
# ============================================
echo -e "\n${BLUE}Building for Linux (AppImage)...${NC}"
LINUX_DIR="$DIST_DIR/linux"
mkdir -p "$LINUX_DIR"

if command -v appimagetool &> /dev/null && [ -d "love-binaries/linux" ]; then
    APPDIR="$BUILD_DIR/${GAME_NAME}.AppDir"
    mkdir -p "$APPDIR/usr/bin"
    mkdir -p "$APPDIR/usr/lib"
    mkdir -p "$APPDIR/usr/share/applications"
    mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

    # Copy LÖVE binaries
    cp -r love-binaries/linux/* "$APPDIR/usr/"

    # Copy the .love file
    cp "$LOVE_FILE" "$APPDIR/usr/share/${GAME_NAME}.love"

    # Create desktop entry
    cat > "$APPDIR/usr/share/applications/${GAME_NAME}.desktop" << EOF
[Desktop Entry]
Name=$GAME_NAME
Exec=love ${GAME_NAME}.love
Icon=${GAME_NAME}
Type=Application
Categories=Game;
EOF

    # Create AppRun script
    cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/love" "${HERE}/usr/share/AstroMoments.love" "$@"
EOF
    chmod +x "$APPDIR/AppRun"

    # Create AppImage
    appimagetool "$APPDIR" "$LINUX_DIR/${GAME_NAME}-${GAME_VERSION}-x86_64.AppImage"

    echo -e "${GREEN}✓ Linux AppImage build complete${NC}"
else
    echo -e "${RED}⚠ appimagetool not found or Linux LÖVE binaries missing${NC}"
    echo -e "${RED}  Install appimagetool: https://appimage.github.io/appimagetool/${NC}"
    echo -e "${RED}  Or just distribute the .love file for Linux users${NC}"

    # As fallback, just copy the .love file
    cp "$LOVE_FILE" "$LINUX_DIR/"
    echo -e "${GREEN}✓ Created .love file for Linux${NC}"
fi

# ============================================
# CREATE ARCHIVES
# ============================================
echo -e "\n${GREEN}[4/5] Creating distribution archives...${NC}"

cd "$DIST_DIR"

if [ -d "windows" ]; then
    echo "Creating Windows ZIP..."
    zip -r "${GAME_NAME}-${GAME_VERSION}-Windows.zip" windows/ -q
    echo -e "${GREEN}✓ Created Windows archive${NC}"
fi

if [ -d "macos" ]; then
    echo "Creating macOS ZIP..."
    zip -r "${GAME_NAME}-${GAME_VERSION}-macOS.zip" macos/ -q
    echo -e "${GREEN}✓ Created macOS archive${NC}"
fi

if [ -d "linux" ]; then
    echo "Creating Linux archive..."
    tar -czf "${GAME_NAME}-${GAME_VERSION}-Linux.tar.gz" linux/
    echo -e "${GREEN}✓ Created Linux archive${NC}"
fi

cd ..

# ============================================
# SUMMARY
# ============================================
echo -e "\n${GREEN}[5/5] Build Summary${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "Build complete! Distributions created in: ${GREEN}$DIST_DIR${NC}"
echo ""
echo "Archives created:"
ls -lh "$DIST_DIR"/*.{zip,tar.gz} 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo -e "${BLUE}================================================${NC}"
echo ""
echo "To test your .love file directly:"
echo "  love $LOVE_FILE"
echo ""
echo -e "${BLUE}Note:${NC} Make sure to download LÖVE binaries for each platform"
echo "      and place them in the love-binaries/ directory:"
echo "      - love-binaries/windows/"
echo "      - love-binaries/macos/love.app"
echo "      - love-binaries/linux/"
echo ""
echo "Download LÖVE binaries from:"
echo "  https://github.com/love2d/love/releases"
