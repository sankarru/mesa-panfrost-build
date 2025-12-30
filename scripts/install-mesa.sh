#!/bin/bash
set -e

echo "=========================================="
echo "Mesa Panfrost Installation Script"
echo "=========================================="
echo ""

MESA_VERSION="${MESA_VERSION:-26.0.0}"
INSTALL_DIR="/"

if [ -z "$1" ]; then
  echo "Usage: $0 <mesa-tarball> [driver]"
  echo ""
  echo "Drivers:"
  echo "  panfrost - Panfrost driver (requires DRM/KMS)"
  echo "  mali_dp - Mali-DP driver (legacy /dev/mali0)"
  echo ""
  echo "Example: $0 mesa-26.0.0-ubuntu24.04-aarch64.tar.gz panfrost"
  exit 1
fi

TARBALL="$1"
DRIVER="${2:-auto}"

if [ "$DRIVER" = "auto" ]; then
  if [ -e /dev/dri/card0 ]; then
    DRIVER="panfrost"
    echo "Detected DRM/KMS support, using Panfrost driver"
  elif [ -e /dev/mali0 ]; then
    DRIVER="mali_dp"
    echo "Detected /dev/mali0, using Mali-DP driver"
  else
    echo "ERROR: No compatible GPU device found"
    echo "  /dev/dri/card0 not found (Panfrost requires DRM/KMS)"
    echo "  /dev/mali0 not found (Mali-DP requires legacy Mali)"
    exit 1
  fi
fi

if [ ! -f "$TARBALL" ]; then
  echo "ERROR: Tarball not found: $TARBALL"
  exit 1
fi

echo "Installing Mesa ${MESA_VERSION}..."
echo "Driver: ${DRIVER}"
echo ""

echo "Creating backup..."
mkdir -p /tmp/mesa-backup
[ -f /usr/lib/aarch64-linux-gnu/libGL.so.1 ] && \
  cp /usr/lib/aarch64-linux-gnu/libGL.so.1 /tmp/mesa-backup/
[ -f /usr/lib/aarch64-linux-gnu/libEGL.so.1 ] && \
  cp /usr/lib/aarch64-linux-gnu/libEGL.so.1 /tmp/mesa-backup/
[ -f /usr/lib/aarch64-linux-gnu/libGLESv2.so.2 ] && \
  cp /usr/lib/aarch64-linux-gnu/libGLESv2.so.2 /tmp/mesa-backup/

echo "Extracting Mesa..."
tar -xzf "$TARBALL" -C /

echo "Running ldconfig..."
ldconfig

case "$DRIVER" in
  panfrost)
    echo "Configuring Panfrost driver..."
    if [ ! -d /etc/environment.d ]; then
      mkdir -p /etc/environment.d
    fi
    echo 'export MESA_LOADER_DRIVER_OVERRIDE=panfrost' > /etc/environment.d/mesa-driver.conf
    echo 'export PAN_MESA_DEBUG=gl3' >> /etc/environment.d/mesa-driver.conf
    ;;
  mali_dp)
    echo "Configuring Mali-DP driver..."
    if [ ! -d /etc/environment.d ]; then
      mkdir -p /etc/environment.d
    fi
    echo 'export MESA_LOADER_DRIVER_OVERRIDE=mali_dp' > /etc/environment.d/mesa-driver.conf
    ;;
  *)
    echo "No driver configuration for: $DRIVER"
    ;;
esac

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "Driver: ${DRIVER}"
echo "Mesa version: ${MESA_VERSION}"
echo ""
echo "Backup location: /tmp/mesa-backup"
echo ""
echo "To restore backup, run:"
echo "  cp /tmp/mesa-backup/* /usr/lib/aarch64-linux-gnu/"
echo "  ldconfig"
echo ""
echo "To verify installation:"
echo "  export DISPLAY=:0"
echo "  glxinfo | grep -i 'OpenGL renderer'"
echo ""
echo "To test performance:"
echo "  glmark2"
echo ""