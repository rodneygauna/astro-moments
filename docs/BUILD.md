# Building Astro Moments

This guide explains how to create distribution packages for Windows, macOS, and Linux.

## Prerequisites

1. **LÖVE2D Binaries**: Download LÖVE 11.5 (or your target version) binaries for each platform:
   - [LÖVE Releases on GitHub](https://github.com/love2d/love/releases)

2. **Directory Structure**: Create a `love-binaries` directory with the following structure:

```text
love-binaries/
├── windows/
│   ├── love.exe
│   ├── SDL2.dll
│   ├── OpenAL32.dll
│   ├── lua51.dll
│   ├── mpg123.dll
│   ├── msvcp120.dll
│   ├── msvcr120.dll
│   └── license.txt
├── macos/
│   └── love.app/
└── linux/
    ├── bin/
    ├── lib/
    └── share/
```

3. **Linux Requirements** (optional, for AppImage):
   - Install `appimagetool`:

```bash
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
```

## Quick Start

1. **Download LÖVE Binaries**:

```bash
mkdir -p love-binaries/{windows,macos,linux}
# Extract downloaded LÖVE binaries into respective folders
```

2. **Make the build script executable**:

```bash
chmod +x build.sh
```

3. **Run the build script**:

```bash
./build.sh
```

4. **Find your builds** in the `dist/` directory:
   - `AstroMoments-1.0.0-Windows.zip`
   - `AstroMoments-1.0.0-macOS.zip`
   - `AstroMoments-1.0.0-Linux.tar.gz`

## What the Script Does

1. **Creates a .love file**: Packages your game into a ZIP archive
2. **Windows**: Concatenates the .love file with love.exe
3. **macOS**: Embeds the .love file into the LÖVE.app bundle
4. **Linux**: Creates an AppImage (or provides the .love file as fallback)
5. **Archives**: Creates distribution-ready ZIP/TAR files

## Manual Testing

To test the .love file directly (works on any platform with LÖVE installed):

```bash
love builds/AstroMoments.love
```

## Distribution Options

### Easy Distribution (Cross-Platform)

Just distribute the `.love` file! Users with LÖVE installed can run it directly:

```bash
love AstroMoments.love
```

### Platform-Specific Executables

Use the build script to create standalone executables for users without LÖVE.

## File Exclusions

The build script automatically excludes:

- `.git` directory and files
- `docs/` documentation
- `sprites/asepriteFiles/` (source art files)
- Development files (`.md`, `.vscode`, etc.)
- Previous `builds/` and `dist/` directories

## Customization

Edit `build.sh` to change:

- `GAME_NAME`: Your game's name
- `GAME_VERSION`: Version number
- `LOVE_VERSION`: Target LÖVE version
- File exclusions in the `rsync` command

## Troubleshooting

**Problem**: "Windows/macOS/Linux binaries not found"

- **Solution**: Download LÖVE binaries and extract them to the correct directories

**Problem**: "appimagetool not found"

- **Solution**: Install appimagetool or just distribute the .love file for Linux

**Problem**: macOS build fails with PlistBuddy errors

- **Solution**: This is normal on non-macOS systems. Build macOS version on a Mac

**Problem**: Build script not executable

- **Solution**: Run `chmod +x build.sh`

## Additional Resources

- [LÖVE2D Game Distribution Guide](https://love2d.org/wiki/Game_Distribution)
- [LÖVE2D Downloads](https://love2d.org/)
- [Creating AppImages](https://appimage.github.io/)

## Notes

- The `.love` file is just a ZIP archive - users can open it to see the source code
- Consider adding an icon for each platform (update the build script accordingly)
- Test each build on its target platform before releasing
- The build script uses `-9` compression for the .love file (maximum compression)
