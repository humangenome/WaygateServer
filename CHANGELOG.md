# Changelog

All notable changes to Waygate are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Waygate uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Each version is split into **Server** (WaygateServer and the host mod) and
**Client** (the Waygate app and the client mod). A release publishes the
section for its own version verbatim as the release body, so a version with no
section here cannot be released.

## [Unreleased]

## [0.2.2] - 2026-09-16

### Server

No change; the package is rebuilt so both halves carry the same version.

### Client

#### Added

- The game's version in the bottom-right corner now carries the Waygate version beside it.

#### Fixed

- The Console tab is in the top bar. 0.2.1 built it but did not show it.
- The Mods tab says once, not twice, that a server needs no client mods.

## [0.2.1] - 2026-09-16

### Server

#### Added

- `kill <player>` in `commands.txt` and the admin console, for a player stuck in geometry or a broken state.

#### Changed

- The server no longer has a character of its own. Nothing is spawned for it: it takes no seat, is in no party or player list, keeps no area awake and is not written to the world save. The world is loaded by the server itself at start; a first start takes about the same time as before. Setting `Host/HostCharacter = true` restores the previous placeholder character.
- The customer console no longer shows the host's internal file and protocol names, nor the game's video-shader warnings printed on every start.

#### Fixed

- Sleeping works. When every connected player is in a bed the night passes. Before this release the server counted itself as an awake player and the night never came.

### Client

No change; the package is rebuilt so both halves carry the same version.

## [0.2.0] - 2026-09-16

### Server

#### Added

- Admin plane: Source RCON on game port + 3 and a signed HTTP API on game port + 4 (`WaygateAdmin.dll`, new). One password for both, set in `BepInEx/config/com.humangenome.waygate.admin.cfg`; empty keeps both listeners off.
- Bans and an allow list keyed on the player's character, with the connecting address as a backstop. `bans.json` and `allowlist.json` live beside `status.json` and survive restarts.
- Console: joins, leaves, chat, deaths, saves and admin actions, 2,000 lines in memory, served by `/api/v1/console/recent` and streamed by `/api/v1/console/stream`.
- Commands: players, kick, ban, unban, bans, allow, deny, allowlist, say, announce, motd, save, time, weather, heal, revive, respawn, kill, give, god, tp, spawn, quests, quest reset, respawnmonsters, lock, chat, shutdown, restart, cancel.
- Mods. The host loads BepInEx plugins from `BepInEx\plugins\mods\<id>\` when the folder carries a `waygate-mod.json` (id, version, side, the plugin's sha256). `status.json` lists every mod and whether it loaded. A2S_RULES on port + 1 lists the client-side mods a server requires, and a client that does not carry that exact set is refused with the reason. Two server mods are published: Server Multipliers and Message of the Day.
- A map feed. While a reader touches `map-wanted` in the waygate directory, the host writes `map.json` every five seconds: every connected player with name, level, health, area and position, the regions and waystones each has found, players last seen, boss fights, temporary portals, map crystals, and the Sanctum's buildings. Nobody reading, nothing written; `status.json` carries `map_feed: true` when the feed exists. New commands: `mapdump` writes the map assets, landmarks and walkability grids the base maps are drawn from; `mapfeed on|off` forces the feed.

#### Fixed

- `commands.txt` is taken by rename before it is read, so a line written between the read and the delete is never lost.

### Client

#### Added

- The Console tab is shown. It uses the selected server's admin port, asks for the admin password once per server, and reads long replies whole.
- Mods. When a server requires client mods, Waygate installs them from the Waygate mod registry before the game starts: each release is checked against the registry's signature and two hashes, installed into a folder for that server only, and you are asked once per server. The Mods tab shows what a server requires and what is installed for it. A plain Steam launch never loads them. A mod withdrawn from the registry is removed on the next start.

## [0.1.7] - 2026-09-16

### Server

#### Fixed

- The host reads the world file's save version before the game's loader does. A world written by
  another game build is left untouched and the server refuses to start, with the reason in
  `boot-report.txt` and `status.json`, instead of the game moving the world to Recovery and starting
  a fresh one.
- The game's own quit path is refused on a host. The game reaches it when a connected player's XP
  state fails validation; on a headless server that was the process ending.

#### Changed

- `status.json` carries `detail`, `save_failure`, `world_file_version` and `game_world_file_version`,
  and is written on a failed start too.
- The server zip no longer ships the generated interop assemblies. BepInEx builds them from the game
  files on the first boot, about a minute longer once, and keeps them. The Unity base libraries ship
  in the zip, so no download is needed.

### Client

No change; the package is rebuilt so both halves carry the same version.

## [0.1.6] - 2026-09-16

### Server

#### Fixed

- The join password is now checked. A server with a password admitted any client that reached it:
  the game only ever compared the password inside its Steam lobby, which Waygate does not use. The
  app now sends the password with the connection and the server refuses a wrong or missing one with
  "Wrong password."

### Client

#### Fixed

- The app presents the server's password on connect. A refused join reports the server's reason in
  the connection status instead of waiting for the timeout.

An app that has not updated yet cannot join a passworded server until it updates itself on its next
start. Servers without a password are not affected.

## [0.1.5] - 2026-09-15

### Server

#### Fixed

- The server's placeholder character no longer takes a player seat. A 4-slot server admitted 3
  players; every slot is a player's now.
- Players are no longer put into the placeholder character's party. The first player to join
  leads the party (named after the server), everyone after joins them, and when the leader logs
  off the game hands the party to the next member. The placeholder character is in no party at all.
- The player count in the status file stayed one low after a refused join. Fixed.

### Client

No change; the package is rebuilt so both halves carry the same version.

## [0.1.4] - 2026-09-15

### Server

#### Added

- `World/LockBuildingsToOwner`: Lock Buildings to Owner, written to the world on every start
  like the other world settings.
- `World/EnableChat`: set it to `false` and the server drops player chat (typed lines and
  direct messages) before it is relayed. Server and quest lines still show.

#### Changed

- The server's own placeholder character no longer appears in anyone's Social tab, neither in
  the server list nor in the party list.
- The party every player lands in is named after the server (`Host/ServerName`) instead of
  "Server's Party".

### Client

#### Changed

- Starting Dimraeth from Steam after a Waygate session opens the plain game again. The join the
  launcher set up is used once; it no longer replays on every launch, so Steam lobbies with
  friends work exactly as before.
- While connected through Waygate, Multiplayer Settings shows Lobby Type: Public instead of
  Friends Only.

## [0.1.3] - 2026-09-15

### Client

#### Added

- A game folder that is not a Steam library install (a copied folder, or a folder chosen in
  Settings) is started directly instead of through Steam, so Connect works on a PC where Steam
  does not list the game.

### Server

No change; the package is rebuilt so both halves carry the same version.

## [0.1.2] - 2026-09-15

The first release, out on Dimraeth's Early Access launch day.

### Server

#### Added

- A Dimraeth server that runs on its own: it creates a world, keeps it saved,
  and reloads the same world on the next start. No player has to be online for
  the world to exist.
- Runs without a graphics card, a monitor, a desktop session, or a signed-in
  Steam account.
- Players connect by address on a configurable UDP port, up to Dimraeth's usual
  eight.
- The host's own character is hidden: invisible to players and never counted
  against the slots.
- World name, difficulty, friendly fire, personal loot, new-characters-only and
  a join password, all from one config file.
- Source A2S query on the port above the gameplay port, with real player counts
  and names.
- A status file rewritten every few seconds and a command file for save,
  shutdown, restart and kick, so a panel or a script can run the server without
  a console.
- A boot report that says why the server refused to start, instead of starting
  broken.
- Lower frame rate while the server is empty, so an idle server costs little.

### Client

#### Added

- The Waygate app for Windows: saved servers with live status, ping and who is
  online, and a Connect button that readies Dimraeth and joins.
- `waygate://add` and `waygate://connect` links.
- Password prompt for locked servers, remembered per server.
- Starts the game through Steam, or straight from the game folder when Steam is
  not signed in.
- Self-update on the next start.

---

Hosting: [SurvivalServers.com](https://www.survivalservers.com/services/game_servers/dimraeth/?utm_source=github&utm_medium=release_notes&utm_campaign=waygate) runs Waygate for you.
