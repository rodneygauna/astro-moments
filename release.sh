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

if [ ! -f "$WINDOWS_ZIP" ] || [ ! -f "$MACOS_ZIP" ] || [ ! -f "$LINUX_TAR" ]; then
    echo -e "${RED}Error: Distribution files not found${NC}"
    echo -e "${YELLOW}Expected files:${NC}"
    echo -e "  - $WINDOWS_ZIP"
    echo -e "  - $MACOS_ZIP"
    echo -e "  - $LINUX_TAR"
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

# Prompt for release notes
echo -e "\n${YELLOW}Enter release notes (press Ctrl+D when done):${NC}"
RELEASE_NOTES=$(cat)

if [ -z "$RELEASE_NOTES" ]; then
    RELEASE_NOTES="Release ${GAME_VERSION}"
fi

# Create GitHub release with files
echo -e "\n${BLUE}Creating GitHub release...${NC}"
gh release create "$TAG" \
    "$WINDOWS_ZIP" \
    "$MACOS_ZIP" \
    "$LINUX_TAR" \
    --title "Astro Moments $TAG" \
    --notes "$RELEASE_NOTES"

echo -e "\n${GREEN}✓ Release created successfully!${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "View release at:"
echo -e "${GREEN}https://github.com/rodneygauna/astro-moments/releases/tag/$TAG${NC}"
echo -e "${BLUE}================================================${NC}"
