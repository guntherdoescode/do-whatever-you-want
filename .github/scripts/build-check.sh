#!/usr/bin/env bash
set -euo pipefail

LANGUAGE="${1:-unknown}"

echo "=== Build/Compile Check for $LANGUAGE ==="

case "$LANGUAGE" in
    rust)
        if [ -f "Cargo.toml" ]; then
            echo "Building Rust project..."
            cargo build --verbose 2>&1
        else
            echo "SKIP: No Cargo.toml found"
        fi
        ;;
    go)
        if [ -f "go.mod" ] || ls *.go 2>/dev/null | head -1; then
            echo "Building Go project..."
            go build ./... 2>&1
        else
            echo "SKIP: No Go files found"
        fi
        ;;
    node)
        if [ -f "package.json" ]; then
            if [ -f "tsconfig.json" ]; then
                echo "Building TypeScript project..."
                npx tsc --noEmit 2>&1
            fi
            if jq -e '.scripts.build' package.json >/dev/null 2>&1; then
                echo "Running build script..."
                npm run build 2>&1
            else
                echo "SKIP: No build script in package.json"
            fi
        else
            echo "SKIP: No package.json found"
        fi
        ;;
    python)
        if ls *.py 2>/dev/null | head -1; then
            echo "Checking Python syntax..."
            python3 -m py_compile ./*.py 2>&1 || true
            # Check for setup.py/build
            if [ -f "setup.py" ] || [ -f "setup.cfg" ] || [ -f "pyproject.toml" ]; then
                echo "Building Python package..."
                python3 -m build --dry-run 2>&1 || python3 setup.py build 2>&1 || true
            fi
        else
            echo "SKIP: No Python files found"
        fi
        ;;
    java)
        if ls *.java 2>/dev/null | head -1; then
            if [ -f "pom.xml" ]; then
                echo "Building Maven project..."
                mvn compile -q 2>&1
            elif [ -f "build.gradle" ]; then
                echo "Building Gradle project..."
                gradle compileJava 2>&1
            else
                echo "Compiling Java files directly..."
                javac *.java 2>&1
            fi
        else
            echo "SKIP: No Java files found"
        fi
        ;;
    *)
        echo "SKIP: Unknown language '$LANGUAGE'"
        ;;
esac

echo ""
echo "BUILD CHECK COMPLETE"
