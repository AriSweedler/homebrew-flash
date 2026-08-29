# NOTICE — content, licensing, and intended use

This tap exists for the repository owner and their friends to play old web
games on modern Macs. It is strictly PERSONAL, NON-COMMERCIAL use: nothing
here is sold, monetized, or claimed as our own work.

## The tap's own code

The scripts, launchers, casks, and harness in this repository
(`bin/`, `scripts/`, `launcher*/`, `java-launcher/`, `web-launcher/`,
`godot-launcher/`, `applet-harness/`, `Casks/`, `Formula/`, `completions/`)
were written for this tap. No license is currently granted (all rights
reserved) — if that changes, a LICENSE file will appear here and the
formulae will declare it.

## Runtimes (NOT redistributed — downloaded from their official sources)

| runtime | source | license |
|---|---|---|
| Ruffle | github.com/ruffle-rs/ruffle official releases | MIT / Apache-2.0 |
| Godot 3 | github.com/godotengine/godot official releases | MIT |
| Temurin 17 JRE | github.com/adoptium official releases | GPLv2 + Classpath Exception |

The casks fetch these directly from upstream at install time; this repository
hosts none of their bits.

## Game content (hosted in this repository)

| game | origin | status |
|---|---|---|
| Slime Soccer, Slime Volleyball (One Slime), Slime Volleyball 2P | original Java applet bytecode by Quin Pendragon (and collaborators), distributed free on their sites circa 1999–2007 | freeware; Pendragon's informal 2001 "slime goes open-source" statement; no formal license text survives. Per-game PROVENANCE.md records exact sources and hashes. |
| godot-slime-soccer | hectorbennett/slime-soccer | MIT (LICENSE vendored) |
| wip-slime-volleyball | mmkal/slimejs build | MIT (LICENSE vendored) |
| bubble-trouble, get-on-top (Flash swfs) | early-2000s freeware web games, unmodified | abandonware/freeware distributed free by their authors; no license text survives |

The freeware titles are preserved here unmodified, with provenance, solely so
a small circle of friends can keep playing games their authors gave the web
for free — the same spirit in which flashpointarchive.org and archive.org
preserve them. No affiliation with or endorsement by the original authors is
implied.

**Takedown**: if you are a rights holder and want anything removed, open an
issue or contact the repository owner; it will be removed promptly.
