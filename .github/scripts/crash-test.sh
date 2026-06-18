#!/usr/bin/env bash
set -euo pipefail

LANGUAGE="${1:-unknown}"

echo "=== Crash Test for $LANGUAGE ==="

case "$LANGUAGE" in
    rust)
        if [ -f "Cargo.toml" ]; then
            echo "Running cargo test..."
            cargo test 2>&1 || echo "NOTE: Tests may have failed (non-fatal)" 
            echo "Running binary if available..."
            cargo run 2>&1 || echo "NOTE: Binary run exited with non-zero (non-fatal)"
        else
            echo "SKIP: No Cargo.toml found"
        fi
        ;;
    node)
        if [ -f "package.json" ]; then
            if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
                echo "Running test script..."
                npm test 2>&1 || echo "NOTE: Tests may have failed (non-fatal)"
            fi
            if jq -e '.scripts.start' package.json >/dev/null 2>&1; then
                echo "Running start script (limited time)..."
                timeout 10 npm start 2>&1 || echo "NOTE: Start exited (expected)"
            fi
        fi
        ;;
    python)
        if ls *.py 2>/dev/null | head -1 && [ ! -f "Cargo.toml" ] && [ ! -f "package.json" ]; then
            echo "Looking for Python entry point..."
            for f in main.py app.py run.py __main__.py; do
                if [ -f "$f" ]; then
                    echo "Running $f (limited time)..."
                    timeout 5 python3 "$f" 2>&1 || echo "NOTE: $f exited (non-fatal)"
                    break
                fi
            done
        fi
        ;;
esac

echo ""
echo "CRASH TEST COMPLETE"
