# Scripts Directory

This directory contains helper scripts for building and releasing the Eye Reminder app.

## Available Scripts

### 🚀 release.sh

**Automated release script** - Creates a new release with GitHub Actions.

```bash
./scripts/release.sh
```

Or specify version directly:

```bash
./scripts/release.sh v1.0.0
```

**What it does:**
- ✅ Validates version format
- ✅ Checks for uncommitted changes
- ✅ Syncs with remote branch
- ✅ Tests build locally (optional)
- ✅ Creates and pushes git tag
- ✅ Triggers GitHub Actions workflow
- ✅ Provides links to monitor progress

**Usage:**
1. Make sure all changes are committed
2. Run the script
3. Follow the interactive prompts
4. Monitor the build on GitHub Actions

---

### 🔨 test-build.sh

**Local build test** - Quickly test if the app builds successfully.

```bash
./scripts/test-build.sh
```

**What it does:**
- ✅ Cleans previous builds
- ✅ Builds the app in Release configuration
- ✅ Verifies the build output
- ✅ Shows app size and location

**When to use:**
- Before creating a release
- After making code changes
- To verify the build environment

---

### 📦 create-dmg.sh

**DMG creator** - Creates a DMG installer from a built app.

```bash
./scripts/create-dmg.sh [version]
```

**Examples:**

```bash
# Create DMG with version 1.0.0
./scripts/create-dmg.sh 1.0.0

# Without version (defaults to 1.0.0)
./scripts/create-dmg.sh
```

**What it does:**
- ✅ Creates a DMG installer
- ✅ Includes Applications folder shortcut
- ✅ Sets volume name
- ✅ Compresses for distribution

**Prerequisites:**
- App must be built first (run `test-build.sh`)

**Output:**
- File: `dist/HealthyWork-vX.X.X.dmg`

---

## Quick Workflow

### For Development

```bash
# 1. Test build
./scripts/test-build.sh

# 2. Make changes to code
# ... edit files ...

# 3. Test again
./scripts/test-build.sh
```

### For Release

```bash
# 1. Test build locally
./scripts/test-build.sh

# 2. Create release (automated)
./scripts/release.sh v1.0.0

# 3. Monitor on GitHub
# GitHub Actions will build and create release automatically
```

### For Manual Distribution

```bash
# 1. Build app
./scripts/test-build.sh

# 2. Create DMG
./scripts/create-dmg.sh 1.0.0

# 3. Distribute
# Share the dist/HealthyWork-v1.0.0.dmg file
```

---

## Script Requirements

All scripts require:
- **macOS** - Scripts are designed for macOS
- **Xcode** - With command line tools installed
- **Git** - For version control operations
- **Bash** - Shell scripting (pre-installed on macOS)

---

## Making Scripts Executable

If a script isn't executable, run:

```bash
chmod +x scripts/*.sh
```

---

## Troubleshooting

### Permission Denied

```bash
chmod +x scripts/script-name.sh
./scripts/script-name.sh
```

### Command Not Found

Make sure you're in the project root:

```bash
cd /Users/dungne/SourceCode/health-reminder
./scripts/script-name.sh
```

### Build Fails

1. Open Xcode and try building manually
2. Check for errors in the project
3. Make sure you have the latest Xcode version
4. Try cleaning: Product → Clean Build Folder (⌘⇧K)

---

## Creating Custom Scripts

You can add your own scripts to this directory. Template:

```bash
#!/bin/bash
set -e  # Exit on error

# Your script here
echo "Hello from custom script"

# Example: Build and open app
cd HealthyWork
xcodebuild -project HealthyWork.xcodeproj -scheme HealthyWork build
open build/Build/Products/Debug/HealthyWork.app
```

Make it executable:

```bash
chmod +x scripts/my-script.sh
```

---

## Environment Variables

Scripts automatically detect:
- `PWD` - Current directory
- `USER` - Current user
- `HOME` - User home directory

You can set custom variables:

```bash
# Custom build configuration
export BUILD_CONFIG=Debug
./scripts/test-build.sh

# Custom output directory
export OUTPUT_DIR=~/Desktop/builds
./scripts/create-dmg.sh
```

---

## CI/CD Integration

These scripts work alongside GitHub Actions:

| Action | Local Script | GitHub Actions |
|--------|-------------|----------------|
| Build | `test-build.sh` | `build.yml` |
| Release | `release.sh` | `release.yml` |
| PR Check | `test-build.sh` | `pr-check.yml` |

---

## Support

For more information, see:
- `RELEASE.md` - Release process guide
- `GITHUB_ACTIONS_SETUP.md` - GitHub Actions documentation
- `README.md` - Project overview

---

**Happy scripting! 🚀**
