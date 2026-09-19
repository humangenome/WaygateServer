# The server's web page

Every Waygate server serves a page about itself on **game port + 5** (`15574` for a server on the default `15569`). It runs inside the host process and needs nothing installed: open `http://<server ip>:<game port + 5>/` in a browser.

<p align="center">
  <img src="img/web-map.png" alt="The map tab: Earlwood with a player's live position" width="860">
</p>

## What is on it

| Tab | Who sees it | What it shows |
|---|---|---|
| Map | anyone with the address | The world from the game's own pixels, one tab per area (Earlwood, Lost Caverns, Sanctum, Goblin Caves), with every connected player's live position and name (refreshed every five seconds), the Waygates and map crystals they have found, boss fights, temporary portals and the Sanctum's buildings. The layers button hides or shows each kind of marker and switches the fog of war on. |
| Console | the owner | The server's live log (joins, leaves, chat, deaths, saves, admin actions, the game's own warnings) and a command line. The quick actions run the common commands; `help` lists them all. |
| Players | anyone; controls for the owner | Everyone connected, with level, area and time on. The owner can remove or block a player and manage the block list. |
| Alerts | the owner | Discord messages the server posts itself: joins and leaves, deaths, the server filling up, the world coming up, a scheduled stop, and an optional round-up. |

The rail on the right lists who is playing on every tab; on a phone it is a sheet at the bottom.

<p align="center">
  <img src="img/web-console.png" alt="The console tab, unlocked: the live log, a command and its answer, the quick actions" width="860">
</p>

<p align="center">
  <img src="img/web-players.png" alt="The players tab with the block list" width="860">
</p>

## The map, close up

The map is the world as the game itself draws it: a capture of the loaded world through the game's own renderer, one screen pixel per sprite pixel, cut into tiles. The package carries it at up to 8 pixels per world unit. Zooming in stops at 16 screen pixels per unit, the game's own closest zoom, where those pixels are doubled cleanly; a picture at exactly its own size is drawn pixel for pixel, and zooming out uses pre-scaled copies, so nothing is stretched or blurred at any level. The layers button hides and shows each kind of marker, and switches the fog of war: the game's own fog over ground no player has discovered yet, off unless `FogOfWar = world` is set (below); the switch works once the page is unlocked.

<p align="center">
  <img src="img/web-map-zoom.png" alt="Earlwood Village at the game's full zoom" width="860">
</p>

## The fog of war

The game hides a region on its own map until a player has set foot in it, one cut-out per region. The page can do the same: switch **Fog of war** on in the layers menu and every region nobody has discovered yet goes under the game's own fog, with its markers and name held back. The menu also picks whose discoveries count, anyone's or one named player's. It is off by default for the owner, and `FogOfWar = world` under `[Web]` makes it the page's starting state for everyone; the layers menu can still switch it once unlocked.

<p align="center">
  <img src="img/web-fog.png" alt="The fog of war on: the village a player has discovered is drawn, the rest of Earlwood is under the game's fog, and the layers menu lists whose discoveries count" width="860">
</p>

## The live layers

Beside the landmarks, the map draws what the world is doing: quests where their current step takes place, each boss's lair and how it fares, loot chests shut or opened with their refill clock and the players' storage, the named people and the village's works, and a World progress line that unfolds. `PublicLayers` under `[Web]` names which of those someone who has not unlocked the page sees (quests, bosses, people and progress unless you change it; `all` or `none` work too); a player's own quests are never shown to visitors. Unlocked with the password, the page shows every layer.

## The password

The owner's parts unlock with the admin password: `Password` under `[Admin]` in `BepInEx\config\com.humangenome.waygate.admin.cfg`. It is the same password RCON and the Waygate app's Console tab use. Typed once, it stays in that browser (nowhere else) and signs every owner action the same way the app does; it is never sent as text. With no password set, the map and the player list still work and the owner parts say so.

## Sharing the address

Anyone who can reach the port sees the map, with player names and positions. To keep the map for the owner too, set `PublicMap = false` under `[Web]`; the page then asks for the password before drawing it. To switch the page off entirely, set `Enable = false` under `[Web]`.

Behind NAT, forward TCP `game port + 5` like the two UDP ports. The page is plain HTTP; put it behind your own reverse proxy if you want a name and a certificate.

## Settings

`BepInEx\config\com.humangenome.waygate.admin.cfg`:

```ini
[Web]
Enable = true        # serve the page
Port = 0             # 0 = game port + 5
PublicMap = true     # false = the map needs the password too
FogOfWar = off       # world = the page starts with every region no player has discovered yet under the game's own fog
PublicLayers = quests,bosses,people,progress   # the live layers someone who has not unlocked the page sees; all, or none. Unlocked, the page shows every layer
WebRoot =            # optional folder overriding the page files, for editing the page

[Alerts]
DiscordWebhook =     # set from the Alerts tab or here
OnJoinLeave = true
OnDeath = true
OnFull = true
OnStartStop = true
RoundupHours = 0     # 0 = never
```

The layers themselves come from the host mod, and `[Map] Layers = false` in its config (`waygate.cfg`) switches them off for the page and the map feed alike.

## Where the pictures come from

The map is drawn by the game: the loaded world rendered through the game's own camera at noon, with monsters, weather and screen effects off, placed by the area rectangles the running game reports, tiled for the browser and shipped in the release beside the plugin (`BepInEx\plugins\WaygateAdmin\www\maps`). Live positions come from the host's own memory every five seconds while a page is open, and nothing is written to disk for it.

## What it is not

The page cannot tell you the server is down: a message the server sends cannot arrive once the server is gone. It is not an anti-cheat and it does not edit the world. Start, stop and restart are `shutdown` and `restart` in the console, with a countdown players see in chat.
