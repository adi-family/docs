#!/bin/bash
# Generate dependency graph data from Cargo.toml files
# Usage: ./generate-deps.sh > deps.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRATES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/crates"

# Category mapping based on crate name patterns
get_category() {
    local name="$1"
    case "$name" in
        adi-cli|adi-executor|lib-llm-providers)
            echo "core"
            ;;
        lib-cli-common|lib-migrations|lib-embed)
            echo "shared"
            ;;
        *-core)
            echo "component"
            ;;
        *-cli|*-http|*-mcp|*-plugin)
            echo "interface"
            ;;
        lib-plugin-*)
            echo "plugin"
            ;;
        adi-plugin-*)
            echo "plugin"
            ;;
        lib-color|lib-animation|lib-syntax-highlight|lib-terminal-*|lib-json-tree|lib-iced-ui)
            echo "ui"
            ;;
        lib-github-client|lib-anthropic-client|lib-openai-client|lib-ollama-client)
            echo "api"
            ;;
        *)
            echo "shared"
            ;;
    esac
}

echo "// Auto-generated dependency graph data"
echo "// Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""
echo "const nodes = ["

# Generate nodes
first_node=true
for cargo_toml in "$CRATES_DIR"/*/Cargo.toml; do
    dir=$(dirname "$cargo_toml")
    name=$(basename "$dir")

    # Skip non-library crates
    case "$name" in
        tool-*|debug-*|adi-worker)
            continue
            ;;
    esac

    category=$(get_category "$name")

    if [ "$first_node" = true ]; then
        first_node=false
    else
        echo ","
    fi
    printf '  { id: "%s", category: "%s", label: "%s" }' "$name" "$category" "$name"
done
echo ""
echo "];"
echo ""
echo "const links = ["

# Generate links
first_link=true
for cargo_toml in "$CRATES_DIR"/*/Cargo.toml; do
    dir=$(dirname "$cargo_toml")
    source=$(basename "$dir")

    # Skip non-library crates
    case "$source" in
        tool-*|debug-*|adi-worker)
            continue
            ;;
    esac

    # Extract internal dependencies (lib-* and adi-*)
    # Handles both path deps and workspace deps
    deps=$(grep -E '^\s*(lib-|adi-)[a-z-]+' "$cargo_toml" 2>/dev/null | \
           grep -v '^\s*#' | \
           sed 's/\s*[=\.].*$//' | \
           sed 's/^\s*//' | \
           grep -v "^$" | \
           sort -u || true)

    for dep in $deps; do
        # Skip self-references
        if [ "$dep" = "$source" ]; then
            continue
        fi

        # Skip adi-worker and non-workspace crates
        if [ "$dep" = "adi-worker" ]; then
            continue
        fi

        # Skip if target crate doesn't exist in workspace
        if [ ! -d "$CRATES_DIR/$dep" ]; then
            continue
        fi

        if [ "$first_link" = true ]; then
            first_link=false
        else
            echo ","
        fi
        printf '  { source: "%s", target: "%s" }' "$source" "$dep"
    done
done
echo ""
echo "];"
