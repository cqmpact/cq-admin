# cq-admin
### Dear ImgUi inspired admin menu for FiveM
![License](https://img.shields.io/badge/License-MPL_2.0-blue.svg)

![QB-Core](https://img.shields.io/badge/QB--Core-No_Default_Support-red.svg)
![ESX](https://img.shields.io/badge/ESX-No_Default_Support-red.svg)

#### Features
- Player: heal, armor, revive, teleport to waypoint, noclip, god mode, invisibility, utility toggles
- Vehicles: spawn, fix/clean, delete/flip/warp, engine toggle, max performance, doors/windows, neon/colors, plate, visibility
- Weapons: give/remove/refill ammo, unlimited ammo/no reload, parachute options
- World: spawn/delete nearby objects
- Time & Weather: set/freeze time, set weather
- Misc: speedometer, coords, HUD/radar toggle, location/time text, night/thermal vision, camera locks, clear area
- Appearance: spawn/reset ped, presets
- Debug: developer tools (tied to `admin.debug`)

Note: exact items available depend on your configured ACE permissions (inside server.cfg or an external permissions .cfg file).

---

### Requirements & compatibility
- FiveM server (fxserver) with `fx_version 'cerulean'` support.
- Game: `gta5`.
- No framework dependency (works without ESX/QB-Core by default).

---

### Installation
1) Place the resource in your server resources folder, e.g.
```
resources/[YOUR-CODE-FOLDER]/cq-admin
```

2) Ensure the resource in your `server.cfg` (after any dependencies):
```
ensure cq-admin
```

3) Configure ACE permissions (see Quick ACE guide below). Without any admin permissions, the menu will not open.

4) Start or restart your server/resource.

---

### Usage
- Press F10 (key mapping for client command `admin`) to request opening the menu.
- Or use `/admin` in chat; both are client commands validated by the server, and the menu will only open if you have at least one admin permission.
- Toggle noclip with F2 (command `noclip`) if you have the `admin.player` permission; this is also server‑validated.
- The menu requests your capabilities from the server and only renders allowed categories.

---

### Commands & keybinds
- Open menu
  - Command: `admin`
  - Default keybind: F10
- Toggle noclip
  - Command: `noclip`
  - Default keybind: F2

Remap keys in your FiveM client: ESC → Settings → Key Bindings → FiveM → look for entries named `admin` and `noclip`.

---

### Configuration: enable/disable built‑in modules
You can choose which built‑in sections appear in the Admin Menu without touching permissions. This is useful if you want to hide certain categories entirely from the UI while still relying on ACE to control access.

- File: `shared/config.lua`
- This file is loaded on both client and server via `fxmanifest.lua` (`shared_scripts`).

Edit the `enabledModules` table to toggle visibility:

```
CQAdmin_Config.enabledModules = {
  player = true,
  weapons = true,
  vehicles = true,
  appearance = true,
  time_weather = true,
  misc = true,
  world = true,
  debug = true,
}
```

Notes:
- `true` = the category can appear if the user also has permission for it; `false` = the category is hidden from the menu.
- This does not grant or remove permissions; ACE still determines access.
- After editing, reload the resource (or restart the server) to apply the changes.

---

### UI controls at a glance
- Pin button: keeps the menu window pinned so it stays visible while switching focus.
- Mouse/free control button: toggles “free mouse/control.” When enabled, the game regains input and you can move while the menu stays visible; click it again to return mouse focus to the UI.
- Esc: closes the menu.

Tip: you can also toggle “Free mouse/control” from within the menu footer if available.

---

### Production options and tunables
To keep server consoles and player UIs quiet in production, the resource ships with conservative defaults and several options you can tune.

ConVars (server.cfg):

- `set cqadmin_versioncheck 1` — enable remote version check at resource start (default: 0/off). When off, no external request is made.
- `set cqadmin_debug 1` — enable verbose debug logs (default: 0/off). When on, additional diagnostic messages are printed server-side.
- Throttle/cooldown windows (milliseconds), optional — override defaults if you need to tune noise/spam resistance:
  - `set cqadmin_cap_req_window_ms 2000` — per-player throttle for capability requests (default: 2000)
  - `set cqadmin_deny_cooldown_ms 2000` — per-player cooldown between permission-denied toasts (default: 2000)
  - `set cqadmin_open_menu_window_ms 1000` — per-player throttle for opening the admin menu (default: 1000)
  - `set cqadmin_world_cooldown_ms 2000` — per-player cooldown for heavy world actions like deleteNearby (default: 2000)
  - `set cqadmin_misc_cooldown_ms 2000` — per-player cooldown for misc heavy actions like clearArea (default: 2000)
  - `set cqadmin_timewx_cooldown_ms 1000` — per-player cooldown for time/weather changes (default: 1000)
  - `set cqadmin_grant_handshake_window_ms 50` — per-player minimum spacing (ms) between grant handshake events (`sv:ack`/`sv:use`) to dampen abuse (default: 50)
  - Grant guardrails:
    - `set cqadmin_max_grants_per_src 32` — max outstanding grants allowed per player (default: 32)
    - `set cqadmin_max_grants_total 1024` — global cap for outstanding grants across all players (default: 1024)

Shared config (both client/server): `shared/config.lua`

- `CQAdmin_Config.quietNotifications` (default: `true`) — when enabled, the client suppresses non-critical informational toasts. Errors and success messages are still shown. This applies to both Lua-side notifications and informational messages returned by NUI callbacks.
- `CQAdmin_Config.enabledModules` — toggle visibility of built-in categories (does not change permissions).

Built-in rate limits and cooldowns:

- Capabilities throttle: the server rate-limits `cq-admin:sv:requestCapabilities` per player (default 2s window, convar `cqadmin_cap_req_window_ms`).
- Deny notification cooldown: repeated permission denials to the same player are only notified once per cooldown window (default 2s, convar `cqadmin_deny_cooldown_ms`).
- Menu open throttle: `cq-admin:sv:openMenuRequest` is throttled per player (default 1s, convar `cqadmin_open_menu_window_ms`).
- Heavy actions: `clearArea` and `deleteNearby` have per-player cooldowns (default 2s; convars `cqadmin_misc_cooldown_ms`, `cqadmin_world_cooldown_ms`).
- Grant guardrails: per-player and global outstanding grant caps prevent unbounded growth (convars `cqadmin_max_grants_per_src`, `cqadmin_max_grants_total`).

Input validation (server-side):

- Vehicle/object/ped model names are sanitized to a safe charset (`[A-Za-z0-9_.-]`) with a max length of 64; empty/invalid values are rejected.
- Weapon names must be `WEAPON_*` and match `^WEAPON_[A-Z0-9_]+$`.
- Numeric clamps: ammo (0..9999), armor (0..100), wanted level (0..5), deleteNearby radius (1..200).

Tip: If you want all informational toasts for debugging, set `quietNotifications = false` in `shared/config.lua` and enable `cqadmin_debug` temporarily in `server.cfg`.

---

### Resource structure
```
cq-admin/
  fxmanifest.lua
  shared/
    config.lua            # simple switches for which default modules show up in the menu
  html/                   # NUI (menu UI)
  client/
    utils.lua             # shared helpers (controls, drawText, loadModel, etc.)
    main.lua              # menu control, capability handling, grant validation
    default/*.lua         # built-in categories & callbacks
    gizmo.js              # helper
    custom/               # your custom client modules (empty, ignored by git)
  server/
    main.lua              # ACE groups map, grants, capability service, /admin
    default/*.lua         # built-in server handlers per category
    custom/               # your custom server modules (empty, ignored by git)
  .github/                # PR/issue templates and CI checks
```

Important: if you plan to use `client/custom` and `server/custom` for your own extensions, make sure they are loaded by `fxmanifest.lua`. See “Loading your custom folder” below.

---

### Loading your custom folder
By default, `fxmanifest.lua` includes the built‑in defaults. To load your custom modules in `client/custom/*.lua` and `server/custom/*.lua`, add these lines to `fxmanifest.lua`:

```
shared_scripts {
  'shared/config.lua'      -- loads module toggle config on both client and server
}

client_scripts {
  'client/utils.lua',      -- load helpers first
  'client/main.lua',
  'client/default/*.lua',
  'client/gizmo.js',
  'client/custom/*.lua'      -- add this
}

server_scripts {
  'server/main.lua',
  'server/default/*.lua',
  'server/custom/*.lua'      -- add this
}
```

This keeps your customizations separate from the `default` modules and out of version control by default.

---

### Client utilities (CQ.Util and CQ.Controls)
Reusable helpers live in `client/utils.lua` and are loaded before other client scripts. They improve readability and remove boilerplate. Highlights:

- Controls
  - `CQ.Controls` — named control IDs (e.g., `SPRINT`, `MOVE_LEFT_ONLY`, `SCROLL_UP`).
  - `CQ.NoclipDisableControls` — list of controls disabled during noclip.

- General utilities (namespace: `CQ.Util`)
  - `ped()` — shorthand for `PlayerPedId()`.
  - `clamp(value, min, max)` — clamp numbers safely.
  - `kmh(mps)` / `mph(mps)` — speed conversions from meters/second.
  - `drawText(x, y, text, opts)` — quick on‑screen text rendering with sensible defaults.
  - `getCamDir()` — unit vector of gameplay camera direction.
  - `getHeadingDirection(heading)` — "North/East/South/West" from a heading.
  - `getStreetAndZone(coords)` — resolve zone and street names.
  - `makeLocationText(coords, heading)` — friendly string: `Zone | Street1[/Street2] | Direction`.
  - `formatClock(hour, minute)` — returns `HH:MM`.
  - `loadModel(modelOrHash, timeoutMs)` — model loader with timeout; returns `(ok, hash)`.
  - `IB.show(buttons)` / `IB.hide()` — wrappers that emit the existing instructional‑buttons show/hide events handled by `client/main.lua`.
  - `disableControls(list)` — disables a set of controls for the current frame (call inside a frame loop).
  - `notify(type, message)` — safe notify wrapper (uses global `notify` if present, falls back to NUI).

Example: draw speed and show IB during a temporary mode
```
local C = CQ.Controls
local U = CQ.Util

CreateThread(function()
  local active = true
  U.IB.show({
    { control = GetControlInstructionalButton(0, C.MOVE_UP_ONLY, true), label = "Forward" },
    { control = GetControlInstructionalButton(0, C.SPRINT, true), label = "Boost" },
  })
  while active do
    Wait(0)
    local speed = U.kmh(GetEntitySpeed(U.ped()))
    U.drawText(0.85, 0.92, ("%.1f KM/H"):format(speed), { scale = 0.5 })
    -- Disable some inputs while active
    U.disableControls({ C.ATTACK, C.AIM, C.RELOAD })
    -- stop after some condition...
  end
  U.IB.hide()
end)
```

These helpers are used throughout the built‑in modules (e.g., noclip, appearance model loading, misc overlays) and are available for your custom modules too.

---

### Adding your own commands (custom modules)
The admin menu is modular. You can register new categories and items on the client, and implement secured handlers on the server. The built‑ins are good examples; here’s a minimal template.

Step 1 — Client: define a category and callbacks
Create `client/custom/my_feature.lua`:
```
-- Register a new category for the menu
RegisterAdminCategory('myfeature', {
  build = function()
    return {
      id = 'my_feature',
      label = 'My Feature',
      sub = 'Custom actions demo',
      enabled = true,
      groups = {
        {
          id = 'tools', type = 'group', label = 'Tools',
          children = {
            { label = 'Do Something', type = 'button', buttonLabel = 'Go', callback = 'cq-admin:cb:doSomething' },
            { label = 'Toggle Thing', type = 'toggle', key = 'my_toggle', default = false, callback = 'cq-admin:cb:toggleThing' },
            { label = 'Set Number', type = 'inputButton', placeholder = '123', buttonLabel = 'Set', payloadKey = 'amount', callback = 'cq-admin:cb:setNumber' },
          }
        }
      }
    }
  end
})

-- NUI callbacks (UI -> server)
RegisterNUICallback('cq-admin:cb:doSomething', function(_, cb)
  TriggerServerEvent('cq-admin:sv:doSomething')
  cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:toggleThing', function(data, cb)
  local enabled = data and data.value and true or false
  TriggerServerEvent('cq-admin:sv:toggleThing', enabled)
  cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:setNumber', function(data, cb)
  local amount = data and data.amount
  TriggerServerEvent('cq-admin:sv:setNumber', amount)
  cb({ ok = true })
end)

-- Secured client-side actions (server -> client, gated by a short-lived grant)
RegisterNetEvent('cq-admin:cl:doSomething', function(reqId)
  if not _validateGrant(reqId) then return end  -- mandatory security check
  -- Perform the action on the client here
end)
```

Step 2 — Server: permissions, handlers, and grants
Create `server/custom/my_feature.lua`:
```
-- Map your actions to ACE strings (reuse existing ones or define your own)
-- You can extend the global GROUPS from any server file:
GROUPS.doSomething = 'admin.misc'         -- or 'admin.myfeature'
GROUPS.toggleThing = 'admin.misc'
GROUPS.setNumber  = 'admin.misc'

-- Handlers called from the client (NUI callbacks trigger these)
RegisterNetEvent('cq-admin:sv:doSomething', function()
  local src = source
  local group = GROUPS.doSomething
  if not hasGroup(src, group) then return deny(src, 'doSomething', group) end
  -- Authorize the client-side effect via a grant
  issueGrant(src, 'doSomething', 'cq-admin:cl:doSomething')
end)

RegisterNetEvent('cq-admin:sv:toggleThing', function(enabled)
  local src = source
  local group = GROUPS.toggleThing
  if not hasGroup(src, group) then return deny(src, 'toggleThing', group) end
  issueGrant(src, 'toggleThing', 'cq-admin:cl:toggleThing', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:setNumber', function(amount)
  local src = source
  local group = GROUPS.setNumber
  if not hasGroup(src, group) then return deny(src, 'setNumber', group) end
  amount = tonumber(amount) or 0
  issueGrant(src, 'setNumber', 'cq-admin:cl:setNumber', amount)
end)
```

Why the grant round‑trip?
- The server issues a short‑lived one‑time token via `issueGrant(...)`.
- The client receives it, calls back with `cq-admin:sv:use`, and only then the action becomes valid in the client with `_validateGrant(reqId)`.
- This prevents spoofing client events and ensures the server authorizes each action.

Naming conventions used by built‑ins:
- NUI callbacks: `cq-admin:cb:<name>` (client side, UI → server trigger)
- Server events: `cq-admin:sv:<name>` (server handlers with ACE check)
- Client events: `cq-admin:cl:<name>` (client effect, must call `_validateGrant` first)

Step 3 — ACE permissions for your actions
- Reuse an existing ACE like `admin.misc`, or create your own e.g. `admin.myfeature` and grant it in `server.cfg`.

---

### Quick ACE permissions guide
cq-admin uses FiveM ACE to decide what each player can see/do. Each logical section maps to an ACE string. Grant them to individuals or groups.

Core ACE strings used by this resource:
- `admin.player`
- `admin.vehicles`
- `admin.weapons`
- `admin.world`
- `admin.time_weather`
- `admin.misc`
- `admin.appearance`
- `admin.debug`

Give everything to a specific player (replace the ID):
```
# Use the player's FiveM identifier (see server console when they connect)
add_ace identifier.fivem:1234567 admin.player allow
add_ace identifier.fivem:1234567 admin.vehicles allow
add_ace identifier.fivem:1234567 admin.weapons allow
add_ace identifier.fivem:1234567 admin.world allow
add_ace identifier.fivem:1234567 admin.time_weather allow
add_ace identifier.fivem:1234567 admin.misc allow
add_ace identifier.fivem:1234567 admin.appearance allow
add_ace identifier.fivem:1234567 admin.debug allow
```

Recommended: create an admin group, grant ACEs to the group, then assign players to it:
```
# server.cfg

# 1) Grant permissions to the group
add_ace group.cq.admin admin.player allow
add_ace group.cq.admin admin.vehicles allow
add_ace group.cq.admin admin.weapons allow
add_ace group.cq.admin admin.world allow
add_ace group.cq.admin admin.time_weather allow
add_ace group.cq.admin admin.misc allow
add_ace group.cq.admin admin.appearance allow
add_ace group.cq.admin admin.debug allow

# 2) Assign players to the admin group (FiveM identifier)
add_principal identifier.fivem:1234567 group.cq.admin
add_principal identifier.fivem:7654321 group.cq.admin
```

Notes
- The built‑in ACE `admin` is printed to logs but not used for gating capabilities; grant the specific `admin.*` entries above.
- You can create finer groups (e.g., moderators with only `admin.player` + `admin.misc`).
- After changing ACE entries, restart the server or at least `refresh` and `restart cq-admin`.

How capabilities are used
- When you open the menu, the client asks the server for capabilities.
- The server replies with booleans for each category based on `IsPlayerAceAllowed(...)` for the ACE strings.
- Only allowed categories are rendered.

---

### Contributing
For full guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).
Please follow these guidelines:

- Conventional Commits for PR titles (e.g., `feat: add vehicle neon color picker`).
- Use the provided PR template and checklists.
- Keep custom features in `client/custom` and `server/custom` when possible.
- Match the code style and patterns used in existing modules.

Useful links in this repo:
- `.github/pull_request_template.md` — required PR template
- `.github/ISSUE_TEMPLATE/bug_report.md` — file an actionable bug report
- `.github/ISSUE_TEMPLATE/feature_request.md` — propose a feature
- `.github/workflows/pr-checks.yml` — CI checks for PRs

Local testing checklist (suggested):
- Start a local FiveM server with `ensure cq-admin`.
- Verify there are no console errors on start.
- Grant yourself temporary ACEs and test each affected section.
- Confirm `/admin` and the keybinding open the menu.

---

### FAQ
Q: I open the menu but see “You do not have access to any admin sections”.
A: Your ACE permissions are missing. Add the relevant `add_ace` lines and try again.

Q: My custom files in `custom/` aren’t loading.
A: Add the `client/custom/*.lua` and `server/custom/*.lua` globs to `fxmanifest.lua` as shown above, then restart the resource.

Q: Can I map the open key to something else?
A: Yes. It uses FiveM’s key mapping: `RegisterKeyMapping('admin', 'Open Admin Menu', 'keyboard', 'F10')`. You can change the binding in your client settings.

---

### Security / contact
- Security reports: **matt@cqmpact.dev**

---

## License (MPL 2.0)

This project is licensed under the **Mozilla Public License 2.0 (MPL-2.0)**.

- A copy of the license is included in this repository as `LICENSE`.
- If you modify files covered by MPL-2.0 and distribute your version, you must make the source of those modified MPL-2.0 files available under MPL-2.0.
- New, separate files you create may be licensed however you choose, as long as you comply with MPL-2.0 for any MPL-licensed files you change.

SPDX identifier: `MPL-2.0`
