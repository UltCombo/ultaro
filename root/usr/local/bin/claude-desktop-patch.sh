#!/usr/bin/env bash
set -euo pipefail

echo "==> Updating Node.js and @electron/asar"
source /usr/share/nvm/init-nvm.sh
nvm install node
npm install -g @electron/asar

ASAR=/usr/lib/claude-desktop/resources/app.asar
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

echo "==> Extracting app.asar"
asar extract "$ASAR" "$WORKDIR/extracted"

# Main window title bar -> native. The app builds the main window options as
#   pOr({...,titleBarOverlay:!0,trafficLightPosition:...}) -> {...e,title:...,titleBarStyle:"hidden",icon:...}
# so flip the style in the builder and drop the overlay flag at the call site.
# (Older builds had both inline: titleBarStyle:"hidden",titleBarOverlay:!0.)
TB_STYLE='titleBarStyle:["`]hidden["`],icon:'
TB_OVERLAY='titleBarOverlay:!0,trafficLightPosition:'
TB_LEGACY='titleBarStyle:["`]hidden["`],titleBarOverlay:!0'
MAIN_JS=$(grep -rlE "$TB_STYLE|$TB_LEGACY" "$WORKDIR/extracted" --include="*.js" || true)
if [[ $(wc -l <<<"$MAIN_JS") -gt 1 ]]; then
  echo "!! Title bar pattern matched more than one file, refusing to guess:" >&2
  echo "$MAIN_JS" >&2
  exit 1
elif [[ -n "$MAIN_JS" ]]; then
  echo "==> Patching title bar (titleBarStyle -> default): ${MAIN_JS#"$WORKDIR/extracted/"}"
  sed -i -E \
    -e "s/$TB_LEGACY/titleBarStyle:\"default\"/" \
    -e "s/$TB_STYLE/titleBarStyle:\"default\",icon:/" \
    -e "s/$TB_OVERLAY/trafficLightPosition:/" \
    "$MAIN_JS"
elif grep -rqE 'titleBarStyle:"default",icon:' "$WORKDIR/extracted" --include="*.js"; then
  echo "==> Title bar already patched, skipping"
else
  echo "!! Title bar pattern not found — the app changed, update this script" >&2
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
  --cds-surface-popover: #1e2227 !important;
}
[data-mode=dark] .dframe-root {
  --df-bg-page: var(--cds-surface-1) !important;
}
[data-mode=dark] .dframe-root .dframe-sidebar, [data-mode=dark] .dframe-root .dframe-card {
  --df-sidebar-bg: var(--cds-surface-3) !important;
  --df-web-sidebar-bg: var(--cds-surface-3) !important;
}
.dframe-chrome-bar { padding-right: 12px !important; }
[data-disclaimer="true"], [data-disclaimer="true"] * { color: transparent !important; pointer-events: none !important; }
`;

    // Block Intercom via webRequest. (The app now refuses to start when
    // --host-resolver-rules is on its command line, so DNS mapping is out.)
    // Electron keeps only one onBeforeRequest listener per session and the
    // app registers its own on several sessions, which would replace ours.
    // So wrap each session's onBeforeRequest: whatever listener the app sets
    // is chained behind our Intercom check, and a session the app never
    // touches still gets the check on its own.
    const INTERCOM_DOMAINS = [
      'intercom.io',
      'intercomcdn.com',
      'intercomassets.com',
      'intercomusercontent.com',
      'intercom.help',
    ];
    function isIntercom(url) {
      let host;
      try { host = new URL(url).hostname.toLowerCase(); } catch (e) { return false; }
      return INTERCOM_DOMAINS.some((d) => host === d || host.endsWith('.' + d));
    }
    const GUARDED = Symbol('intercomGuard');
    function guardSession(ses) {
      try {
        const wr = ses.webRequest;
        if (!wr || wr[GUARDED]) return;
        const original = wr.onBeforeRequest.bind(wr);
        const install = (filter, listener) => {
          const chained = (details, callback) => {
            if (isIntercom(details.url)) return callback({ cancel: true });
            if (listener) return listener(details, callback);
            callback({});
          };
          return filter ? original(filter, chained) : original(chained);
        };
        wr.onBeforeRequest = function (filterOrListener, listener) {
          // onBeforeRequest(listener | null) or onBeforeRequest(filter, listener | null)
          if (filterOrListener == null || typeof filterOrListener === 'function') {
            return install(null, filterOrListener || null);
          }
          return install(filterOrListener, listener || null);
        };
        wr[GUARDED] = true;
        install(null, null);
      } catch (e) {}
    }

    // Register our preload against every session (default + any partitioned
    // ones), additive to whatever preload the app's own windows already use.
    const PRELOAD_PATH = path.join(__dirname, 'injected-managed-config-preload.js');
    function addPreload(ses) {
      try {
        const existing = ses.getPreloadScripts();
        if (!existing.some((s) => s.filePath === PRELOAD_PATH)) {
          ses.registerPreloadScript({ type: 'frame', filePath: PRELOAD_PATH });
        }
      } catch (e) {}
    }
    app.whenReady().then(() => {
      guardSession(session.defaultSession);
      addPreload(session.defaultSession);
    });
    if (typeof app.on === 'function') {
      app.on('session-created', (ses) => {
        guardSession(ses);
        addPreload(ses);
      });
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
