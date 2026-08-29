# Slime Soccer (Java) — provenance

## Payload

| file | what | sha256 |
|---|---|---|
| `game/WorldCupSoccerSlime.class` | the original 2002-era "World Cup Soccer Slime" applet, single class file, 24668 bytes, class file version 45.3 (Java 1.1) | `6c02a7400b893618075282f3fb1ed4afc4c65dba777dc6d7a16ce7a867f4ebf1` |
| `game/slime-harness.jar` | our AWT applet harness (`applet-harness/` in this repo), compiled `--release 8` | built from source in-repo |
| `game/applet.conf` | tells the java-launcher which applet class to run (`class=WorldCupSoccerSlime`) | written in-repo |

## Sources (byte-identical from two independent mirrors)

1. mmkal/slimejs GitHub repo, pinned commit (scraped slimegames.eu while live):
   <https://raw.githubusercontent.com/mmkal/slimejs/3879d534137a0645a470214fa7765680adfa40e3/processed/compiled/slimegames-soccer/WorldCupSoccerSlime.class>
2. Wayback Machine raw-bytes capture of the original host:
   <http://web.archive.org/web/20110106100124id_/http://slimegames.eu/soccer/WorldCupSoccerSlime.class>

Both downloads hash to the sha256 above (verified 2026-08-28).

## Original embed

The archived slimegames.eu/soccer/ page (Wayback capture 20110714234543) embeds:

    <applet code="WorldCupSoccerSlime.class" width="700" height="350">

so the app window ships at 700x350.

## Controls

- Player 1: `A` / `D` move, `W` jump, `S` grab (also changes World Cup side in menus)
- Player 2: `J` / `L` move, `I` jump, `K` grab (also changes World Cup side in menus)
- Mouse for menu navigation.

## Behavior audit

Bytecode audit (javap disassembly, 2026-08-28): no network references, no file
I/O, `getParameter` never called. Uses `Applet.showStatus` on every mouse move
(the harness implements it as a no-op) and `getGraphics`/`createImage` from
`init()`. Calls `Thread.stop()` at end of match, which is why the runtime is
pinned to a JRE <= 19 (Temurin 17 via the `ari-flash-jre` cask).

## Icon

`icon.png` is ORIGINAL artwork generated headlessly at authoring time
(Java2D `BufferedImage` -> `ImageIO`, generator kept in the authoring
scratchpad): a green slime half-disc with an eye, a soccer ball, and a goal on
a striped pitch, in the visual style of the game. It deliberately does NOT
reuse slimegames.eu site art, which is copyright A. Bartle 2007 UK.

## Licensing

- slimegames.eu footer (2011 Wayback captures, all game pages): "Website and
  artwork is copyright of A. Bartle 2007 UK. SlimeVolleyball and all its
  variations, unless stated, are copyright of Q. Pendragon 2007 AU."
- oneslime.net/kb/A_Brief_History_Of_Slime.html (live) records for
  Jan 12 2001: "slime goes open-source" — Quin Pendragon proclaimed it on his
  web page and told modders "the source is up there, do it yourself."
- No formal license text has ever been located; the games were distributed as
  free browser applets and copyright is explicitly retained by Q. Pendragon.

Redistribution here rests on that informal 2001 open-source statement — the
ship/no-ship call belongs to the user.
