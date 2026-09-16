# The host control plane: status.json, commands.txt and A2S

A Waygate host has no admin HTTP API and no RCON in this release. Three small, boring things
stand in for them, and the SurvivalServers panel drives all three from the box the server runs
on. Nothing here needs a key, a port or a login beyond being able to read the instance folder.

Everything lives in the instance's **waygate directory**: `<game>\waygate\` by default, or the
folder named by `--waygate-dir=<dir>` on the command line (the panel passes one per instance so
two servers on one machine never share a file).

## status.json

Rewritten every 5 seconds by the host, atomically (a complete temp file is swung into place), so a
reader never sees a half-written document.

```json
{
  "verdict": "HOSTING",
  "product": "Waygate 0.1.0",
  "game_version": "eDev 0.107.7689",
  "port": 15569,
  "query_port": 15570,
  "players": 1,
  "max_players": 8,
  "world": "Waygate",
  "server_name": "Waygate Lab",
  "uptime_seconds": 412,
  "written": "2026-09-15T18:41:02.1234567Z",
  "roster": ["Wanderer"]
}
```

| Field | Meaning |
|---|---|
| `verdict` | The boot report's verdict: `STARTING`, `HOSTING`, `WILL NOT HOST`, `WORLD DID NOT START` |
| `product` | Host mod name and version |
| `game_version` | The game's own version string |
| `port` / `query_port` | Gameplay UDP port and the A2S port (always `port + 1`) |
| `players` / `max_players` | Connected players (the hidden host character is never counted) and the slot cap |
| `world` / `server_name` | The world save being hosted and the name advertised over A2S |
| `uptime_seconds` | Seconds since the host reached `HOSTING` |
| `written` | UTC timestamp of this snapshot |
| `roster` | Display names of connected players, from the replicated player name |

`boot-report.txt` in the same folder is the human-readable version of `verdict` with a one-line
`detail:`; it is what a support person reads first.

## commands.txt

Drop a file named `commands.txt` into the waygate directory, one command per line. The host reads
and deletes it on its next tick (within a second) and logs each command it runs. Lines starting
with `#` are ignored.

| Command | Effect |
|---|---|
| `save` | Write the world save now |
| `shutdown` (alias `stop`) | Save, then exit the process cleanly |
| `restart` | Save, then exit; the supervisor that started the host is expected to start it again |
| `kick <name-or-clientId>` | Disconnect one player, matched by display name first, then by Netcode client id |
| `mapdump` | Write `mapdump.json` (every map asset with its bounds and scale, every landmark, map crystal and scene link) and the game's walkability grids as `mask-*.pgm` files into the waygate directory. A one-off used to draw base maps; it takes about two seconds |
| `tiledump` | `mapdump` plus the list of tilemaps the game holds (their cells are not readable in this build) |
| `mapfeed on` / `mapfeed off` | Force the map feed below on regardless of the `map-wanted` marker, or hand control back to the marker |

Because the file is consumed whole, write it in one go (write to a temp name and rename) rather
than appending lines to a file the host may already be reading.

A command file that is already there when the host boots is deleted unread and noted in the
log: it was written for a previous run, and a stale `shutdown` must never stop the server that
has just come up.

## map.json (the map feed) and map-wanted

The host can describe the live world for a map: every connected player with name, level, health,
area and position, the regions and Waygates each has discovered, players last seen offline, boss
fights in progress, temporary portals, map crystals with their collected state, and the Sanctum's
buildings, farm plots and player-built waygates.

It writes that to `map.json` in the waygate directory every `Map/FeedIntervalSeconds` (default 5)
**only while something is reading it**: touch a file named `map-wanted` in the same directory and
the feed runs until `Map/WantedSeconds` (default 45) pass without another touch. Nobody looking
costs one file-time check per tick and nothing is written. `Map/FeedEnable = false` turns the feed
off entirely. A `map.json` left over from a previous run is deleted at boot.

```json
{
  "written": "2026-09-16T18:00:18.6202100Z",
  "product": "Waygate 0.1.6",
  "game_version": "eDev 0.107.7689",
  "interval": 5,
  "server_name": "Compass Lab",
  "world": { "name": "CompassLab", "share_regions": false, "share_waygates": true, "explored": [] },
  "players": [
    { "name": "Compass One", "level": 1, "hp": 220, "hp_max": 220, "dead": false, "scene": "EarlwoodVillage",
      "x": -27.991, "y": -372, "sleeping": false, "teleporting": false, "spectating": false,
      "race": "1", "class": "4", "regions": [], "waygates": ["Dark Caverns"] }
  ],
  "offline": [], "bosses": [], "teleporters": [],
  "crystals": [ { "id": "LostCavernsWest", "collected": false } ],
  "buildings": [], "farm_plots": [], "base_waygates": []
}
```

| Field | Meaning |
|---|---|
| `world.explored` | Union of every player's discovered regions (the game's `MapFragmentName` values) plus the Sanctum's story-revealed regions |
| `world.share_regions` | The world's "share map fragment unlocks" setting; when false, each player's own `regions` list is the truth for them |
| `players[].scene` | The game's `Areas.Scene` name; `x`/`y` are plain world units (the map plane) |
| `players[].regions` / `waygates` | What that player has discovered, as the game reports it (effective, so shared unlocks are included) |
| `offline[]` | Players in the world save who are not connected: name, last scene and position, `last_played` as Unix seconds |
| `bosses[]` | Boss fights in progress: name, health, max health (the game gives no position) |
| `teleporters[]` | Temporary player portals: from scene/point, to scene/point, seconds remaining |
| `crystals[]` | Every map crystal in the world and whether it has been collected |
| `buildings[]` | Sanctum build items: type, position, rotation, owner's display name |

Positions are world coordinates. `mapdump.json` records how each in-game map projects them:
every map has `scale (4, 4)`, so a landmark's pixel on a map picture is
`((x - map_bottom_left.x) * 4, (map_top_right.y - y) * 4)` from the top-left corner.

## A2S (Source query) on port + 1

The host answers `A2S_INFO` and `A2S_PLAYER` (with the challenge handshake) on UDP `port + 1`.
This is what the Waygate app's Online badge, the panel's player count and any generic server
query tool speak. The extra-data flags carry the Steam app id (2402680) so tools that key on it
recognise the game. The responder runs on a background thread over a snapshot the game thread
refreshes, so it never touches game objects and a flood of queries cannot stall the world.

## What is deliberately not here

- No remote console: the game has no command surface to expose, and a fake one would be a
  liability. When the host grows an admin plane the launcher's Console tab comes back with it.
- No roster history: `status.json` and `map.json` are live snapshots, not logs. Keep your own history by
  sampling it.
