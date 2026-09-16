<p align="center">
  <img src="docs/img/waygate-lockup.png" alt="Waygate" width="420">
</p>

<p align="center">
  <a href="#requirements"><img src="https://img.shields.io/badge/Platform-Windows_10%2F11%2FServer-blue.svg" alt="Platform"></a>
  <a href="https://store.steampowered.com/app/2402680/"><img src="https://img.shields.io/badge/Game-Dimraeth-7b5cff.svg" alt="Game"></a>
  <a href="https://github.com/HumanGenome/Waygate"><img src="https://img.shields.io/badge/Player_App-Waygate-brightgreen.svg" alt="Player app"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License"></a>
</p>

# WaygateServer

The server half of [Waygate](https://github.com/HumanGenome/Waygate) — the piece that runs on a host machine and keeps a [Dimraeth](https://store.steampowered.com/app/2402680/) world online around the clock.

Players use the Waygate app; hosts use this. Start here if you are running the server, and at the [Waygate hub](https://github.com/HumanGenome/Waygate) if you are joining one.

## What it does

- Runs Dimraeth as a headless host — no graphics card, no desktop session, no logged-in Steam account
- Owns the world. The world is created and saved on the host, and it stays there when players leave
- Accepts direct connections on a normal UDP port, so players reach it by address instead of a Steam friend invite
- Hides its own host character: it takes no slot, is invisible to players and never gets in the way
- Answers Source server query on the port above the gameplay port, so server lists, monitoring and bots can read status and player count
- Takes a join password, if you set one
- Holds up to eight players, matching Dimraeth's own limit

## What it does not do

- **It does not ship Dimraeth.** You install the game files yourself; the server runs them from a folder you choose.
- **It does not replace the player's game.** Everyone joining still runs retail Dimraeth, with the Waygate app on top.
- **It is not an anti-cheat.** Waygate does not police what connected clients do.

## Requirements

| | |
|---|---|
| OS | Windows 10, Windows 11, or Windows Server |
| Game files | A Dimraeth installation on the host (about 6 GB) |
| Ports | Two UDP ports — the gameplay port, and the port immediately above it for server query |
| Hardware | No GPU required; plan on 4 to 8 GB of RAM per server (the game simulates the whole world even with nobody online) |

## Ports

Everything derives from one number, so you only ever choose the gameplay port.

| Port | Protocol | Used for |
|---|---|---|
| base (default `15569`) | UDP | Gameplay — the port players connect to |
| base + 1 (default `15570`) | UDP | Server query (Source A2S) |

Both must be open on the host firewall and forwarded if the server sits behind NAT.

## Setup

1. Put a copy of Dimraeth's game files on the host (install it through Steam on any PC and copy the game folder, or use SteamCMD with an account that owns the game).
2. Download `WaygateServer-<version>.zip` from the [latest release](https://github.com/HumanGenome/WaygateServer/releases/latest) and unzip it **over** the game folder, so `winhttp.dll` and `BepInEx\` sit beside `Dimraeth.exe`.
3. Edit `BepInEx\config\com.humangenome.waygate.host.cfg`: set the gameplay port, the server name, the world name and difficulty, and a join password if you want one.
4. Start the server from the game folder:

   ```
   Dimraeth.exe -batchmode -nographics
   ```

   The world is created on the first start. `waygate\boot-report.txt` says `HOSTING` once players can join, or exactly what stopped it if they cannot.
5. Hand players the address as `ip:port`. They add it in the Waygate app and press Connect.

Running two servers on one machine: give each its own copy of the game folder (a junction works) and its own port, and pass `--waygate-dir=<folder>` so their saves and status files never share a path.

## Running it from a panel or a script

`waygate\status.json` is rewritten every 5 seconds with the verdict, ports, player count, roster and uptime. Drop a `waygate\commands.txt` with `save`, `shutdown`, `restart` or `kick <name>` and the host runs it on its next tick. Details: [docs/status-and-commands.md](docs/status-and-commands.md).

## Managed hosting

If you would rather not run the machine, [SurvivalServers.com](https://www.survivalservers.com/services/game_servers/dimraeth/?utm_source=github&utm_medium=readme_install&utm_campaign=waygate) runs Dimraeth servers with Waygate already installed and the ports already open.

## Changelog

Every released version is listed in [CHANGELOG.md](CHANGELOG.md), split by what changed on the **Server** and what changed on the **Client**. Release pages quote the matching section verbatim.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Security issues go through [private reporting](.github/SECURITY.md), never a public issue.

## Community note

Waygate is an independent community project. It is not affiliated with, endorsed by, or supported by Mudtek.

## License

MIT — see [LICENSE](LICENSE).
