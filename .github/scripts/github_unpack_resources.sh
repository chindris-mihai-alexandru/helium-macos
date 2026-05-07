#!/bin/bash -eux

# Unpacking script for GitHub Actions

echo "Checking sha256sum of archive:"
# Check if checksum file exists, if not skip verification
if [ -f "build_resources_sums.txt" ]; then
  sha256sum -c build_resources_sums.txt
else
  echo "build_resources_sums.txt not found, skipping checksum verification"
fi

ls -lrt

echo "Extracting build archive"
tar -xf build_resources.tar.zst

rm build_resources.tar.zst
