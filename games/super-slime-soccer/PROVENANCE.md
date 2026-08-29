# Super Slime Soccer — provenance

Super Slime Soccer by Jens Dahl Møllerhøj (superslimesoccer.io, historically
slime.cc) — a modern, actively-maintained HTML5 successor to the classic
slime games. It has no offline build and no published license, so THIS CASK
REDISTRIBUTES NOTHING of the game: the app is our WKWebView wrapper loading
the live site (web/site.conf `url=` line). Network is required at play time.
Progress/unlocks persist in the wrapper's own localStorage (per bundle id),
covered by the cask's zap stanzas.

Icon: user-provided artwork (shared with slime-soccer).
