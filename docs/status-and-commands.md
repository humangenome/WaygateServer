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
  "steam_build": "25335390",
  "port": 15569,
  "query_port": 15570,
  "ports": { "game": 15569, "query": 15570, "rcon": 15572, "http": 15573, "web": 15574 },
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
| `steam_build` | The Steam build id of the game files this server started from, read once at start from `steamapps\appmanifest_2402680.acf` beside the game (or two folders up, in a Steam library). Empty when the folder has no manifest. See "Game builds" below |
| `port` / `query_port` | Gameplay UDP port and the A2S port the responder really has (usually `port + 1`) |
| `ports` | Where each listener really is: `game`, `query`, `rcon`, `http`, `web`; `0` = not listening. See "When a port is taken" below. Read these instead of assuming `port + n` |
| `players` / `max_players` | Connected players and the slot cap. The host has no character of its own, so nothing but real players is ever counted |
| `world` / `server_name` | The world save being hosted and the name advertised over A2S |
| `uptime_seconds` | Seconds since the host reached `HOSTING` |
| `written` | UTC timestamp of this snapshot |
| `roster` | Display names of connected players, from the replicated player name |

`boot-report.txt` in the same folder is the human-readable version of `verdict` with a one-line
`detail:`; it is what a support person reads first.

`last-shutdown.json` in the same folder is written by every `shutdown` and `restart`, right after
the save and before the game begins to close:

```json
{ "when": "2026-09-19T19:34:07.4456305Z", "why": "commands.txt", "restart": false, "world_saved": true }
```

A supervisor that stops the server reads it to learn whether the world was saved, instead of
searching a log.

## When a port is taken

Each listener has a usual port and two spare ones inside the server's own block of ten ports:

| Listener | Usual | Then |
|---|---|---|
| Server query (UDP) | `port + 1` | `port + 2`, `port + 6` |
| RCON (TCP) | `port + 3` | `port + 6`, `port + 8` |
| Admin API (TCP) | `port + 4` | `port + 7`, `port + 9` |
| Web page (TCP) | `port + 5` | `port + 8`, `port + 9` |

A port set in the config is tried first. When the usual port is held by another program, the
listener takes the next one, the host log and the console say which, and `status.json`
(`ports`), the query answer's keywords (`query=`, `rcon=`, `http=`, `web=`) and the admin API
report it. The Waygate app follows a moved server by itself. A listener that finds none of its
ports free says so and stays off; the server keeps running. If you firewall the block port by
port, allow the spare ports too.

Every listener is closed the moment the server is asked to shut down, before the game begins to
close, so a restart finds its usual ports free.

## Game builds: a player and a server must run the same one

A player and a server on different builds of Dimraeth cannot play together, and the game does
not say so: it approves the join and drops it a few seconds later, with no reason in either
log. Steam updates players the day a patch ships. A server only changes build when its game
files are updated and it is started again. So after every game patch, a server that has not
been updated turns every player away until it is.

From 0.3.11 this is said in words:

- The server publishes its build: `game_version` and `steam_build` in `status.json`, the same two
  in `/api/v1/health`, and `build=<steam build>` in the query answer's keywords (`build=0` when
  the folder has no Steam manifest). The A2S version field is the game's version string, as it
  has been since 0.1.2.
- The app compares that with the game installed on the player's PC before it starts the game,
  and stops with the side that has to move: "This server is on an older game version. Its owner
  needs to restart it." or "Your game is older than this server: update Dimraeth in Steam." The
  client mod makes the same comparison inside the game before it connects.
- The join ticket (v3) carries the player's build. A player on another build is refused at the
  join, and the console says so once a minute at most:
  `A player on game version eDev 0.107.7694 could not join: this server runs the older eDev 0.107.7689. Restart the server to update it.`
  With Discord alerts on, that line is a join alert.
- Two builds are the same when the game's version strings match; the Steam build ids decide only
  when a string is missing. A side that could not be read is never treated as different.

"Restart the server to update it" is true where the start script updates the game first. If
yours does not, update the game files (SteamCMD `app_update 2402680`) and then start the server.

Apps before 0.3.11 send ticket v1 or v2, which carry no build; they are admitted as before and
fall back to the game's own silent drop on a build difference. The app sends v3 only to a server
that advertises `build=`: an older server would read the extra lines as part of the password.

## mem-wanted and mem-log.txt (a diagnostic, off by default)

Create an empty file named `mem-wanted` in the waygate directory and the server appends what the `mem`
console command prints (process memory, the .NET runtime, the engine's allocations, the game's scripting
heap, object counts, the most common object names) to `mem-log.txt` beside it, every 30 minutes. Put a
number in the file to change the minutes (at least 5). The marker stops counting when it is older than
24 hours; delete it to stop sooner. `mem-log.txt` rolls over to `mem-log.1.txt` at 1 MB. Nothing is written
without the marker, and nothing about it appears in the console or in any log.

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
| `mem` (console only) | Where the server's memory is: process commit and working set, the .NET runtime, the engine's allocations, the game's scripting heap, object counts. Read-only |
| `kill <name-or-clientId>` | Kill one player the way lethal damage would (health to zero, the game's own death handling on every client); the player respawns from their own death screen. For a player stuck in geometry or a broken state |

Because the file is consumed whole, write it in one go (write to a temp name and rename) rather
than appending lines to a file the host may already be reading.

A command file that is already there when the host boots is deleted unread and noted in the
log: it was written for a previous run, and a stale `shutdown` must never stop the server that
has just come up.

## A2S (Source query) on port + 1

The host answers `A2S_INFO` and `A2S_PLAYER` (with the challenge handshake) on UDP `port + 1`
(or a spare query port, see "When a port is taken").
This is what the Waygate app's Online badge, the panel's player count and any generic server
query tool speak. The extra-data flags carry the Steam app id (2402680) so tools that key on it
recognise the game. The responder runs on a background thread over a snapshot the game thread
refreshes, so it never touches game objects and a flood of queries cannot stall the world.

## What is deliberately not here

- No remote console: the game has no command surface to expose, and a fake one would be a
  liability. When the host grows an admin plane the launcher's Console tab comes back with it.
- No roster history or map: `status.json` is a live snapshot, not a log. Keep your own history by
  sampling it.
