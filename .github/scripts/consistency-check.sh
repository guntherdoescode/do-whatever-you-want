#!/usr/bin/env bash
set -euo pipefail

echo "=== Codebase Consistency Check ==="
FAILED=0

# 1. Check for .gitkeep files that exist alongside real files (stale structure)
echo "--- Checking for stale .gitkeep files ---"
while IFS= read -r -d '' keep; do
    dir=$(dirname "$keep")
    other=$(find "$dir" -type f ! -name '.gitkeep' 2>/dev/null | head -1)
    if [ -n "$other" ]; then
        echo "WARNING: Stale .gitkeep in $dir (other files exist)"
    fi
done < <(find . -path ./.git -prune -o -name '.gitkeep' -type f -print0 2>/dev/null || true)

# 2. Check for conflicting config files (signs of project mismatch)
echo "--- Checking for conflicting project configurations ---"
CONFLICT_PAIRS=(
    "package.json:Cargo.toml"
    "package.json:go.mod"
    "Cargo.toml:go.mod"
    "setup.py:package.json"
    "requirements.txt:Cargo.toml"
    "pom.xml:Cargo.toml"
    "build.gradle:pom.xml"
)

for pair in "${CONFLICT_PAIRS[@]}"; do
    file1="${pair%%:*}"
    file2="${pair##*:}"
    if [ -f "$file1" ] && [ -f "$file2" ]; then
        echo "INFO: Both $file1 and $file2 exist (mixed-language project)"
    fi
done

# 3. Check for empty directories
echo "--- Checking for empty directories ---"
while IFS= read -r -d '' dir; do
    if [ -z "$(find "$dir" -mindepth 1 -maxdepth 1 2>/dev/null)" ]; then
        echo "WARNING: Empty directory: $dir"
    fi
done < <(find . -path ./.git -prune -o -type d -print0 2>/dev/null || true)

# 4. Check for README in subdirectories (organization)
echo "--- Checking for organizational structure ---"
SUBDIRS=$(find . -path ./.git -prune -o -mindepth 2 -maxdepth 2 -type d -print 2>/dev/null || true)
if [ -n "$SUBDIRS" ]; then
    echo "INFO: Subdirectories found. Ensure each has appropriate documentation."
fi

# 5. Check for consistent line endings
echo "--- Checking line endings ---"
while IFS= read -r -d '' file; do
    if file "$file" | grep -q 'CRLF'; then
        echo "INFO: CRLF line endings in $file (consider using LF)"
    fi
done < <(find . -path ./.git -prune -o -type f -print0 2>/dev/null || true)

# 6. Check for BOM markers
echo "--- Checking for BOM markers ---"
while IFS= read -r -d '' file; do
    if head -c 3 "$file" | od -A n -t x1 | grep -q 'ef bb bf'; then
        echo "INFO: UTF-8 BOM detected in $file"
    fi
done < <(find . -path ./.git -prune -o -type f -print0 2>/dev/null || true)

echo ""
if [ "$FAILED" -eq 1 ]; then
    echo "RESULT: FAILED - Consistency issues found"
    exit 1
else
    echo "RESULT: PASSED - Codebase looks consistent"
    exit 0
fi
