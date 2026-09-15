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

Because the file is consumed whole, write it in one go (write to a temp name and rename) rather
than appending lines to a file the host may already be reading.

## A2S (Source query) on port + 1

The host answers `A2S_INFO` and `A2S_PLAYER` (with the challenge handshake) on UDP `port + 1`.
This is what the Waygate app's Online badge, the panel's player count and any generic server
query tool speak. The extra-data flags carry the Steam app id (2402680) so tools that key on it
recognise the game. The responder runs on a background thread over a snapshot the game thread
refreshes, so it never touches game objects and a flood of queries cannot stall the world.

## What is deliberately not here

- No remote console: the game has no command surface to expose, and a fake one would be a
  liability. When the host grows an admin plane the launcher's Console tab comes back with it.
- No roster history or map: `status.json` is a live snapshot, not a log. Keep your own history by
  sampling it.
