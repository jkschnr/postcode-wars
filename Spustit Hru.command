#!/bin/bash
# ===========================================================================
#  POSTCODE WARS (ENDS) — Spustit Hru / Run the Game
#  Double-click to play the click-only crime RPG in Godot.
# ===========================================================================

cd "$(dirname "$0")" || exit 1

clear
echo ""
echo "   POSTCODE WARS — ENDS"
echo "   from wasteman to Top Boy, one postcode at a time"
echo ""

# Find a Godot 4 binary
GODOT=""
for cand in godot /opt/homebrew/bin/godot /usr/local/bin/godot \
            "/Applications/Godot.app/Contents/MacOS/Godot"; do
  if command -v "$cand" >/dev/null 2>&1 || [ -x "$cand" ]; then
    GODOT="$cand"; break
  fi
done

if [ -z "$GODOT" ]; then
  echo "  ⚠  Godot 4 not found."
  echo "     Install it from https://godotengine.org (or 'brew install godot'),"
  echo "     then double-click this file again."
  echo ""
  read -r -p "  Press Enter to close."
  exit 1
fi

echo "  Launching with: $GODOT"
echo "  (Close the game window to stop.)"
echo ""

# Run the game (portrait window). To EDIT instead, open ./godot in the Godot editor.
"$GODOT" --path godot
