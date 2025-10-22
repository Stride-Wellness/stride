#!/bin/bash
set -e

# Clone Flutter into a temp folder (won't be committed)
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Add flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verify Flutter installation
flutter --version

# Enable web (just in case)
flutter config --enable-web

# Get dependencies
flutter pub get

# Build for WebAssembly (Wasm)
flutter build web --wasm