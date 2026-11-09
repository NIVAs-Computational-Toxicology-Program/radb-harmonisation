#!/usr/bin/env bash
# Scaffold a hybrid R + PostgreSQL project.
# Usage: ./setup_project.sh [target_dir]   (defaults to current directory)
# Safe to re-run: never overwrites existing files.

set -euo pipefail

ROOT="${1:-.}"
mkdir -p "$ROOT"
cd "$ROOT"

# --- folders ---------------------------------------------------------------
dirs=(
  sql/schema            # DDL: tables, views, indexes
  sql/queries           # reusable .sql queries called from R
  R                     # helper functions (db connection, cleaning, plotting)
  scripts               # numbered analysis scripts (01_extract.R, 02_explore.R)
  analysis              # Quarto / R Markdown exploration reports
  data/raw              # untouched extracts (gitignored)
  data/processed        # cleaned / cached data (gitignored)
  output/figures        # plots (gitignored)
  output/tables         # exported tables (gitignored)
  output/reports        # rendered reports (gitignored)
  tests/testthat        # tests for R helpers
  docs                  # data dictionary, notes, ERDs
  config                # non-secret config (e.g. config.yml)
)

for entry in "${dirs[@]}"; do
  d="${entry%%[[:space:]]*}"     # strip trailing comment
  mkdir -p "$d"
  # keep empty dirs in git; data/output contents are ignored but .gitkeep is not
  touch "$d/.gitkeep"
done

# --- helper to create a file only if absent --------------------------------
write_if_missing() {
  local path="$1"
  if [[ -e "$path" ]]; then
    echo "skip   $path (exists)"
    cat > /dev/null
  else
    cat > "$path"
    echo "create $path"
  fi
}

# --- .gitignore (skipped if you already have one) --------------------------
write_if_missing .gitignore <<'EOF'
# R
.Rhistory
.RData
.Rproj.user/
.Ruserdata
*.Rproj.user
renv/library/
renv/local/
renv/cellar/
renv/lock/
renv/python/
renv/sandbox/
renv/staging/
.quarto/
*_cache/
*_files/

# Secrets / credentials
.Renviron
.env
*.pgpass
.pgpass
pg_service.conf
*.pem
*.key

# Data & outputs (may contain sensitive DB extracts)
data/raw/*
data/processed/*
output/figures/*
output/tables/*
output/reports/*
!**/.gitkeep

# OS / editor
.DS_Store
Thumbs.db
.vscode/
.idea/
EOF

# --- .Renviron template (copy to .Renviron and fill in) --------------------
write_if_missing .Renviron.example <<'EOF'
PGHOST=localhost
PGPORT=5432
PGDATABASE=
PGUSER=
PGPASSWORD=
EOF

# --- config ----------------------------------------------------------------
write_if_missing config/config.yml <<'EOF'
default:
  schema: public
  raw_dir: data/raw
  processed_dir: data/processed
EOF

# --- .Rprofile (activates renv if present) ---------------------------------
# write_if_missing .Rprofile <<'EOF'
# if (file.exists("renv/activate.R")) source("renv/activate.R")
# EOF

# --- README stub ------------------------------------------------------------
write_if_missing README.md <<'EOF'
# Project name

## Setup
1. `cp .Renviron.example .Renviron` and fill in DB credentials.
2. Restart R, then `renv::restore()` (once `renv::init()` has been run).

## Layout
| Path | Purpose |
|------|---------|
| `sql/` | Schema, queries and migrations |
| `R/` | Reusable R functions |
| `scripts/` | Numbered analysis scripts |
| `analysis/` | Quarto / Rmd exploration |
| `data/` | Extracts (gitignored) |
| `output/` | Figures, tables, reports (gitignored) |
| `tests/` | testthat tests |
| `docs/` | Data dictionary and notes |
EOF

echo
echo "Done. Next steps:"
# echo "  - In R: renv::init()  (and usethis::use_rstudio() if you want an .Rproj)"
echo "  - cp .Renviron.example .Renviron  and fill in credentials"
