#!/bin/bash -eux

# Simple partitioned (2 of 3) build script for building Helium macOS binaries on GitHub Actions
# Resuming build script for macOS

_target_cpu="${1:-x86_64}"

_root_dir="$(dirname "$(greadlink -f "$0")")"
_src_dir="$_root_dir/build/src"
if [[ -f "$_root_dir/epoch_job_start.txt" ]]; then
  epoch_job_start=$(cat "$_root_dir/epoch_job_start.txt")
  # GitHub's hard time limit is 6 h per job, we want to spare 1 h for steps before and after the build,
  # To get the remaining time for building we subtract 360*60s - 60*60s - (epoch_now - epoch_job_start)
  _remaining_time=$(( 360*60 - 60*60 - $(date +%s) + epoch_job_start ))
fi

cd "$_src_dir"

echo $(date +%s) | tee -a "$_root_dir/build_times_$_target_cpu.log"
echo "status=running" >> $GITHUB_OUTPUT

# Force sccache to use local disk cache. The GHA cache backend auto-detects
# GitHub Actions environment and tries to use ACTIONS_CACHE_URL/ACTIONS_RESULTS_URL,
# which aren't reliably available in composite actions on self-hosted runners.
# Stop any existing server so it restarts with clean env.
sccache --stop-server 2>/dev/null || true
unset ACTIONS_CACHE_URL ACTIONS_RESULTS_URL ACTIONS_RUNTIME_TOKEN
unset SCCACHE_GHA_ENABLED SCCACHE_GHA_VERSION SCCACHE_GHA_CACHE_URL SCCACHE_GHA_RUNTIME_TOKEN
export SCCACHE_DIR="$HOME/.cache/sccache"
export SCCACHE_CACHE_SIZE="50G"
sccache --start-server
sccache --show-stats

set +e

timeout -k 7m -s SIGTERM ${_remaining_time:-19680}s ninja -C out/Default chrome chromedriver # 328 m as default $_remaining_time

_error_code="${?}"
if [[ "$_error_code" -eq 124 ]]; then
    exit 0
fi

if [[ "$_error_code" -ne 0 ]]; then
    exit "$_error_code"
fi

set -e

echo $(date +%s) | tee "$_root_dir/build_finished_$_target_cpu.log"
echo "status=finished" >> $GITHUB_OUTPUT
