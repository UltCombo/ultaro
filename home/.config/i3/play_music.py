import json, requests, websocket

CDP_PORT = 9222
WATCH_URL = "https://music.youtube.com/watch?list=PL5sLVFzDBpqlyjXM6s6jozOKR018aDr8Q&shuffle=1"
INCOGNITO_NEWTAB_MARKER = "duckduckgo.com/?q=&t=vivaldi"

INIT_SCRIPT = """
(function() {
  function clickRepeatOnce() {
    var btn = document.querySelector('yt-icon-button.repeat');
    if (!btn) return setTimeout(clickRepeatOnce, 400);
    btn.click();
  }
  function setVolumeOnce() {
    var slider = document.querySelector('#volume-slider');
    if (!slider) return setTimeout(setVolumeOnce, 400);
    slider.value = 60;
    slider.dispatchEvent(new CustomEvent('immediate-value-change', {bubbles: true, composed: true}));
    slider.dispatchEvent(new Event('change', {bubbles: true, composed: true}));
  }
  document.addEventListener('DOMContentLoaded', function() {
    clickRepeatOnce();
    setVolumeOnce();
  });
})();
"""

def rpc(ws, method, params=None, _id=[0]):
    _id[0] += 1
    ws.send(json.dumps({"id": _id[0], "method": method, "params": params or {}}))
    while True:
        resp = json.loads(ws.recv())
        if resp.get("id") == _id[0]:
            if "error" in resp:
                raise RuntimeError(f"{method} failed: {resp['error']}")
            return resp["result"]

browser_ws_url = requests.get(f"http://localhost:{CDP_PORT}/json/version").json()["webSocketDebuggerUrl"]
bws = websocket.create_connection(browser_ws_url)
targets = rpc(bws, "Target.getTargets")["targetInfos"]
incognito_tab = next(t for t in targets
                      if t["type"] == "page" and INCOGNITO_NEWTAB_MARKER in t["url"])
bws.close()

page_info = next(t for t in requests.get(f"http://localhost:{CDP_PORT}/json/list").json()
                  if t["id"] == incognito_tab["targetId"])
ws = websocket.create_connection(page_info["webSocketDebuggerUrl"])

rpc(ws, "Page.enable")
rpc(ws, "Network.enable")
rpc(ws, "Page.addScriptToEvaluateOnNewDocument", {"source": INIT_SCRIPT})
rpc(ws, "Page.navigate", {"url": WATCH_URL})
ws.close()
