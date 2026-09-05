#!/usr/bin/env bash
set -euo pipefail

source /usr/share/nvm/init-nvm.sh
nvm install node
nvm use node
npm install -g @electron/asar

ASAR=/usr/lib/claude-desktop/resources/app.asar
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

echo "==> Extracting app.asar"
asar extract "$ASAR" "$WORKDIR/extracted"

MAIN_JS=$(grep -rl 'titleBarStyle:`hidden`,titleBarOverlay:!0' "$WORKDIR/extracted" --include="*.js" || true)
if [[ -n "$MAIN_JS" ]]; then
  echo "==> Patching title bar (titleBarStyle -> default)"
  sed -i 's/titleBarStyle:`hidden`,titleBarOverlay:!0/titleBarStyle:`default`/' "$MAIN_JS"
else
  echo "==> Title bar already patched, skipping"
fi

MAIN_REL=$(node -e "console.log(require('$WORKDIR/extracted/package.json').main)")
MAIN_FILE="$WORKDIR/extracted/$MAIN_REL"
[[ -f "$MAIN_FILE" ]] || { echo "!! No main entry at $MAIN_FILE" >&2; exit 1; }

sed -i '/__CLAUDE_DESKTOP_CSS_PATCH__/,/__CLAUDE_DESKTOP_CSS_PATCH_END__/d' "$MAIN_FILE"

echo "==> Injecting CSS patch into: $MAIN_REL"
cat > "$WORKDIR/css-patch.js" <<'JSEOF'
/* __CLAUDE_DESKTOP_CSS_PATCH__ */
(function () {
  try {
    const { app } = require('electron');

    const CUSTOM_CSS = String.raw`
[data-mode=dark] .cds-root:not([data-mode=light]):not([data-mode=system]), .cds-root[data-mode=dark] { --cds-surface-1: #23272e !important; }
.dframe-content { background: #23272e !important; padding-top: 0 !important; }
.dframe-root[data-variant=web] .df-header-backdrop { right: 0 !important; }
.\[mask-image\:linear-gradient\(to_bottom\,black_66\.67\%\,transparent\)\] { mask-image: linear-gradient(#1e2227 66.67%, #1e222700) !important; background: #1e2227 !important; }
[data-chat-input-container="true"] > [data-disclaimer="true"] > a { visibility: hidden !important; }
.bg-surface-3 { background: #1e2227 !important; }
.dframe-pane-scroller { padding: 0 !important; }
[data-testid="chat-column-body"] { padding-left: calc(var(--spacing) * 2) !important; }
.dframe-chrome-bar { padding-right: 12px !important; }
.shrink-0[style*=titlebar-area-width] { display: none !important; }
`;

    app.on('web-contents-created', (_event, contents) => {
      contents.on('did-finish-load', () => {
        contents.insertCSS(CUSTOM_CSS).catch(() => {});
      });
    });
  } catch (err) {
    // fail silently — a broken patch should never block the app from launching
  }
})();
/* __CLAUDE_DESKTOP_CSS_PATCH_END__ */
JSEOF
cat "$WORKDIR/css-patch.js" "$MAIN_FILE" > "$MAIN_FILE.new"
mv "$MAIN_FILE.new" "$MAIN_FILE"

echo "==> Repacking app.asar"
asar pack "$WORKDIR/extracted" "$WORKDIR/app.asar"
echo "==> Installing patched app.asar"
cp "$WORKDIR/app.asar" "$ASAR"
echo "==> Done"
