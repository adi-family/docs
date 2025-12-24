#!/bin/bash
# Generate documentation pages from README/CLAUDE.md files
# Usage: ./generate.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRATES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/crates"
OUTPUT_DIR="$SCRIPT_DIR/libs"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# HTML template header
cat > "$OUTPUT_DIR/_header.html" << 'HEADER'
<!DOCTYPE html>
<html lang="en" class="dark">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{TITLE}} - adi-family docs</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script>
    tailwind.config = {
      darkMode: 'class',
      theme: {
        extend: {
          colors: {
            dark: { 900: '#0a0a0f', 800: '#12121a', 700: '#1a1a24', 600: '#22222e' },
            accent: { 500: '#8b5cf6', 400: '#a78bfa', 300: '#c4b5fd' }
          },
          fontFamily: {
            sans: ['Inter', 'system-ui', 'sans-serif'],
            mono: ['JetBrains Mono', 'Fira Code', 'monospace'],
          }
        }
      }
    }
  </script>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-rust.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-bash.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-toml.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-json.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-yaml.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-docker.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-nginx.min.js"></script>
  <style>
    html { scroll-behavior: smooth; }
    body { font-family: 'Inter', system-ui, sans-serif; }
    code, pre { font-family: 'JetBrains Mono', monospace; }
    .glass { background: rgba(26, 26, 36, 0.7); backdrop-filter: blur(12px); }
    .gradient-border { position: relative; }
    .gradient-border::before {
      content: ''; position: absolute; inset: 0; border-radius: inherit; padding: 1px;
      background: linear-gradient(135deg, rgba(139, 92, 246, 0.5), rgba(139, 92, 246, 0.1));
      -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
      mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
      -webkit-mask-composite: xor; mask-composite: exclude;
    }
    ::-webkit-scrollbar { width: 8px; height: 8px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: #22222e; border-radius: 4px; }

    /* Markdown content styles */
    .prose { }
    .prose h1 { font-size: 2rem; font-weight: 700; color: white; margin-bottom: 1rem; margin-top: 2rem; }
    .prose h2 { font-size: 1.5rem; font-weight: 600; color: white; margin-bottom: 0.75rem; margin-top: 1.5rem; border-bottom: 1px solid rgba(255,255,255,0.1); padding-bottom: 0.5rem; }
    .prose h3 { font-size: 1.25rem; font-weight: 600; color: white; margin-bottom: 0.5rem; margin-top: 1.25rem; }
    .prose h4 { font-size: 1rem; font-weight: 600; color: white; margin-bottom: 0.5rem; margin-top: 1rem; }
    .prose p { color: #9ca3af; margin-bottom: 1rem; line-height: 1.7; }
    .prose ul, .prose ol { color: #9ca3af; margin-bottom: 1rem; padding-left: 1.5rem; }
    .prose li { margin-bottom: 0.5rem; }
    .prose ul { list-style-type: disc; }
    .prose ol { list-style-type: decimal; }
    .prose code:not(pre code) { background: #1a1a24; padding: 0.2rem 0.4rem; border-radius: 0.25rem; color: #a78bfa; font-size: 0.875rem; }
    .prose pre { background: #1a1a24 !important; border: 1px solid rgba(255,255,255,0.05); border-radius: 0.5rem; padding: 1rem; overflow-x: auto; margin-bottom: 1rem; }
    .prose pre code { background: transparent !important; padding: 0; font-size: 0.875rem; }
    .prose pre[class*="language-"] { background: #1a1a24 !important; }
    code[class*="language-"], pre[class*="language-"] { text-shadow: none !important; }
    .prose a { color: #a78bfa; text-decoration: underline; }
    .prose a:hover { color: #c4b5fd; }
    .prose table { width: 100%; border-collapse: collapse; margin-bottom: 1rem; }
    .prose th { text-align: left; padding: 0.75rem; background: #1a1a24; color: white; font-weight: 500; border: 1px solid rgba(255,255,255,0.05); }
    .prose td { padding: 0.75rem; color: #9ca3af; border: 1px solid rgba(255,255,255,0.05); }
    .prose blockquote { border-left: 4px solid #8b5cf6; padding-left: 1rem; margin-left: 0; color: #9ca3af; font-style: italic; }
    .prose hr { border: none; border-top: 1px solid rgba(255,255,255,0.1); margin: 2rem 0; }
    .prose strong { color: white; }
  </style>
</head>
<body class="bg-dark-900 text-gray-300 antialiased">
  <div class="fixed inset-0 overflow-hidden pointer-events-none">
    <div class="absolute -top-40 -right-40 w-80 h-80 bg-accent-500/20 rounded-full blur-[100px]"></div>
    <div class="absolute top-1/2 -left-40 w-80 h-80 bg-accent-500/10 rounded-full blur-[100px]"></div>
  </div>

  <div class="relative min-h-screen">
    <header class="sticky top-0 z-30 glass border-b border-white/5">
      <div class="max-w-4xl mx-auto px-8 py-4 flex items-center justify-between">
        <div class="flex items-center gap-4">
          <a href="../index.html" class="flex items-center gap-2 text-gray-400 hover:text-white transition-colors">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
            <span>Back to docs</span>
          </a>
        </div>
        <span class="px-2 py-1 text-xs font-medium text-accent-400 bg-accent-500/10 rounded-full">{{BADGE}}</span>
      </div>
    </header>

    <main class="max-w-4xl mx-auto px-8 py-12">
      <div class="prose">
HEADER

# HTML template footer
cat > "$OUTPUT_DIR/_footer.html" << 'FOOTER'
      </div>
    </main>

    <footer class="max-w-4xl mx-auto px-8 py-8 border-t border-white/5">
      <div class="flex items-center justify-between text-sm text-gray-500">
        <a href="../index.html" class="hover:text-gray-300 transition-colors">Back to documentation</a>
        <span>adi-family</span>
      </div>
    </footer>
  </div>
  <script>
    document.addEventListener('DOMContentLoaded', function() {
      if (typeof Prism !== 'undefined') {
        Prism.highlightAll();
      }
    });
  </script>
</body>
</html>
FOOTER

# Function to convert markdown to HTML
convert_md_to_html() {
    local input="$1"

    # Use sed for basic markdown conversion
    cat "$input" | \
    # Escape HTML special chars first (but preserve markdown)
    sed 's/&/\&amp;/g' | \
    # Code blocks (```lang ... ```) - must be before other processing
    awk '
    BEGIN { in_code = 0 }
    /^```/ {
        if (in_code) {
            print "</code></pre>"
            in_code = 0
        } else {
            lang = substr($0, 4)
            if (lang == "") lang = "text"
            print "<pre><code class=\"language-" lang "\">"
            in_code = 1
        }
        next
    }
    { print }
    ' | \
    # Inline code
    sed 's/`\([^`]*\)`/<code>\1<\/code>/g' | \
    # Headers
    sed 's/^###### \(.*\)$/<h6>\1<\/h6>/' | \
    sed 's/^##### \(.*\)$/<h5>\1<\/h5>/' | \
    sed 's/^#### \(.*\)$/<h4>\1<\/h4>/' | \
    sed 's/^### \(.*\)$/<h3>\1<\/h3>/' | \
    sed 's/^## \(.*\)$/<h2>\1<\/h2>/' | \
    sed 's/^# \(.*\)$/<h1>\1<\/h1>/' | \
    # Bold and italic
    sed 's/\*\*\([^*]*\)\*\*/<strong>\1<\/strong>/g' | \
    sed 's/\*\([^*]*\)\*/<em>\1<\/em>/g' | \
    # Links
    sed 's/\[\([^]]*\)\](\([^)]*\))/<a href="\2">\1<\/a>/g' | \
    # Horizontal rules
    sed 's/^---$/<hr>/' | \
    sed 's/^___$/<hr>/' | \
    # Unordered lists
    sed 's/^- \(.*\)$/<li>\1<\/li>/' | \
    sed 's/^  - \(.*\)$/<li>\1<\/li>/' | \
    sed 's/^\* \(.*\)$/<li>\1<\/li>/' | \
    # Tables (proper markdown table support)
    awk '
    BEGIN { in_table = 0; is_header = 1 }
    /^\|.*\|$/ {
        # Skip separator rows (|---|---|)
        if ($0 ~ /^\|[-: |]+\|$/) {
            is_header = 0
            next
        }
        if (!in_table) {
            print "<table>"
            in_table = 1
            is_header = 1
        }
        # Remove leading/trailing pipes and split
        gsub(/^\||\|$/, "")
        n = split($0, cells, "|")
        if (is_header) {
            print "<thead><tr>"
            for (i = 1; i <= n; i++) {
                gsub(/^[ \t]+|[ \t]+$/, "", cells[i])
                print "<th>" cells[i] "</th>"
            }
            print "</tr></thead><tbody>"
            is_header = 0
        } else {
            print "<tr>"
            for (i = 1; i <= n; i++) {
                gsub(/^[ \t]+|[ \t]+$/, "", cells[i])
                print "<td>" cells[i] "</td>"
            }
            print "</tr>"
        }
        next
    }
    {
        if (in_table) {
            print "</tbody></table>"
            in_table = 0
            is_header = 1
        }
        print
    }
    END {
        if (in_table) print "</tbody></table>"
    }
    ' | \
    # Wrap paragraphs (lines that don't start with < and aren't empty)
    awk '
    {
        if ($0 ~ /^</ || $0 ~ /^$/ || $0 ~ /^<li>/) {
            print
        } else {
            print "<p>" $0 "</p>"
        }
    }
    ' | \
    # Group list items
    awk '
    BEGIN { in_list = 0 }
    /<li>/ {
        if (!in_list) { print "<ul>"; in_list = 1 }
        print
        next
    }
    {
        if (in_list) { print "</ul>"; in_list = 0 }
        print
    }
    END { if (in_list) print "</ul>" }
    '
}

# Function to get library category badge
get_badge() {
    local name="$1"
    case "$name" in
        lib-plugin-*|adi-plugin-registry-http) echo "Plugin System" ;;
        lib-llm-*|lib-anthropic-*|lib-openai-*|lib-ollama-*) echo "LLM" ;;
        lib-color|lib-animation|lib-terminal-*|lib-syntax-*|lib-json-*|lib-iced-*|debug-metal-*) echo "UI" ;;
        adi-indexer-*) echo "Indexer" ;;
        adi-knowledgebase-*) echo "Knowledgebase" ;;
        adi-tasks-*) echo "Tasks" ;;
        adi-agent-*) echo "Agent Loop" ;;
        adi-executor|adi-worker) echo "Executor" ;;
        adi-cli) echo "CLI" ;;
        *) echo "Library" ;;
    esac
}

# Generate index of all libraries
generate_index() {
    local libs_json="["
    local first=true

    for dir in "$CRATES_DIR"/*/; do
        local name=$(basename "$dir")
        local readme=""
        local title="$name"
        local desc=""

        # Find documentation file
        if [ -f "$dir/README.md" ]; then
            readme="$dir/README.md"
        elif [ -f "$dir/CLAUDE.md" ]; then
            readme="$dir/CLAUDE.md"
        fi

        # Get description from Cargo.toml
        if [ -f "$dir/Cargo.toml" ]; then
            desc=$(grep '^description' "$dir/Cargo.toml" 2>/dev/null | head -1 | sed 's/description = "\(.*\)"/\1/' || echo "")
        fi

        if [ -n "$readme" ]; then
            local badge=$(get_badge "$name")

            if [ "$first" = true ]; then
                first=false
            else
                libs_json+=","
            fi
            libs_json+="{\"name\":\"$name\",\"badge\":\"$badge\",\"desc\":\"$desc\"}"
        fi
    done

    libs_json+="]"
    echo "$libs_json" > "$OUTPUT_DIR/index.json"
}

# Process each crate
echo "Generating library documentation..."

for dir in "$CRATES_DIR"/*/; do
    name=$(basename "$dir")
    readme=""

    # Find documentation file (prefer README.md over CLAUDE.md)
    if [ -f "$dir/README.md" ]; then
        readme="$dir/README.md"
    elif [ -f "$dir/CLAUDE.md" ]; then
        readme="$dir/CLAUDE.md"
    fi

    if [ -n "$readme" ]; then
        echo "  Processing: $name"

        badge=$(get_badge "$name")
        output_file="$OUTPUT_DIR/$name.html"

        # Generate HTML
        header=$(cat "$OUTPUT_DIR/_header.html" | sed "s/{{TITLE}}/$name/g" | sed "s/{{BADGE}}/$badge/g")
        content=$(convert_md_to_html "$readme")
        footer=$(cat "$OUTPUT_DIR/_footer.html")

        echo "$header" > "$output_file"
        echo "$content" >> "$output_file"
        echo "$footer" >> "$output_file"
    fi
done

# Generate index
generate_index

# Clean up templates
rm -f "$OUTPUT_DIR/_header.html" "$OUTPUT_DIR/_footer.html"

echo ""
echo "Generated $(ls -1 "$OUTPUT_DIR"/*.html 2>/dev/null | wc -l | tr -d ' ') library pages in $OUTPUT_DIR/"
echo "Index written to $OUTPUT_DIR/index.json"
