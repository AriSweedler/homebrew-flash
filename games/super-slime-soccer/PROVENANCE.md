# Super Slime Soccer — provenance

Super Slime Soccer by Jens Dahl Møllerhøj (superslimesoccer.io, historically
slime.cc) — a modern, actively-maintained GameMaker HTML5 game. It has no
offline build and no published license, so THIS REPO SHIPS NONE OF IT:
`bin/site-vendor` downloads the game onto the installing machine at install
time (network needed once), and the app then plays fully offline through
web-launcher's in-app URL-scheme server.

Fetched files (from https://www.superslimesoccer.io/):
- `html5game/SSS.js` (~1.7 MB GameMaker export), `html5game/SSS_texture_0.png`,
  `html5game/SSS_texture_1.png`; `html5game/data.ini` is probed but upstream
  itself 404s it (the game defaults its settings).

The repo's own files here: `web/index.html` (our minimal GameMaker boot page,
canvas 560x400), `web/serve.conf` (scheme-server marker), `icon.png`
(user-provided artwork, shared with slime-soccer).

Online-only site features (accounts/sign-in, leaderboards) do not exist in
the offline app; local 1-player and 2-player play is intact. Controls per
the site: arrows + Space (player 1), WASD + 1 (player 2).
