#!/usr/bin/env bash
# Idempotent bootstrap for the ToolBox repository's runnable component: the
# Ruby "ExcelToStrings" localization tool (Excel -> iOS .strings + AES crypt).
#
# The Swift "Tools" target (ToolBox.xcodeproj) is macOS-only (Cocoa/AppKit/
# CommonCrypto, no Package.swift) and cannot be built on a Linux Cloud Agent,
# so it is intentionally not set up here.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Ensuring Ruby toolchain is installed"
if ! command -v ruby >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ruby-full build-essential zlib1g-dev libxml2-dev libxslt1-dev
fi
ruby --version

echo "==> Ensuring bundler is installed"
command -v bundle >/dev/null 2>&1 || sudo gem install --no-document bundler

echo "==> Installing ExcelToStrings gem dependencies"
cd "$REPO_ROOT/ExcelToStrings"
# Keep gems local to the checkout and add the Linux platform, since the
# committed Gemfile.lock is pinned to arm64-darwin only.
bundle config set --local path 'vendor/bundle'
bundle lock --add-platform x86_64-linux
bundle install

echo "==> Environment setup complete"
