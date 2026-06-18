#!/usr/bin/env bash
set -euo pipefail

echo "=== Dependency Hell Check ==="
FAILED=0

# 1. Check for multiple package managers in the same project (conflict indicator)
echo "--- Checking for package manager conflicts ---"
MANAGERS=()
[ -f "package.json" ] && MANAGERS+=("npm/node")
[ -f "yarn.lock" ] && MANAGERS+=("yarn")
[ -f "pnpm-lock.yaml" ] && MANAGERS+=("pnpm")
[ -f "Cargo.toml" ] && MANAGERS+=("cargo")
[ -f "go.mod" ] && MANAGERS+=("go")
[ -f "Gemfile" ] && MANAGERS+=("bundler")
[ -f "requirements.txt" ] && MANAGERS+=("pip")
[ -f "Pipfile" ] && MANAGERS+=("pipenv")
[ -f "poetry.lock" ] && MANAGERS+=("poetry")
[ -f "composer.json" ] && MANAGERS+=("composer")
[ -f "build.gradle" ] && MANAGERS+=("gradle")
[ -f "pom.xml" ] && MANAGERS+=("maven")
[ -f "mix.exs" ] && MANAGERS+=("mix")
[ -f "shard.yml" ] && MANAGERS+=("shards")
[ -f "dub.sdl" ] || [ -f "dub.json" ] && MANAGERS+=("dub")
[ -f "Makefile.PL" ] || [ -f "cpanfile" ] && MANAGERS+=("cpan")

if [ ${#MANAGERS[@]} -gt 2 ]; then
    echo "WARNING: Multiple package managers detected (${MANAGERS[*]}). This may cause dependency conflicts."
fi

# 2. npm/node dependency check
if [ -f "package.json" ]; then
    echo "--- Checking npm/node dependencies ---"
    if [ -f "package-lock.json" ] || [ -f "yarn.lock" ] || [ -f "pnpm-lock.yaml" ]; then
        echo "OK: Lockfile present"
    else
        echo "WARNING: package.json found but no lockfile. Lockfile recommended for reproducible builds."
    fi

    # Check for known malicious npm packages
    MALICIOUS_PKGS=("event-stream" "flatmap-stream" "eslint-scope" "node_modules")
    for pkg in "${MALICIOUS_PKGS[@]}"; do
        if grep -q "\"$pkg\"" package.json 2>/dev/null; then
            echo "WARNING: Potentially risky package '$pkg' found in package.json"
            FAILED=1
        fi
    done
fi

# 3. Rust/Cargo dependency check
if [ -f "Cargo.toml" ]; then
    echo "--- Checking Rust dependencies ---"
    if grep -qi 'git\s*=\s*"[^"]*"' Cargo.toml 2>/dev/null; then
        echo "INFO: Git dependencies found in Cargo.toml (ensure pinned commits)"
    fi
    if grep -qi 'path\s*=\s*"[^"]*"' Cargo.toml 2>/dev/null; then
        echo "INFO: Path dependencies found in Cargo.toml"
    fi
fi

# 4. Python dependency check
if [ -f "requirements.txt" ]; then
    echo "--- Checking Python dependencies ---"
    if grep -qi '\-e git+' requirements.txt 2>/dev/null; then
        echo "INFO: Editable git installs in requirements.txt"
    fi
    # Check for unpinned versions
    UNPINNED=$(grep -cP '^[a-zA-Z][a-zA-Z0-9_.-]+(?:\s*>=\s*[0-9])*$' requirements.txt 2>/dev/null || true)
    if [ "$UNPINNED" -gt 0 ]; then
        echo "WARNING: $UNPINNED unpinned dependencies found in requirements.txt. Pin versions to avoid dependency hell."
    fi
fi

# 5. Check for conflicting dependency directories
echo "--- Checking for dependency directory conflicts ---"
while IFS= read -r -d '' dir; do
    echo "INFO: Dependency directory found: $dir"
done < <(find . -maxdepth 2 -type d \( -name "node_modules" -o -name "vendor" -o -name ".cargo" -o -name "target" \) -print0 2>/dev/null || true)

# 6. Check for overly broad dependency versions
echo "--- Checking for overly broad version ranges ---"
for f in package.json Cargo.toml composer.json; do
    if [ -f "$f" ]; then
        if grep -Pq '"\*"' "$f" 2>/dev/null; then
            echo "WARNING: Wildcard dependency found in $f. Specify exact versions."
        fi
    fi
done

echo ""
if [ "$FAILED" -eq 1 ]; then
    echo "RESULT: FAILED - Dependency issues found"
    exit 1
else
    echo "RESULT: PASSED - Dependencies look clean"
    exit 0
fi
