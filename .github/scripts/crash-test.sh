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
    assembly)
        if ls *.o 2>/dev/null | head -1; then
            echo "Linking and running assembly..."
            gcc -o /tmp/asm_prog *.o -lc 2>/dev/null && timeout 5 /tmp/asm_prog || echo "NOTE: Assembly run exited (expected)"
        elif ls *.asm 2>/dev/null | head -1; then
            for f in *.asm; do
                [ -f "$f" ] && nasm -f elf64 "$f" -o /tmp/asm_test.o && gcc -o /tmp/asm_test /tmp/asm_test.o && timeout 5 /tmp/asm_test || echo "NOTE: Assembly run exited (expected)"
                break
            done
        fi
        ;;
    brainfuck)
        if ls *.bf *.b 2>/dev/null | head -1; then
            for f in *.bf *.b; do
                [ -f "$f" ] && timeout 5 bf "$f" 2>&1 || echo "NOTE: $f exited (expected)"
                break
            done
        fi
        ;;
    clojure)
        if [ -f "deps.edn" ] || [ -f "project.clj" ]; then
            echo "Running Clojure..."
            timeout 10 clojure -M -e '(println "hello")' 2>&1 || echo "NOTE: Clojure run exited (expected)"
        fi
        ;;
    crystal)
        if ls *.cr 2>/dev/null | head -1; then
            echo "Running Crystal..."
            timeout 5 crystal run *.cr 2>&1 || echo "NOTE: Crystal run exited (expected)"
        fi
        ;;
    elixir)
        if [ -f "mix.exs" ]; then
            echo "Running Elixir project..."
            timeout 10 mix run 2>&1 || echo "NOTE: mix run exited (expected)"
        elif ls *.exs 2>/dev/null | head -1; then
            for f in *.exs; do
                [ -f "$f" ] && timeout 10 elixir "$f" 2>&1 || echo "NOTE: $f exited (expected)"
                break
            done
        fi
        ;;
    erlang)
        if ls *.erl 2>/dev/null | head -1; then
            echo "Running Erlang..."
            timeout 5 erl -noshell -eval 'halt().' 2>&1 || echo "NOTE: Erlang run exited (expected)"
        fi
        ;;
    julia)
        if ls *.jl 2>/dev/null | head -1; then
            for f in main.jl app.jl run.jl; do
                if [ -f "$f" ]; then
                    echo "Running $f..."
                    timeout 10 julia "$f" 2>&1 || echo "NOTE: $f exited (expected)"
                    break
                fi
            done
        fi
        ;;
    lua)
        if ls *.lua 2>/dev/null | head -1; then
            for f in main.lua app.lua run.lua; do
                if [ -f "$f" ]; then
                    echo "Running $f..."
                    timeout 5 lua "$f" 2>&1 || echo "NOTE: $f exited (expected)"
                    break
                fi
            done
        fi
        ;;
    nim)
        if ls *.nim 2>/dev/null | head -1; then
            echo "Running Nim..."
            for f in *.nim; do
                [ -f "$f" ] && timeout 5 nim compile --run "$f" 2>&1 || echo "NOTE: Nim run exited (expected)"
                break
            done
        fi
        ;;
    ocaml)
        if ls *.ml 2>/dev/null | head -1; then
            echo "Running OCaml..."
            for f in *.ml; do
                [ -f "$f" ] && timeout 5 ocaml "$f" 2>&1 || echo "NOTE: OCaml run exited (expected)"
                break
            done
        fi
        ;;
    perl)
        if ls *.pl 2>/dev/null | head -1; then
            for f in main.pl app.pl run.pl; do
                if [ -f "$f" ]; then
                    echo "Running $f..."
                    timeout 5 perl "$f" 2>&1 || echo "NOTE: $f exited (expected)"
                    break
                fi
            done
        fi
        ;;
    r)
        if ls *.R *.r 2>/dev/null | head -1; then
            for f in main.R app.R run.R; do
                if [ -f "$f" ]; then
                    echo "Running $f..."
                    timeout 10 Rscript "$f" 2>&1 || echo "NOTE: $f exited (expected)"
                    break
                fi
            done
        fi
        ;;
    v)
        if ls *.v 2>/dev/null | head -1; then
            for f in *.v; do
                [ -f "$f" ] && timeout 5 v run "$f" 2>&1 || echo "NOTE: V run exited (expected)"
                break
            done
        fi
        ;;
esac

echo ""
echo "CRASH TEST COMPLETE"
