# Changelog

All notable changes to Waygate are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Waygate uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Each version is split into **Server** (WaygateServer and the host mod) and
**Client** (the Waygate app and the client mod). A release publishes the
section for its own version verbatim as the release body, so a version with no
section here cannot be released.

## [Unreleased]

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
