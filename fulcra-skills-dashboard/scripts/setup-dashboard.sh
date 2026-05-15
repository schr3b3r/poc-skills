#!/bin/bash
set -e

# Resolve the directory of this script to find the template
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../template-dashboard"
TARGET_DIR="${1:-fulcra-dashboard}"

echo "🚀 Setting up Fulcra Skills Dashboard in: $TARGET_DIR"

if [ -d "$TARGET_DIR" ]; then
  echo "⚠️  Directory $TARGET_DIR already exists. Please choose a different name or remove it first."
  exit 1
fi

echo "📦 Copying dashboard template..."
cp -r "$TEMPLATE_DIR" "$TARGET_DIR"

cd "$TARGET_DIR"

echo "📥 Installing dependencies..."
npm install

echo "📁 Creating data directories..."
mkdir -p static/data
mkdir -p src/lib/components

echo "✅ Setup complete!"
echo "To start the dashboard, run:"
echo "  cd $TARGET_DIR"
echo "  npm run dev"
echo ""
echo "🤖 AGENT NOTE: You should now ask the user what visual theme they want and style the un-styled template components (src/routes/+page.svelte)!"
