# Quick Start Guide

Follow these steps to build and install Mesa with GPU acceleration for your Ubuntu-Chroot.

## Step 1: Initialize Repository

```bash
cd mesa-panfrost-build

# Initialize git repository
git init
git add .
git commit -m "Initial: Mesa Panfrost build workflow"

# Create GitHub repository (do this on GitHub.com or use gh)
gh repo create mesa-panfrost-build --public --source=.

# Or if repo already exists:
git remote add origin https://github.com/YOUR_USERNAME/mesa-panfrost-build.git
git branch -M main
git push -u origin main
```

## Step 2: Push to GitHub

```bash
git remote set-url origin https://github.com/YOUR_USERNAME/mesa-panfrost-build.git
git push -u origin main
```

## Step 3: Trigger Build

### Option A: Interactive (Recommended)

```bash
cd mesa-panfrost-build
gh workflow run build-mesa-panfrost.yml
# Follow prompts to configure build
```

### Option B: With Specific Parameters

```bash
# Build with default settings (Mali-DP enabled, O3 optimization)
gh workflow run build-mesa-panfrost.yml

# Build with custom version
gh workflow run build-mesa-panfrost.yml -f mesa_version=25.3.2

# Build with balanced optimization
gh workflow run build-mesa-panfrost.yml -f optimize_level=2

# Build only Mali-DP (faster, less testing)
gh workflow run build-mesa-panfrost.yml -f enable_panfrost=false

# Build only Panfrost (if you have DRM/KMS kernel)
gh workflow run build-mesa-panfrost.yml -f enable_mali_dp=false
```

### Option C: Monitor Progress

```bash
# Watch workflow run
gh run watch

# Or list recent runs
gh run list

# View specific run details
gh run view <run-id>
```

## Step 4: Download Artifacts

```bash
# Download latest artifacts
gh run download <run-id> -n mesa-26.0.0-ubuntu24.04-aarch64

# Or download from web UI:
# 1. Go to https://github.com/YOUR_USERNAME/mesa-panfrost-build/actions
# 2. Click on the workflow run
# 3. Scroll to "Artifacts" section
# 4. Download mesa-26.0.0-ubuntu24.04-aarch64.zip
```

## Step 5: Install in Ubuntu-Chroot

### Method A: Install on Android (recommended)

```bash
# Transfer artifact to device
adb push mesa-26.0.0-ubuntu24.04-aarch64.tar.gz /data/local/tmp/

# Enter Ubuntu chroot
su -c "chroot /data/local/ubuntu /bin/bash"

# Extract in chroot
cd /tmp
tar -xzf mesa-26.0.0-ubuntu24.04-aarch64.tar.gz

# Run installation script
./install-mesa.sh mesa-26.0.0-ubuntu24.04-aarch64.tar.gz

# For Mali-DP (recommended for Exynos 9810):
./install-mesa.sh mesa-26.0.0-ubuntu24.04-aarch64.tar.gz mali_dp
```

### Method B: Install directly in chroot

```bash
# Already in chroot
cd /path/to/artifacts

# Extract and install
tar -xzf mesa-26.0.0-ubuntu24.04-aarch64.tar.gz
./install-mesa.sh mesa-26.0.0-ubuntu24.04-aarch64.tar.gz mali_dp
```

## Step 6: Verify Installation

```bash
# In chroot, export display
export DISPLAY=:1

# Run verification script
./verify.sh

# Or manual check
glxinfo | grep "OpenGL renderer"

# Expected output (Mali-DP):
#   OpenGL renderer string: Mali G72 (r38p0)

# Expected output (Panfrost - if you have DRM/KMS):
#   OpenGL renderer string: Panfrost Mali G72
```

## Step 7: Test Performance

```bash
# Run glmark2 benchmark
glmark2 --benchmark all --duration 10

# Check improvement vs llvmpipe:
# - llvmpipe: ~100-200 FPS
# - Mali-DP: ~250-400 FPS (2-4x improvement)
# - Panfrost (DRM): ~500-1000 FPS (5-10x improvement)
```

## Step 8: Reboot and Enjoy

```bash
# Exit chroot
exit

# Reboot device
adb reboot
```

## Troubleshooting

### Build Fails

```bash
# Check workflow logs
gh run view <run-id> --log

# Or view in browser
gh browse --repo YOUR_USERNAME/mesa-panfrost-build
```

### Installation Fails

```bash
# Check if /dev/mali0 exists
ls -la /dev/mali0

# Check backup directory
ls -la /tmp/mesa-backup

# Restore backup if needed
cp /tmp/mesa-backup/* /usr/lib/aarch64-linux-gnu/
ldconfig
```

### Still Using llvmpipe

```bash
# Check environment variables
cat /etc/environment.d/mesa-driver.conf

# Should contain:
# export MESA_LOADER_DRIVER_OVERRIDE=mali_dp

# Reload environment
source /etc/environment
```

## Success Indicators

✅ **Build Success**: Workflow completes, artifacts uploaded
✅ **Installation Success**: No errors, backup created
✅ **Driver Loaded**: `glxinfo` shows Mali/Panfrost (not llvmpipe)
✅ **Performance Gain**: 2-10x FPS improvement in glmark2

## Next Steps

1. **Test Desktop Environment**: Launch XFCE/GNOME and verify smoothness
2. **Run Applications**: Test GPU-accelerated apps (games, video, 3D)
3. **Monitor Performance**: Watch for thermal throttling or crashes
4. **Tune Settings**: Adjust optimization level if needed

## Support

- Full README: [README.md](README.md)
- Workflow file: [.github/workflows/build-mesa-panfrost.yml](.github/workflows/build-mesa-panfrost.yml)
- Installation script: [scripts/install-mesa.sh](scripts/install-mesa.sh)
- Verification script: [scripts/verify.sh](scripts/verify.sh)

---

**Estimated Build Time**: 2-4 hours (first build), 1-2 hours (with caching)
**Artifact Size**: ~500-800 MB
**Storage Required**: ~1 GB in chroot during installation