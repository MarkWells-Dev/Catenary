#!/bin/bash
set -e

EXPERIMENT_DIR="/tmp/catenary-experiment"

echo "=== Catenary + Gemini CLI Prototype ==="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v gemini &> /dev/null; then
    echo "ERROR: gemini cli not found"
    echo "Install: https://github.com/google-gemini/gemini-cli"
    exit 1
fi
echo "  gemini: $(which gemini)"

if ! command -v catenary &> /dev/null; then
    echo "ERROR: catenary not found"
    echo "Install: cargo install catenary-mcp"
    exit 1
fi
echo "  catenary: $(which catenary)"

echo ""
echo "Prerequisites OK"
echo ""

# Check if experiment dir exists
if [ ! -d "$EXPERIMENT_DIR" ]; then
    echo "Creating experiment directory..."
    mkdir -p "$EXPERIMENT_DIR/.gemini"

    # Create workspace settings (use tools.core allowlist - tools.exclude doesn't work)
    cat > "$EXPERIMENT_DIR/.gemini/settings.json" << 'EOF'
{
  "tools": {
    "core": [
      "web_fetch",
      "google_web_search",
      "save_memory"
    ]
  },
  "mcpServers": {
    "catenary": {
      "command": "catenary"
    }
  }
}
EOF

    # Create test file
    cat > "$EXPERIMENT_DIR/main.rs" << 'EOF'
fn main() {
    println!("Hello from catenary experiment!");
}

fn add(a: i32, b: i32) -> i32 {
    a + b
}
EOF
    echo "Created $EXPERIMENT_DIR with workspace settings"
fi

echo ""
echo "Experiment dir: $EXPERIMENT_DIR"
echo "Settings: $EXPERIMENT_DIR/.gemini/settings.json"
echo ""
echo "Starting gemini cli..."
echo "In another terminal, run: catenary monitor"
echo ""
echo "---"
echo ""

cd "$EXPERIMENT_DIR"
gemini
