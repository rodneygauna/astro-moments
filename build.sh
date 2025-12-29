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

    # Setup Linux binaries (extract from system LÖVE if available)
    if [ ! -d "linux/bin" ] || [ ! -f "linux/bin/love" ]; then
        echo -e "${BLUE}Setting up Linux binaries...${NC}"

        # Check if LÖVE is installed on the system
        if command -v love &> /dev/null; then
            echo -e "${BLUE}Found LÖVE installed on system, extracting binaries...${NC}"
            mkdir -p linux/{bin,lib,share}

            # Find the LÖVE executable
            LOVE_PATH=$(which love)

            # If it's a symbolic link, follow it
            if [ -L "$LOVE_PATH" ]; then
                LOVE_PATH=$(readlink -f "$LOVE_PATH")
            fi

            # Copy the love binary
            cp "$LOVE_PATH" linux/bin/love
            chmod +x linux/bin/love

            # Try to find and copy required shared libraries
            # This uses ldd to find dependencies
            echo -e "${BLUE}Copying required libraries...${NC}"
            mkdir -p linux/lib

            # Get library dependencies and copy them
            ldd "$LOVE_PATH" 2>/dev/null | grep "=> /" | awk '{print $3}' | while read lib; do
                if [ -f "$lib" ]; then
                    # Only copy libraries that aren't standard system libraries
                    case "$lib" in
                        /lib/x86_64-linux-gnu/*|/usr/lib/x86_64-linux-gnu/*)
                            # Skip standard system libraries, they should be on target systems
                            ;;
                        *)
                            cp "$lib" linux/lib/ 2>/dev/null || true
                            ;;
                    esac
                fi
            done

            # Create a minimal share directory structure
            mkdir -p linux/share/applications

            echo -e "${GREEN}✓ Linux binaries extracted from system LÖVE${NC}"
        else
            echo -e "${YELLOW}LÖVE not found on system${NC}"
            echo -e "${YELLOW}Options:${NC}"
            echo -e "${YELLOW}  1. Install LÖVE: sudo apt install love (Debian/Ubuntu)${NC}"
            echo -e "${YELLOW}  2. Download and extract LÖVE AppImage to love-binaries/linux/${NC}"
            echo -e "${YELLOW}  3. Just distribute the .love file for Linux users${NC}"
            mkdir -p linux
            touch linux/.placeholder
            echo -e "${GREEN}✓ Linux distribution ready (.love file only)${NC}"
        fi
    else
        echo -e "${GREEN}✓ Linux binaries found${NC}"
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

# Copy .love file to dist directory for standalone distribution
cp "$LOVE_FILE" "$DIST_DIR/"

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

# Check if we have actual LÖVE binaries (not just placeholder)
HAS_LINUX_BINARIES=false
if [ -d "love-binaries/linux" ] && [ -d "love-binaries/linux/bin" ]; then
    HAS_LINUX_BINARIES=true
fi

if command -v appimagetool &> /dev/null && [ "$HAS_LINUX_BINARIES" = true ]; then
    APPDIR="$BUILD_DIR/${GAME_NAME}.AppDir"
    mkdir -p "$APPDIR/usr/bin"
    mkdir -p "$APPDIR/usr/lib"
    mkdir -p "$APPDIR/usr/share/applications"
    mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

    # Copy LÖVE binaries
    cp -r love-binaries/linux/* "$APPDIR/usr/"

    # Copy the .love file
    cp "$LOVE_FILE" "$APPDIR/usr/share/${GAME_NAME}.love"

    # Copy icon if available (use spaceship sprite as icon)
    if [ -f "sprites/ships/Spaceship.png" ]; then
        cp "sprites/ships/Spaceship.png" "$APPDIR/${GAME_NAME}.png"
        cp "sprites/ships/Spaceship.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/${GAME_NAME}.png"
    fi

    # Create desktop entry (needs to be in root of AppDir for appimagetool)
    cat > "$APPDIR/${GAME_NAME}.desktop" << EOF
[Desktop Entry]
Name=$GAME_NAME
Exec=love ${GAME_NAME}.love
Icon=${GAME_NAME}
Type=Application
Categories=Game;
EOF

    # Also copy to standard location
    cp "$APPDIR/${GAME_NAME}.desktop" "$APPDIR/usr/share/applications/${GAME_NAME}.desktop"

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

    # Create AppImage (set architecture explicitly)
    ARCH=x86_64 appimagetool "$APPDIR" "$LINUX_DIR/${GAME_NAME}-${GAME_VERSION}-x86_64.AppImage"

    echo -e "${GREEN}✓ Linux AppImage build complete${NC}"
else
    if [ "$HAS_LINUX_BINARIES" = false ]; then
        echo -e "${YELLOW}⚠ Linux LÖVE binaries not found in love-binaries/linux${NC}"
        echo -e "${YELLOW}  To create an AppImage, you need to:${NC}"
        echo -e "${YELLOW}  1. Download LÖVE Linux binaries or compile from source${NC}"
        echo -e "${YELLOW}  2. Extract them to love-binaries/linux/ (should include bin/, lib/, share/ directories)${NC}"
        echo -e "${YELLOW}  3. Install appimagetool if not already installed${NC}"
    elif ! command -v appimagetool &> /dev/null; then
        echo -e "${YELLOW}⚠ appimagetool not found${NC}"
        echo -e "${YELLOW}  Install appimagetool: https://appimage.github.io/appimagetool/${NC}"
    fi

    echo -e "${YELLOW}  Falling back to .love file distribution for Linux${NC}"
    echo -e "${YELLOW}  Linux users can run: love ${GAME_NAME}.love${NC}"

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
echo "Standalone .love file:"
ls -lh "$DIST_DIR"/*.love 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "Platform archives:"
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
