# Mesa Panfrost Build for ARM64 (Mali-G72)

This repository provides automated GitHub Actions workflows to build Mesa 3D library with Panfrost and Mali-DP drivers for ARM64 architecture, specifically optimized for Mali-G72 GPUs (Samsung Exynos 9810 and similar).

## Features

- **Automated GitHub Actions build** using QEMU ARM64 emulation
- **Multiple driver support**: Panfrost (DRM/KMS), Mali-DP (legacy), PanVK (Vulkan)
- **Ubuntu 24.04 ARM64 compatibility** - Perfect match for Ubuntu-Chroot environments
- **Configurable optimization** - Choose between balanced (O2) and maximum (O3) performance
- **Auto-detection** - Installation script automatically detects available GPU device
- **Safety rollback** - Backup and restore capability for failed installations
- **Verification scripts** - Built-in GPU acceleration testing

## Quick Start

### 1. Create GitHub Repository

```bash
# Initialize repository
git init
git add .
git commit -m "Initial commit: Mesa Panfrost build workflow"

# Add remote (replace YOUR_USERNAME and YOUR_REPO_NAME)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

### 2. Trigger Build

**Option A: via GitHub CLI (Recommended)**

```bash
# Interactive - gh will prompt for options
gh workflow run build-mesa-panfrost.yml

# Or with specific parameters
gh workflow run build-mesa-panfrost.yml -f mesa_version=26.0.0 -f enable_panfrost=true -f optimize_level=3
```

**Option B: via GitHub Web UI**

1. Go to repository → Actions tab
2. Select "Build Mesa with Panfrost for ARM64"
3. Click "Run workflow"
4. Configure inputs as needed
5. Click "Run workflow"

**Option C: Automatic on Push**

The workflow automatically runs when you push to `main` or `master` branches.

### 3. Download and Install

```bash
# Once workflow completes, download artifacts
# Go to Actions tab → Select workflow run → Scroll to "Artifacts" section

# Or download via gh CLI
gh run download <run-id>

# Extract and install
tar -xzf mesa-26.0.0-ubuntu24.04-aarch64.tar.gz

# Run installation script (auto-detects driver)
./install-mesa.sh mesa-26.0.0-ubuntu24.04-aarch64.tar.gz

# Or manually specify driver
./install-mesa.sh mesa-26.0.0-ubuntu24.04-aarch64.tar.gz panfrost  # For DRM/KMS
./install-mesa.sh mesa-26.0.0-ubuntu24.04-aarch64.tar.gz mali_dp  # For legacy Mali
```

## Workflow Inputs

| Input | Description | Default | Options |
|--------|-------------|----------|----------|
| `mesa_version` | Mesa version to build | `26.0.0` | e.g., `26.0.0`, `25.3.4` |
| `enable_panfrost` | Build Panfrost driver (requires DRM/KMS) | `true` | `true`, `false` |
| `enable_mali_dp` | Build Mali-DP driver (legacy /dev/mali0) | `true` | `true`, `false` |
| `enable_panvk` | Build PanVK Vulkan driver (Mali-G72) | `true` | `true`, `false` |
| `optimize_level` | Optimization level | `3` | `2` (balanced), `3` (maximum) |

## Installation Details

### Supported Drivers

#### Panfrost (Requires DRM/KMS)

- **Requirements**: `/dev/dri/card0` and `/dev/dri/renderD128` must exist
- **Kernel**: Must have `CONFIG_DRM_PANFROST=y` enabled
- **Performance**: 5-10x faster than llvmpipe
- **Support**: OpenGL ES 3.1, OpenGL 3.1, Vulkan 1.0

**Environment Variables:**
```bash
export MESA_LOADER_DRIVER_OVERRIDE=panfrost
export PAN_MESA_DEBUG=gl3
```

#### Mali-DP (Legacy /dev/mali0)

- **Requirements**: `/dev/mali0` must exist
- **Kernel**: Must have `CONFIG_MALI_MIDGARD=y` or `CONFIG_MALI_BIFROST=y` enabled
- **Performance**: 2-4x faster than llvmpipe
- **Support**: OpenGL ES 2.0/3.0 (limited features)

**Environment Variables:**
```bash
export MESA_LOADER_DRIVER_OVERRIDE=mali_dp
```

### Device Compatibility

| Device | SoC | GPU | Recommended Driver | Known Working |
|---------|-----|-----|-------------------|---------------|
| Samsung R7/A7/A9 (Exynos 9810) | Exynos 9810 | Mali-G72 MP18 | Mali-DP (legacy) |
| Samsung Galaxy Note 9/S10 | Exynos 9820 | Mali-G76 MP12 | Mali-DP (legacy) |
| Raspberry Pi 4/5 | Various | Various | Panfrost (if DRM) | Depends on kernel |
| PinePhone Pro | Rockchip RK3399 | Mali-T860 MP4 | Panfrost (if DRM) | Depends on kernel |

**Note for Samsung R7 (Exynos 9810):**

Your device has:
- ✅ Mali-G72 MP18 GPU
- ✅ `/dev/mali0` available
- ❌ No DRM/KMS support (no `/dev/dri/card0`)

**Recommended**: Use **Mali-DP driver** initially. If you later flash a custom kernel with DRM/Panfrost support, switch to Panfrost.

## Testing

### Quick Verification

```bash
# Run built-in verification script
./verify.sh
```

### Manual Testing

```bash
# Install test tools
sudo apt install mesa-utils glmark2

# Check OpenGL renderer
glxinfo | grep "OpenGL renderer"
# Expected output (Mali-DP): "Mali G72 (r38p0)"
# Expected output (Panfrost): "Panfrost Mali G72"

# Run benchmark
glmark2 --benchmark all --duration 5
```

### Performance Comparison (Expected)

| Driver | glmark2 Score | Relative to llvmpipe |
|--------|---------------|----------------------|
| llvmpipe (current) | ~100 FPS | 1x (baseline) |
| Mali-DP (legacy) | ~250-400 FPS | 2.5-4x |
| Panfrost (DRM) | ~500-1000 FPS | 5-10x |

## Troubleshooting

### Panfrost Not Working

**Symptoms**: Falls back to llvmpipe, errors in logs

**Checks:**
```bash
# Check for DRM devices
ls -la /dev/dri/
# Expected: card0, renderD128, etc.

# Check Panfrost driver files
ls -la /usr/lib/aarch64-linux-gnu/dri/panfrost*

# Check environment variables
env | grep -i mesa
```

**Solutions:**
1. Kernel lacks DRM support - Enable `CONFIG_DRM_PANFROST=y` in kernel config
2. Try Mali-DP driver instead (works with legacy `/dev/mali0`)
3. Verify library paths with `ldconfig -p | grep mesa`

### Mali-DP Not Working

**Symptoms**: Falls back to llvmpipe, device not found errors

**Checks:**
```bash
# Check for Mali device
ls -la /dev/mali0
# Expected: crw-rw-rw- root root 10, 87 ...

# Check Mali DP driver files
ls -la /usr/lib/aarch64-linux-gnu/dri/*mali*

# Check permissions
stat /dev/mali0
```

**Solutions:**
1. Check device permissions: `sudo chmod 666 /dev/mali0`
2. Verify kernel has Mali support: `cat /proc/config.gz 2>/dev/null | zcat | grep MALI`
3. Reboot after installation

### Falls Back to llvmpipe

**Cause**: Driver not loaded, environment variable not set, or incompatible kernel

**Solutions:**
```bash
# Force driver selection
export MESA_LOADER_DRIVER_OVERRIDE=mali_dp

# Verify driver is loading
LIBGL_DEBUG=verbose glxinfo 2>&1 | grep "Driver loader"

# Check which DRI driver is being used
ldd $(which glxinfo) | grep dri
```

### Performance Issues

**Symptoms**: Slow rendering, low FPS, thermal throttling

**Checks:**
```bash
# Check for thermal throttling
dmesg | grep -i thermal

# Check GPU frequency
cat /sys/class/devfreq/*/cur_freq

# Check for errors in kernel logs
dmesg | grep -i "gpu\|mali\|panfrost"
```

**Solutions:**
1. Reduce optimization level: Rebuild with `optimize_level=2`
2. Check device cooling and ventilation
3. Disable power saving features in kernel

### X11/VNC Issues

**Symptoms**: Black screen, crashes when starting X11, VNC not updating

**Solutions:**
```bash
# Restart X11/VNC service
sudo systemctl restart vncserver@:1.service

# Check X11 logs
cat ~/.vnc/*.log | tail -50

# Test with simple application first
export DISPLAY=:1
glxgears
```

## Rollback

If installation causes issues:

```bash
# Restore original Mesa libraries
cp /tmp/mesa-backup/* /usr/lib/aarch64-linux-gnu/
ldconfig

# Remove environment variables
rm /etc/environment.d/mesa-driver.conf

# Restart X11/VNC
sudo systemctl restart vncserver@:1.service
```

## Building Locally (Without GitHub Actions)

If you prefer to build Mesa directly on your Ubuntu-Chroot:

```bash
# Install build dependencies
sudo apt install git build-essential ninja-build meson python3-pip \
  python3-mako python3-pil python3-yaml libxcb-dri3-dev \
  libx11-xcb-dev libxkbcommon-dev libxshmfence-dev libdrm-dev \
  libxrandr-dev libxinerama-dev libxcursor-dev libxfixes-dev \
  libxi-dev libxext-dev libxv-dev libxvm-dev libgbm-dev \
  libwayland-dev libegl1-mesa-dev libgles2-mesa-dev \
  libgl1-mesa-dev libvulkan-dev glslang-tools spirv-tools \
  pkg-config flex bison libwayland-protocols-dev

python3 -m pip install mako jinja2 ply pyyaml

# Clone and build Mesa
cd /tmp
git clone https://gitlab.freedesktop.org/mesa/mesa.git
cd mesa
git checkout mesa-26.0.0

meson setup build \
  --prefix=/usr \
  --sysconfdir=/etc \
  --libdir=/usr/lib/aarch64-linux-gnu \
  -Dplatforms=x11,wayland,surfaceless \
  -Dgallium-drivers=panfrost,zink,llvmpipe \
  -Degl=enabled \
  -Dgles2=enabled \
  -Dglx=dri \
  -Dbuildtype=release \
  -Doptimization=3

ninja -C build -j$(nproc)
sudo ninja -C build install
sudo ldconfig
```

## Advanced Usage

### Custom Driver Configuration

To use specific Mesa features or debug options:

```bash
# Panfrost debug options
export PAN_MESA_DEBUG=gl3         # OpenGL 3.x support
export PAN_MESA_DEBUG=nocompat     # Disable compat checks
export PAN_MESA_DEBUG=syncobj      # Force sync objects

# Mali-DP options
export PAN_MESA_DEBUG=gl2          # Force OpenGL ES 2.x

# General Mesa debugging
export LIBGL_DEBUG=verbose         # Verbose library loading
export MESA_DEBUG=verbose          # Verbose Mesa operation
```

### Building with Different Mesa Versions

```bash
# List available Mesa tags
git ls-remote --tags https://gitlab.freedesktop.org/mesa/mesa.git | grep mesa

# Build specific version
gh workflow run build-mesa-panfrost.yml -f mesa_version=25.3.4
gh workflow run build-mesa-panfrost.yml -f mesa_version=26.1.0
```

### Matrix Builds

To build multiple Mesa versions or configurations simultaneously, modify workflow to use `matrix` strategy:

```yaml
strategy:
  matrix:
    mesa_version: ['25.3.4', '26.0.0']
    optimize_level: ['2', '3']
```

## Project Structure

```
mesa-panfrost-build/
├── .github/
│   └── workflows/
│       └── build-mesa-panfrost.yml    # Main GitHub Actions workflow
├── configs/
│   └── meson-cross-aarch64.txt       # Meson cross-compilation config
├── scripts/
│   ├── install-mesa.sh                 # Installation script
│   └── verify.sh                     # Verification script
└── README.md                           # This file
```

## Contributing

Contributions are welcome! Please:
1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project provides build scripts and workflows. The Mesa library itself is licensed under MIT license. See https://docs.mesa3d.org/license.html for details.

## References

- [Mesa 3D Documentation](https://docs.mesa3d.org/)
- [Panfrost Driver Documentation](https://docs.mesa3d.org/drivers/panfrost.html)
- [Mesa GitLab](https://gitlab.freedesktop.org/mesa/mesa)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [uraimo/run-on-arch-action](https://github.com/uraimo/run-on-arch-action)
- [Ubuntu-Chroot](https://github.com/ravindu644/Ubuntu-Chroot)

## Support

For issues specific to this build workflow:
- Open an issue in this repository

For Mesa driver issues:
- [Mesa Issue Tracker](https://gitlab.freedesktop.org/mesa/mesa/-/issues)
- [Freedesktop Bugzilla](https://bugs.freedesktop.org/)

---

**Built with ❤️ for ARM64 Linux on mobile devices**
