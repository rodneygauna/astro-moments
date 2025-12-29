#!/bin/bash
# Release script for Astro Moments
# Creates a GitHub release and uploads distribution packages

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Extract version from version.lua
GAME_VERSION=$(grep 'Version.current = ' version.lua | sed 's/.*"\(.*\)".*/\1/')
TAG="v${GAME_VERSION}"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Astro Moments - Release Script${NC}"
echo -e "${BLUE}  Version: ${GAME_VERSION}${NC}"
echo -e "${BLUE}================================================${NC}"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo -e "${YELLOW}Install from: https://cli.github.com/${NC}"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
    echo -e "${YELLOW}Run: gh auth login${NC}"
    exit 1
fi

# Check if distribution files exist
DIST_DIR="dist"
if [ ! -d "$DIST_DIR" ]; then
    echo -e "${RED}Error: dist/ directory not found${NC}"
    echo -e "${YELLOW}Run ./build.sh first to create distribution packages${NC}"
    exit 1
fi

WINDOWS_ZIP="${DIST_DIR}/AstroMoments-${GAME_VERSION}-Windows.zip"
MACOS_ZIP="${DIST_DIR}/AstroMoments-${GAME_VERSION}-macOS.zip"
LINUX_TAR="${DIST_DIR}/AstroMoments-${GAME_VERSION}-Linux.tar.gz"
LOVE_FILE="${DIST_DIR}/AstroMoments.love"

if [ ! -f "$WINDOWS_ZIP" ] || [ ! -f "$MACOS_ZIP" ] || [ ! -f "$LINUX_TAR" ] || [ ! -f "$LOVE_FILE" ]; then
    echo -e "${RED}Error: Distribution files not found${NC}"
    echo -e "${YELLOW}Expected files:${NC}"
    echo -e "  - $WINDOWS_ZIP"
    echo -e "  - $MACOS_ZIP"
    echo -e "  - $LINUX_TAR"
    echo -e "  - $LOVE_FILE"
    echo -e "${YELLOW}Run ./build.sh first${NC}"
    exit 1
fi

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo -e "${YELLOW}Tag $TAG already exists${NC}"
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Deleting local tag...${NC}"
        git tag -d "$TAG"
        echo -e "${BLUE}Deleting remote tag...${NC}"
        git push origin ":refs/tags/$TAG" 2>/dev/null || true
    else
        echo -e "${RED}Aborted${NC}"
        exit 1
    fi
fi

# Create and push git tag
echo -e "\n${BLUE}Creating git tag: $TAG${NC}"
git tag -a "$TAG" -m "Release $GAME_VERSION"

echo -e "${BLUE}Pushing tag to GitHub...${NC}"
git push origin "$TAG"

# Get previous version tag for comparison
PREV_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")

# Parse changelog from version.lua
echo -e "\n${BLUE}================================================${NC}"
echo -e "${BLUE}Release Information${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "Current Version: ${GREEN}${GAME_VERSION}${NC}"
if [ -n "$PREV_TAG" ]; then
    echo -e "Previous Version: ${YELLOW}${PREV_TAG}${NC}"
fi
echo -e "\nFiles to be released:"
echo -e "  - Windows: $(basename "$WINDOWS_ZIP")"
echo -e "  - macOS: $(basename "$MACOS_ZIP")"
echo -e "  - Linux: $(basename "$LINUX_TAR")"
echo -e "  - Universal: $(basename "$LOVE_FILE")"
echo -e "${BLUE}================================================${NC}"

# Extract changelog from version.lua using awk
echo -e "\n${BLUE}Extracting changelog from version.lua...${NC}"

# Parse the changelog entry for current version
parse_changelog() {
    awk -v version="$GAME_VERSION" '
    BEGIN {
        in_version = 0
        in_changes = 0
        section = ""
        in_array = 0
    }
    /version = "/ {
        if ($0 ~ version) {
            in_version = 1
        }
    }
    in_version && /date = "/ {
        gsub(/.*date = "/, "")
        gsub(/".*/, "")
        print "DATE:" $0
    }
    in_version && /highlights = {/ {
        section = "highlights"
        in_array = 1
        # Extract inline content
        line = $0
        while (match(line, /"[^"]+"/)) {
            text = substr(line, RSTART+1, RLENGTH-2)
            print section ":" text
            line = substr(line, RSTART+RLENGTH)
        }
        next
    }
    in_version && /changes = {/ {
        in_changes = 1
        next
    }
    in_changes && /added = {/ {
        section = "added"
        in_array = 1
        # Extract inline content
        line = $0
        while (match(line, /"[^"]+"/)) {
            text = substr(line, RSTART+1, RLENGTH-2)
            print section ":" text
            line = substr(line, RSTART+RLENGTH)
        }
        next
    }
    in_changes && /fixed = {/ {
        section = "fixed"
        in_array = 1
        next
    }
    in_changes && /changed = {/ {
        section = "changed"
        in_array = 1
        next
    }
    in_changes && /upcoming = {/ {
        section = "upcoming"
        in_array = 1
        next
    }
    in_array && /"/ {
        # Extract all quoted strings from the line
        line = $0
        while (match(line, /"[^"]+"/)) {
            text = substr(line, RSTART+1, RLENGTH-2)
            if (text != "") {
                print section ":" text
            }
            line = substr(line, RSTART+RLENGTH)
        }
    }
    in_array && /}/ {
        if ($0 ~ /^[[:space:]]*}[[:space:]]*$/ || $0 ~ /^[[:space:]]*}[[:space:]]*,/) {
            in_array = 0
            if (section == "upcoming") {
                in_changes = 0
                in_version = 0
                exit
            }
            section = ""
        }
    }
    ' version.lua
}

# Get parsed changelog data
CHANGELOG_DATA=$(parse_changelog)

if [ -z "$CHANGELOG_DATA" ]; then
    echo -e "${YELLOW}Warning: Could not find changelog for version ${GAME_VERSION} in version.lua${NC}"
    echo -e "${YELLOW}Using default release notes template${NC}"
fi

# Build structured release notes from parsed data
HIGHLIGHTS=""
ADDED=""
FIXED=""
CHANGED=""
UPCOMING=""
RELEASE_DATE=""

while IFS=: read -r key value; do
    case $key in
        DATE)
            RELEASE_DATE="$value"
            ;;
        highlights)
            HIGHLIGHTS="${HIGHLIGHTS}- ${value}\n"
            ;;
        added)
            ADDED="${ADDED}- ${value}\n"
            ;;
        fixed)
            FIXED="${FIXED}- ${value}\n"
            ;;
        changed)
            CHANGED="${CHANGED}- ${value}\n"
            ;;
        upcoming)
            UPCOMING="${UPCOMING}- ${value}\n"
            ;;
    esac
done <<< "$CHANGELOG_DATA"

# Display parsed changelog
if [ -n "$CHANGELOG_DATA" ]; then
    echo -e "${GREEN}✓ Found changelog entry for ${GAME_VERSION}${NC}"
    if [ -n "$RELEASE_DATE" ]; then
        echo -e "  Release Date: ${RELEASE_DATE}"
    fi
    [ -n "$HIGHLIGHTS" ] && echo -e "  Highlights: $(echo -e "$HIGHLIGHTS" | wc -l | tr -d ' ') items"
    [ -n "$ADDED" ] && echo -e "  Added: $(echo -e "$ADDED" | wc -l | tr -d ' ') items"
    [ -n "$FIXED" ] && echo -e "  Fixed: $(echo -e "$FIXED" | wc -l | tr -d ' ') items"
    [ -n "$CHANGED" ] && echo -e "  Changed: $(echo -e "$CHANGED" | wc -l | tr -d ' ') items"
    [ -n "$UPCOMING" ] && echo -e "  Upcoming: $(echo -e "$UPCOMING" | wc -l | tr -d ' ') items"
fi

# Build release notes
RELEASE_NOTES="## Astro Moments ${GAME_VERSION}"

if [ -n "$RELEASE_DATE" ]; then
    RELEASE_NOTES="${RELEASE_NOTES}
_Released on ${RELEASE_DATE}_"
fi

RELEASE_NOTES="${RELEASE_NOTES}

### Downloads
- **Windows**: Download and extract the Windows ZIP, then run \`AstroMoments.exe\`
- **macOS**: Download and extract the macOS ZIP, then run \`AstroMoments.app\`
- **Linux**: Extract the Linux TAR.GZ and run with LÖVE
- **Universal**: If you have LÖVE installed, download and run \`AstroMoments.love\`
"

# Add sections from version.lua
if [ -n "$HIGHLIGHTS" ]; then
    RELEASE_NOTES="${RELEASE_NOTES}
### Highlights
$(echo -e "$HIGHLIGHTS")"
fi

if [ -n "$ADDED" ]; then
    RELEASE_NOTES="${RELEASE_NOTES}
### Added
$(echo -e "$ADDED")"
fi

if [ -n "$FIXED" ]; then
    RELEASE_NOTES="${RELEASE_NOTES}
### Fixed
$(echo -e "$FIXED")"
fi

if [ -n "$CHANGED" ]; then
    RELEASE_NOTES="${RELEASE_NOTES}
### Changed
$(echo -e "$CHANGED")"
fi

if [ -n "$UPCOMING" ]; then
    RELEASE_NOTES="${RELEASE_NOTES}
### Coming Soon
$(echo -e "$UPCOMING")"
fi

# Fallback if no changelog found
if [ -z "$HIGHLIGHTS" ] && [ -z "$ADDED" ] && [ -z "$FIXED" ] && [ -z "$CHANGED" ]; then
    RELEASE_NOTES="${RELEASE_NOTES}
### Changes
Release ${GAME_VERSION}"
fi

# Allow user to review and optionally edit
echo -e "\n${BLUE}================================================${NC}"
echo -e "${BLUE}Generated Release Notes Preview:${NC}"
echo -e "${BLUE}================================================${NC}"
echo "$RELEASE_NOTES"
echo -e "${BLUE}================================================${NC}"
echo -e "\n${YELLOW}Use these release notes? (y/n):${NC}"
read -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Enter custom release notes (press Ctrl+D when done):${NC}"
    RELEASE_NOTES=$(cat)
    if [ -z "$RELEASE_NOTES" ]; then
        RELEASE_NOTES="Release ${GAME_VERSION}"
    fi
fi

# Create GitHub release with files
echo -e "\n${BLUE}Creating GitHub release...${NC}"
gh release create "$TAG" \
    "$WINDOWS_ZIP" \
    "$MACOS_ZIP" \
    "$LINUX_TAR" \
    "$LOVE_FILE" \
    --title "Astro Moments $TAG" \
    --notes "$RELEASE_NOTES"

echo -e "\n${GREEN}✓ Release created successfully!${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "View release at:"
echo -e "${GREEN}https://github.com/rodneygauna/astro-moments/releases/tag/$TAG${NC}"
echo -e "${BLUE}================================================${NC}"
