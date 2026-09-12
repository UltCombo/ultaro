#!/usr/bin/env bash
set -euo pipefail

echo "==> Updating Node.js and @electron/asar"
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
MAIN_DIR=$(dirname "$MAIN_FILE")

sed -i '/__CLAUDE_DESKTOP_CSS_PATCH__/,/__CLAUDE_DESKTOP_CSS_PATCH_END__/d' "$MAIN_FILE"

# --- write the extra preload file that injects window.desktopManagedConfig ---
echo "==> Writing managed-config preload"
cat > "$MAIN_DIR/injected-managed-config-preload.js" <<'PRELOADEOF'
const { contextBridge } = require('electron');
const CONFIG = {
  deploymentMode: '1p',
  disableEssentialTelemetry: true,
  disableNonessentialTelemetry: true,
};
try {
  contextBridge.exposeInMainWorld('desktopManagedConfig', CONFIG);
} catch (e) {
  // contextIsolation may be off for this webContents; fall back to a direct assignment.
  try { window.desktopManagedConfig = CONFIG; } catch (e2) {}
}
PRELOADEOF

echo "==> Injecting CSS + Block Intercom + Disable all telemetry: $MAIN_REL"
cat > "$WORKDIR/css-patch.js" <<'JSEOF'
/* __CLAUDE_DESKTOP_CSS_PATCH__ */
(function () {
  try {
    const { app, session } = require('electron');
    const path = require('path');

    const CUSTOM_CSS = String.raw`
[data-mode=dark] .cds-root:not([data-mode=light]):not([data-mode=system]), .cds-root[data-mode=dark] {
  --cds-surface-0: #282c34 !important;
  --cds-surface-1: #23272e !important;
  --cds-surface-2: #21252b !important;
  --cds-surface-3: #1e2227 !important;
}
[data-mode=dark] .dframe-root {
  --df-bg-page: var(--cds-surface-1) !important;
}
[data-mode=dark] .dframe-root .dframe-sidebar, [data-mode=dark] .dframe-root .dframe-card {
  --df-sidebar-bg: var(--cds-surface-1) !important;
}
.dframe-chrome-bar { display: none !important; }
.dframe-sidebar, .dframe-content { padding-top: 0 !important; }
.dframe-root[data-variant=web] .df-header-backdrop { right: 0 !important; }
.\[mask-image\:linear-gradient\(to_bottom\,black_66\.67\%\,transparent\)\] { mask-image: linear-gradient(#1e2227 66.67%, #1e222700) !important; background: #1e2227 !important; }
[data-chat-input-container="true"] > [data-disclaimer="true"] { color: transparent !important; }
.dframe-pane-scroller { padding: 0 !important; }
[data-testid="chat-column-body"] { padding-left: calc(var(--spacing) * 2) !important; }
.dframe-chrome-bar { padding-right: 12px !important; }
.shrink-0[style*=titlebar-area-width] { display: none !important; }
`;

    // Must run before 'ready' fires. Blocks Intercom at DNS resolution, so it
    // never connects regardless of scheme (https/wss) or which webRequest
    // listener (if any) the app's own code registers later.
    app.commandLine.appendSwitch(
      'host-resolver-rules',
      [
        'MAP *.intercom.io 127.0.0.1',
        'MAP intercom.io 127.0.0.1',
        'MAP *.intercomcdn.com 127.0.0.1',
        'MAP *.intercomassets.com 127.0.0.1',
        'MAP *.intercomusercontent.com 127.0.0.1',
        'MAP *.intercom.help 127.0.0.1'
      ].join(',')
    );

    // Register our preload against every session (default + any partitioned
    // ones), additive to whatever preload the app's own windows already use.
    const PRELOAD_PATH = path.join(__dirname, 'injected-managed-config-preload.js');
    function addPreload(ses) {
      try {
        const existing = ses.getPreloads ? ses.getPreloads() : [];
        if (!existing.includes(PRELOAD_PATH)) ses.setPreloads([...existing, PRELOAD_PATH]);
      } catch (e) {}
    }
    app.whenReady().then(() => addPreload(session.defaultSession));
    if (typeof app.on === 'function') {
      app.on('session-created', (ses) => addPreload(ses));
    }

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
