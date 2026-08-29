# Slime Volleyball (Java) — provenance

## Payload

| file | what | sha256 |
|---|---|---|
| `game/slime.class` | the ORIGINAL "Two Player Slime" volleyball applet (Quin Pendragon, Aug 1999), single class file, 11057 bytes, class file version 45.3 (Java 1.1). Class name is lowercase `slime` — load-bearing in `applet.conf`. | `e0cf8009a351dc226b6546e99ef649462543f4b7663733b21dae20ce6e1d47ef` |
| `game/slime-harness.jar` | our AWT applet harness (`applet-harness/` in this repo), compiled `--release 8` | built from source in-repo |
| `game/applet.conf` | tells the java-launcher which applet class to run (`class=slime`) | written in-repo |

## Sources (byte-identical from two independent mirrors)

1. mmkal/slimejs GitHub repo, pinned commit (scraped slimegames.eu while live):
   <https://raw.githubusercontent.com/mmkal/slimejs/3879d534137a0645a470214fa7765680adfa40e3/processed/compiled/slimegames-volleyball-original/slime.class>
2. Wayback Machine raw-bytes capture of the original host:
   <http://web.archive.org/web/20110106095813id_/http://slimegames.eu/volleyball-original/slime.class>

Both downloads hash to the sha256 above (verified 2026-08-28).

## Original embed and window size

The archived slimegames.eu/volleyball-original/ page (Wayback capture
20151123231244) embeds:

    <applet code="slime.class" width="600" height="350">

The applet's internal playfield is 600x400 (YSIZE=400); at the authentic
600x350 embed the bottom 50px ground band is CLIPPED. This matches the site's
own screenshot of the game, so 600x350 is the shipped size — the authentic
clipped look. A 600x400 window (full ground band visible) is a deliberate
non-shipped variant.

## Controls

- `left` / `right` to move plus `space` to jump — or `4` / `6` on the numeric
  keypad.
- Two-player 1999 original; both players share the keyboard.
- Click the applet to start play.

## Behavior audit

Bytecode audit (javap disassembly, 2026-08-28): no network references, no file
I/O, `getParameter` never called. Caches `getGraphics`/`createImage` in
`init()`. Never re-requests keyboard focus itself — the harness's
`windowActivated` re-grab exists for this game. Calls `Thread.stop()`, which
is why the runtime is pinned to a JRE <= 19 (Temurin 17 via the
`ari-flash-jre` cask).

## Icon

`icon.png` is ORIGINAL artwork generated headlessly at authoring time
(Java2D `BufferedImage` -> `ImageIO`, generator kept in the authoring
scratchpad): red and green slime half-discs facing off over a net under a
night sky with a grey ground band, in the visual style of the game. It
deliberately does NOT reuse slimegames.eu site art, which is copyright
A. Bartle 2007 UK.

## Licensing

- slimegames.eu footer (2011 Wayback captures, all game pages): "Website and
  artwork is copyright of A. Bartle 2007 UK. SlimeVolleyball and all its
  variations, unless stated, are copyright of Q. Pendragon 2007 AU."
- oneslime.net/kb/A_Brief_History_Of_Slime.html (live) records the original 1P
  slime volleyball appearing June 1999 (Clive Gout, UWA) and Quin Pendragon's
  Two Player Slime in Aug 1999; the entry for Jan 12 2001 reads "slime goes
  open-source" — Quin proclaimed it on his web page and told modders "the
  source is up there, do it yourself."
- No formal license text has ever been located; the games were distributed as
  free browser applets and copyright is explicitly retained by Q. Pendragon.

Redistribution here rests on that informal 2001 open-source statement — the
ship/no-ship call belongs to the user.
