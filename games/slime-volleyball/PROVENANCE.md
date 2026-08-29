# Slime Volleyball (One Slime, official JS port) — provenance

SHIPPED VARIANT (v2.2.0+): the AUTHOR'S OFFICIAL JavaScript port of One Slime
(Quin Pendragon; FAQ credits Daniel Wedge for the One Slime AI), as served on
oneslime.net. Chosen over the 2007 applet: it renders via
requestAnimationFrame — display-synced 60 FPS vs the applet's 50 FPS loop.

| file | what | sha256 |
|---|---|---|
| `web/OneSlime.min.js` | fetched 2026-08-29 from oneslime.net `getscript.php?OneSlime.min.js` | `097b88e7b5009fdb454370af4d16fd3a096403cea2afcec9836434c25e17d872` |
| `web/index.html` | our margin-0 wrapper; canvas 750x375; domain-lock note inline | (ours) |

Audit: zero network surface (no fetch/XHR/php), no audio, no localStorage;
input via window keydown/keyup/mousedown; self-starts on window.onload.
Domain-lock (canvas scale checksum over location.hostname) is inert under
file:// (empty hostname). Upstream may rotate the script — refresh by
re-fetching and bumping.

Controls: left/right arrows move, up arrow jumps (keypad 4/6/8 also work);
click to start. Licensing: Pendragon freeware family — see NOTICE.md.

---
Prior variants: v2.0.0 the 1999 Two Player applet; v2.1.x the 2007 One Slime
applet (bytecode shas in git history at those tags).
