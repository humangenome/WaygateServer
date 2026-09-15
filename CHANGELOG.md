# Changelog

All notable changes to Waygate are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Waygate uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Each version is split into **Server** (WaygateServer and the host mod) and
**Client** (the Waygate app and the client mod). A release publishes the
section for its own version verbatim as the release body, so a version with no
section here cannot be released.

## [Unreleased]

## [0.1.0] - 2026-09-15

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
