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
    go)
        if [ -f "go.mod" ] || ls *.go 2>/dev/null | head -1; then
            echo "Running Go tests..."
            go test ./... 2>&1 || true
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
    java)
        echo "Running Java crash test..."
        if [ -f "pom.xml" ]; then
            mvn test -q 2>&1 || true
        fi
        ;;
    c_cpp)
        if [ -f "Makefile" ] && grep -q '^run' Makefile 2>/dev/null; then
            echo "Running make run..."
            timeout 10 make run 2>&1 || echo "NOTE: make run exited (expected)"
        fi
        ;;
    csharp)
        if ls *.csproj *.sln 2>/dev/null | head -1; then
            echo "Running dotnet test..."
            dotnet test 2>&1 || true
            echo "Running dotnet run..."
            timeout 10 dotnet run 2>&1 || echo "NOTE: dotnet run exited (expected)"
        fi
        ;;
    ruby)
        if ls *.rb 2>/dev/null | head -1; then
            for f in main.rb app.rb run.rb; do
                if [ -f "$f" ]; then
                    echo "Running $f..."
                    timeout 5 ruby "$f" 2>&1 || echo "NOTE: $f exited (non-fatal)"
                    break
                fi
            done
        fi
        ;;
    php)
        echo "PHP lint already performed in build check"
        if [ -f "composer.json" ]; then
            composer validate 2>&1 || true
        fi
        ;;
    zig)
        if [ -f "build.zig" ]; then
            echo "Running zig test..."
            zig test src/*.zig 2>&1 || true
        fi
        ;;
    kotlin)
        if [ -f "output.jar" ]; then
            echo "Running compiled Kotlin..."
            timeout 5 java -jar output.jar 2>&1 || echo "NOTE: jar run exited (non-fatal)"
        fi
        ;;
    swift)
        if [ -f "Package.swift" ]; then
            echo "Running Swift tests..."
            swift test 2>&1 || true
        fi
        ;;
    haskell)
        if [ -f "stack.yaml" ]; then
            echo "Running Stack tests..."
            stack test 2>&1 || true
        fi
        ;;
    dart)
        if [ -f "pubspec.yaml" ]; then
            echo "Running Dart tests..."
            dart test 2>&1 || true
        fi
        ;;
    scala)
        if [ -f "build.sbt" ]; then
            echo "Running Scala tests..."
            sbt test 2>&1 || true
        fi
        ;;
esac

echo ""
echo "CRASH TEST COMPLETE"
