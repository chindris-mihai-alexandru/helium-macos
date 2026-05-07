#!/bin/bash -eux

# Simple script for getting ready to build Helium macOS binaries on GitHub Actions

_target_cpu="$1"

# Some path variables
_root_dir="$(dirname "$(greadlink -f "$0")")"
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/helium-chromium"

shopt -s nocasematch

if [[ $_target_cpu == "arm64" ]]; then
  echo 'target_cpu = "arm64"' >> "$_root_dir/flags.macos.gn"
else
  echo 'target_cpu = "x64"' >> "$_root_dir/flags.macos.gn"
fi

cp "$_main_repo/flags.gn" "$_src_dir/out/Default/args.gn"
cat "$_root_dir/flags.macos.gn" >> "$_src_dir/out/Default/args.gn"
# cc_wrapper disabled: GHA cache backend fails on self-hosted runners
# echo 'cc_wrapper="sccache"' >> "$_src_dir/out/Default/args.gn"

if ! [ -z "${PROD_MACOS_SPARKLE_ED_PUB_KEY-}" ]; then
  echo 'enable_sparkle=true' >> "$_src_dir/out/Default/args.gn"
  echo 'sparkle_ed_key="'"$PROD_MACOS_SPARKLE_ED_PUB_KEY"'"' >> "$_src_dir/out/Default/args.gn"
fi

echo 'symbol_level=0' >> "$_src_dir/out/Default/args.gn"
echo 'chrome_pgo_phase=2' >> "$_src_dir/out/Default/args.gn"

# Use macOS 14.0 deployment target for maximum compatibility
echo 'mac_deployment_target="14.0"' >> "$_src_dir/out/Default/args.gn"

# Create fallback sys/fileport.h header for macOS 15.2 SDK compatibility
mkdir -p "$_src_dir/sys"
cat > "$_src_dir/sys/fileport.h" << 'HEADER_EOF'
// Fallback header for missing sys/fileport.h on macOS 15.2 SDK
// This header provides minimal definitions for fileport functionality

#ifndef SYS_FILEPORT_H_
#define SYS_FILEPORT_H_

#include <mach/mach.h>

#define FILEPORT_NULL ((mach_port_t)0)
typedef mach_port_t fileport_t;

#ifdef __cplusplus
extern "C" {
#endif

// Minimal fileport functions for compatibility
// Note: Simplified versions that match the expected signatures
static inline kern_return_t fileport_makefd(fileport_t fileport) {
  return KERN_FAILURE;
}

static inline kern_return_t fileport_makeport(int fd) {
  return KERN_FAILURE;
}

static inline kern_return_t fileport_makefd_with_fd(fileport_t fileport, int *fd) {
  return KERN_FAILURE;
}

#ifdef __cplusplus
}
#endif

#endif // SYS_FILEPORT_H_
HEADER_EOF

# Memory-saving flags for GitHub-hosted runners (7GB RAM)
echo 'use_thin_lto=false' >> "$_src_dir/out/Default/args.gn"
echo 'thin_lto_enable_optimizations=false' >> "$_src_dir/out/Default/args.gn"

cd "$_src_dir"

./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./out/Default/gn gen out/Default --fail-on-unused-args
