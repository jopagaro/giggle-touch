#!/bin/bash
set -e

APP_NAME="GiggleTouch"
APP_BUNDLE="${APP_NAME}.app"
BUILD_DIR=".build/release"

echo "▶ Building ${APP_NAME}..."
swift build -c release

echo "▶ Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
mkdir -p "${APP_BUNDLE}/Contents/Resources/giggles"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp Info.plist "${APP_BUNDLE}/Contents/Info.plist"
cp -R giggles/. "${APP_BUNDLE}/Contents/Resources/giggles/"

echo "✅ Done: ${APP_BUNDLE}"
echo ""
echo "To run:  open ${APP_BUNDLE}"
echo ""
echo "First launch: macOS will ask for Accessibility permission."
echo "Go to System Settings → Privacy & Security → Accessibility and enable GiggleTouch."
