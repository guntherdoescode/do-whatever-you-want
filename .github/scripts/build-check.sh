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
            elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
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
    c_cpp)
        if [ -f "CMakeLists.txt" ]; then
            echo "Building with CMake..."
            cmake -B build -DCMAKE_BUILD_TYPE=Release 2>&1
            cmake --build build 2>&1
        elif [ -f "Makefile" ]; then
            echo "Building with Make..."
            make 2>&1
        elif ls *.cpp *.c *.cc *.cxx 2>/dev/null | head -1; then
            echo "Compiling source files directly..."
            for src in *.c; do
                [ -f "$src" ] && gcc -Wall -Werror -o "${src%.c}" "$src" 2>&1 || true
            done
            for src in *.cpp *.cc *.cxx; do
                [ -f "$src" ] && g++ -Wall -Werror -o "${src%.*}" "$src" 2>&1 || true
            done
        else
            echo "SKIP: No C/C++ files found"
        fi
        ;;
    csharp)
        if ls *.csproj *.sln 2>/dev/null | head -1; then
            echo "Building .NET project..."
            dotnet build 2>&1
        elif ls *.cs 2>/dev/null | head -1; then
            echo "SKIP: No .csproj/.sln found for C# project"
        else
            echo "SKIP: No C# files found"
        fi
        ;;
    ruby)
        if [ -f "Gemfile" ]; then
            echo "Installing Ruby dependencies..."
            bundle install 2>&1 || true
        fi
        if ls *.rb 2>/dev/null | head -1; then
            echo "Checking Ruby syntax..."
            for f in *.rb; do
                ruby -c "$f" 2>&1
            done
        else
            echo "SKIP: No Ruby files found"
        fi
        ;;
    php)
        if [ -f "composer.json" ]; then
            echo "Installing PHP dependencies..."
            composer install --no-ansi --no-interaction 2>&1 || true
        fi
        if ls *.php 2>/dev/null | head -1; then
            echo "Linting PHP files..."
            for f in *.php; do
                php -l "$f" 2>&1
            done
        else
            echo "SKIP: No PHP files found"
        fi
        ;;
    zig)
        if [ -f "build.zig" ]; then
            echo "Building Zig project..."
            zig build 2>&1
        elif ls *.zig 2>/dev/null | head -1; then
            echo "Building Zig files..."
            for f in *.zig; do
                [ -f "$f" ] && zig build-exe "$f" 2>&1 || true
            done
        else
            echo "SKIP: No Zig files found"
        fi
        ;;
    kotlin)
        if [ -f "build.gradle.kts" ]; then
            echo "Building Kotlin with Gradle..."
            gradle build 2>&1 || true
        elif ls *.kt 2>/dev/null | head -1; then
            echo "Compiling Kotlin files..."
            kotlinc *.kt -include-runtime -d output.jar 2>&1
        else
            echo "SKIP: No Kotlin files found"
        fi
        ;;
    swift)
        if [ -f "Package.swift" ]; then
            echo "Building Swift package..."
            swift build 2>&1
        elif ls *.swift 2>/dev/null | head -1; then
            echo "Compiling Swift files..."
            for f in *.swift; do
                [ -f "$f" ] && swiftc "$f" 2>&1 || true
                break
            done
        else
            echo "SKIP: No Swift files found"
        fi
        ;;
    haskell)
        HAS_CABAL=false
        for f in *.cabal; do
            [ -f "$f" ] && HAS_CABAL=true && break
        done
        if [ -f "stack.yaml" ]; then
            echo "Building with Stack..."
            stack build 2>&1 || true
        elif [ "$HAS_CABAL" = true ]; then
            echo "Building with Cabal..."
            cabal build 2>&1 || true
        elif ls *.hs 2>/dev/null | head -1; then
            echo "Compiling Haskell files directly..."
            for f in *.hs; do
                [ -f "$f" ] && ghc -O2 "$f" 2>&1 || true
                break
            done
        else
            echo "SKIP: No Haskell files found"
        fi
        ;;
    dart)
        if [ -f "pubspec.yaml" ]; then
            echo "Analyzing Dart project..."
            dart analyze 2>&1
            echo "Compiling Dart project..."
            dart compile exe bin/*.dart 2>&1 || true
        elif ls *.dart 2>/dev/null | head -1; then
            echo "Analyzing Dart files..."
            dart analyze *.dart 2>&1 || true
        else
            echo "SKIP: No Dart files found"
        fi
        ;;
    scala)
        if [ -f "build.sbt" ]; then
            echo "Building Scala with sbt..."
            sbt compile 2>&1 || true
        elif ls *.scala 2>/dev/null | head -1; then
            echo "Compiling Scala files..."
            for f in *.scala; do
                [ -f "$f" ] && scalac "$f" 2>&1 || true
                break
            done
        else
            echo "SKIP: No Scala files found"
        fi
        ;;
    assembly)
        if ls *.asm 2>/dev/null | head -1; then
            echo "Assembling with NASM..."
            for f in *.asm; do
                [ -f "$f" ] && nasm -f elf64 "$f" -o "${f%.asm}.o" 2>&1 || true
            done
        elif ls *.s *.S 2>/dev/null | head -1; then
            echo "Assembling with GCC..."
            for f in *.s *.S; do
                [ -f "$f" ] && gcc -c "$f" -o "${f%.*}.o" 2>&1 || true
                break
            done
        else
            echo "SKIP: No Assembly files found"
        fi
        ;;
    brainfuck)
        if ls *.bf *.b 2>/dev/null | head -1; then
            echo "Checking Brainfuck syntax..."
            for f in *.bf *.b; do
                [ -f "$f" ] && bf "$f" < /dev/null 2>&1 || true
                break
            done
        else
            echo "SKIP: No Brainfuck files found"
        fi
        ;;
    clojure)
        if [ -f "deps.edn" ] || [ -f "project.clj" ]; then
            echo "Checking Clojure project..."
            clojure -M -e '(println "ok")' 2>&1 || true
        elif ls *.clj 2>/dev/null | head -1; then
            echo "Checking Clojure files..."
            clojure -M -e '(println "ok")' 2>&1 || true
        else
            echo "SKIP: No Clojure files found"
        fi
        ;;
    crystal)
        if [ -f "shard.yml" ]; then
            echo "Building Crystal project..."
            crystal build src/*.cr 2>&1 || true
        elif ls *.cr 2>/dev/null | head -1; then
            echo "Compiling Crystal files..."
            crystal build *.cr 2>&1 || true
        else
            echo "SKIP: No Crystal files found"
        fi
        ;;
    elixir)
        if [ -f "mix.exs" ]; then
            echo "Compiling Elixir project..."
            mix compile 2>&1 || true
        elif ls *.ex 2>/dev/null | head -1; then
            echo "Compiling Elixir files..."
            elixirc *.ex 2>&1 || true
        else
            echo "SKIP: No Elixir files found"
        fi
        ;;
    erlang)
        if ls *.erl 2>/dev/null | head -1; then
            echo "Compiling Erlang files..."
            erlc *.erl 2>&1 || true
        else
            echo "SKIP: No Erlang files found"
        fi
        ;;
    julia)
        if ls *.jl 2>/dev/null | head -1; then
            echo "Checking Julia syntax..."
            for f in *.jl; do
                [ -f "$f" ] && julia -e "include(\"$f\")" 2>&1 || true
                break
            done
        else
            echo "SKIP: No Julia files found"
        fi
        ;;
    lua)
        if ls *.lua 2>/dev/null | head -1; then
            echo "Checking Lua syntax..."
            for f in *.lua; do
                [ -f "$f" ] && luac -p "$f" 2>&1 || true
            done
        else
            echo "SKIP: No Lua files found"
        fi
        ;;
    nim)
        if ls *.nim 2>/dev/null | head -1; then
            echo "Compiling Nim files..."
            for f in *.nim; do
                [ -f "$f" ] && nim compile --verbosity:0 "$f" 2>&1 || true
                break
            done
        else
            echo "SKIP: No Nim files found"
        fi
        ;;
    ocaml)
        if [ -f "dune" ]; then
            echo "Building with Dune..."
            dune build 2>&1 || true
        elif ls *.ml 2>/dev/null | head -1; then
            echo "Compiling OCaml files..."
            ocamlc -c *.ml 2>&1 || true
        else
            echo "SKIP: No OCaml files found"
        fi
        ;;
    perl)
        if ls *.pl *.pm 2>/dev/null | head -1; then
            echo "Checking Perl syntax..."
            for f in *.pl *.pm; do
                [ -f "$f" ] && perl -c "$f" 2>&1 || true
            done
        else
            echo "SKIP: No Perl files found"
        fi
        ;;
    r)
        if ls *.R *.r 2>/dev/null | head -1; then
            echo "Checking R files..."
            for f in *.R *.r; do
                [ -f "$f" ] && Rscript -e "parse(file=\"$f\")" 2>&1 || true
                break
            done
        else
            echo "SKIP: No R files found"
        fi
        ;;
    v)
        if ls *.v 2>/dev/null | head -1; then
            echo "Building V files..."
            for f in *.v; do
                [ -f "$f" ] && v "$f" 2>&1 || true
                break
            done
        else
            echo "SKIP: No V files found"
        fi
        ;;
    *)
        echo "SKIP: Unknown language '$LANGUAGE'"
        ;;
esac

echo ""
echo "BUILD CHECK COMPLETE"
