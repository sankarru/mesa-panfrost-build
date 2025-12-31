#!/bin/bash
set -e

echo "=========================================="
echo "Local Mesa 25.3.2 Build Script for ARM64"
echo "=========================================="
echo ""

MESA_VERSION="24.3.4"
BUILD_DIR="$HOME/mesa-build-$MESA_VERSION"
SOURCE_DIR="$HOME/mesa-source"
ARTIFACT_DIR="$HOME/mesa-artifacts"
JOBS=$(nproc)

echo "Configuration:"
echo "  Mesa version: $MESA_VERSION"
echo "  Build directory: $BUILD_DIR"
echo "  Source directory: $SOURCE_DIR"
echo "  Artifact directory: $ARTIFACT_DIR"
echo "  Parallel jobs: $JOBS"
echo ""

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y \
  git build-essential ninja-build meson python3 python3-pip \
  python3-mako python3-pil python3-yaml libxcb-dri3-dev \
  libx11-xcb-dev libxcb-keysyms1-dev libxkbcommon-dev \
  libxshmfence-dev libdrm-dev libxrandr-dev libxinerama-dev \
  libxcursor-dev libxfixes-dev libxi-dev libxext-dev \
  libxv-dev libgbm-dev libwayland-dev \
  libegl1-mesa-dev libgles2-mesa-dev libgl1-mesa-dev \
  glslang-tools spirv-tools pkg-config \
  flex bison wayland-protocols \
  libx11-dev libxxf86vm-dev \
  libxcb-dri2-0-dev libxcb-glx0-dev \
  libxcb-present-dev libxcb-xfixes0-dev libexpat1-dev \
  libudev-dev libxml2-dev libssl-dev \
  libelf-dev libclang-20-dev

# Update Meson if needed (Mesa 25.3.2 requires >=1.4.0)
echo ""
echo "Checking Meson version..."
CURRENT_MESON=$(meson --version | cut -d. -f1,2 | tr -d '.')
if [ "$CURRENT_MESON" -lt 14 ]; then
  echo "Meson version < 1.4.0, upgrading via pip..."
  python3 -m pip install --break-system-packages "meson>=1.4.0"
else
  echo "Meson version OK: $(meson --version)"
fi

# Install Python packages
echo ""
echo "Installing Python packages..."
python3 -m pip install --break-system-packages mako jinja2 ply pyyaml markdown

# Clone Mesa
echo ""
echo "Cloning Mesa $MESA_VERSION..."
if [ -d "$SOURCE_DIR" ]; then
  cd "$SOURCE_DIR"
  git fetch --tags origin
  git checkout "mesa-$MESA_VERSION"
else
  git clone --depth=1 --branch "mesa-$MESA_VERSION" https://gitlab.freedesktop.org/mesa/mesa.git "$SOURCE_DIR"
  cd "$SOURCE_DIR"
fi

# Configure
echo ""
echo "Configuring Mesa..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

meson setup "$BUILD_DIR" \
  --prefix=/usr \
  --sysconfdir=/etc \
  --libdir=/usr/lib/aarch64-linux-gnu \
  -Dplatforms=x11,wayland \
  -Dgallium-drivers=panfrost \
  -Degl=enabled \
  -Dgles2=enabled \
  -Dgles1=disabled \
  -Dglx=dri \
  -Dbuildtype=release \
  -Doptimization=3 \
  --wrap-mode=nofallback

# Build
echo ""
echo "Building Mesa with $JOBS parallel jobs..."
echo "This will take 30-60 minutes on ARM64..."
ninja -C "$BUILD_DIR" -j"$JOBS" || exit 1

# Create artifacts
echo ""
echo "Creating package..."
rm -rf "$ARTIFACT_DIR"
mkdir -p "$ARTIFACT_DIR/mesa-$MESA_VERSION-ubuntu24.04-aarch64"

DESTDIR="$ARTIFACT_DIR/mesa-$MESA_VERSION-ubuntu24.04-aarch64"
ninja -C "$BUILD_DIR" install || exit 1

tar -czf "$ARTIFACT_DIR/mesa-$MESA_VERSION-ubuntu24.04-aarch64.tar.gz" \
  -C "$ARTIFACT_DIR/mesa-$MESA_VERSION-ubuntu24.04-aarch64" \
  usr

echo ""
echo "=========================================="
echo "Build complete!"
echo "=========================================="
echo ""
echo "Artifacts:"
echo "  Tarball: $ARTIFACT_DIR/mesa-$MESA_VERSION-ubuntu24.04-aarch64.tar.gz"
echo "  Directory: $ARTIFACT_DIR/mesa-$MESA_VERSION-ubuntu24.04-aarch64/"
echo ""
echo "Install in Android chroot:"
echo "  adb push $ARTIFACT_DIR/mesa-$MESA_VERSION-ubuntu24.04-aarch64.tar.gz /data/local/tmp/"
echo "  # In chroot:"
echo "  cd /tmp && tar -xzf /data/local/tmp/mesa-$MESA_VERSION-ubuntu24.04-aarch64.tar.gz"
echo "  export MESA_LOADER_DRIVER_OVERRIDE=mali_dp"
echo "  # Or for Panfrost (if you have DRM/KMS):"
echo "  # export MESA_LOADER_DRIVER_OVERRIDE=panfrost"
echo ""
echo "File sizes:"
du -sh "$ARTIFACT_DIR"/*
echo ""
