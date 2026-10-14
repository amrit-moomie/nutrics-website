#!/usr/bin/env bash
# publish-deck.sh — put the latest public investor deck at the one public deck URL:
#   https://www.nutrics.ca/guides/nutrics-deck.pdf
# Usage: ./scripts/publish-deck.sh [path/to/Nutrics-Deck-V…-Public.pdf]
#        then ./scripts/deploy.sh to make it live.
# With no argument it takes the highest-numbered Nutrics-Deck-V*-Public.pdf in the Dropbox BDC
# folder (version sort, so V8.10 beats V8.9). Versioned deck URLs (…-V8.4-Public.pdf etc.) 301
# to the single URL (see deploy.sh), so guides/ keeps only nutrics-deck.pdf.

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DECKS="${NUTRICS_DECKS:-$HOME/Library/CloudStorage/Dropbox/Nutrics/BDC}"
TARGET="$REPO/guides/nutrics-deck.pdf"

if [ $# -ge 1 ]; then
  SRC="$1"
else
  SRC="$(ls "$DECKS"/Nutrics-Deck-V*-Public.pdf 2>/dev/null | sort -V | tail -1 || true)"
fi
if [ -z "${SRC:-}" ] || [ ! -f "$SRC" ]; then
  echo "No deck found (looked for Nutrics-Deck-V*-Public.pdf in $DECKS)." >&2
  exit 1
fi

cp "$SRC" "$TARGET"
# One deck file only: versioned copies would just shadow the redirect.
find "$REPO/guides" -maxdepth 1 -name 'Nutrics-Deck-V*.pdf' -delete

echo "Published $(basename "$SRC") -> guides/nutrics-deck.pdf ($(wc -c < "$TARGET" | tr -d ' ') bytes)"
echo "Run ./scripts/deploy.sh to make it live at https://www.nutrics.ca/guides/nutrics-deck.pdf"
