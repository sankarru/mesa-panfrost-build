#!/bin/bash
set -e

echo "=========================================="
echo "Mesa Verification Script"
echo "=========================================="
echo ""

if command -v glxinfo &> /dev/null; then
  echo "Checking OpenGL renderer..."
  RENDERER=$(glxinfo 2>/dev/null | grep "OpenGL renderer string" | head -1 || echo "Not available")
  echo "  $RENDERER"
  echo ""

  if echo "$RENDERER" | grep -qi "llvmpipe"; then
    echo "WARNING: Software rendering (llvmpipe) is active!"
    echo "GPU acceleration is NOT working."
    echo ""
  elif echo "$RENDERER" | grep -qi "panfrost\|mali"; then
    echo "SUCCESS: Hardware acceleration is active!"
    echo ""
  else
    echo "Unknown renderer. Check configuration."
    echo ""
  fi
else
  echo "glxinfo not installed"
  echo "Install with: sudo apt install mesa-utils"
  echo ""
fi

if command -v glmark2 &> /dev/null; then
  echo "Running glmark2 benchmark..."
  echo "Testing for 5 seconds..."
  glmark2 --benchmark all --duration 5 2>&1 | grep -E "FPS|Score" || true
  echo ""
else
  echo "glmark2 not installed"
  echo "Install with: sudo apt install glmark2"
  echo ""
fi

if [ -e /dev/dri ]; then
  echo "DRM devices found:"
  ls -la /dev/dri/ 2>/dev/null || echo "  None"
  echo ""
fi

if [ -e /dev/mali0 ]; then
  echo "Mali device found:"
  ls -la /dev/mali0
  echo ""
fi

echo "Environment variables:"
env | grep -i mesa || echo "  None set"
echo ""

echo "=========================================="
echo "Verification complete!"
echo "=========================================="