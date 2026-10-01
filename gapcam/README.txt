GAPCAM - suction mount 360 camera (free release)

REQUIRES: ox_lib
OPTIONAL: object_gizmo (https://github.com/DemiAutomatic/object_gizmo) for gizmo placement.
          Without it, placement falls back to keyboard (arrows, PgUp/PgDn, Q/E, Shift, Enter).

INSTALL
1. Put gapcam in your resources and add `ensure gapcam` (after ox_lib / object_gizmo / your inventory).
2. Add the item for your inventory (below). Item name: gapcam (change Config.Item in config.lua if you rename it).
3. Inventory is auto-detected. Set Config.Inventory in config.lua to force one:
   ox | qs | qbx | qb (qb/ps/lj-inventory) | esx | none (no item, /gapcam is free)

ITEM
ox_inventory (data/items.lua):
	['gapcam'] = {
		label = 'Gap Cam', weight = 1500, stack = false, close = true,
		description = 'Suction mounted 360 camera.',
		client = { event = 'gapcam:use' },
	},

qb-core / qbx_core (shared/items.lua):
	gapcam = { name = 'gapcam', label = 'Gap Cam', weight = 1500, type = 'item', image = 'gapcam.png', unique = true, useable = true, shouldClose = true, description = 'Suction mounted 360 camera.' },

qs-inventory (shared/items.lua):
	['gapcam'] = { name = 'gapcam', label = 'Gap Cam', weight = 1500, type = 'item', image = 'gapcam.png', unique = true, useable = true, shouldClose = true, description = 'Suction mounted 360 camera.' },

ESX: add a `gapcam` row to the `items` table (name 'gapcam', label 'Gap Cam', weight 1500).

USE
Use the item near / in a vehicle, place with the gizmo, confirm.
/gapcamview   look through the cam: mouse = look 360, scroll = zoom, R = reset, Enter = record (Rockstar Editor), Backspace = exit
/gapcamedit   reposition it
/gapcamremove remove it (item is returned)
/gapcam       same as using the item (free if Inventory = 'none')
Command names are configurable in config.lua.

NOTES
Model/spawn name: gapcam. One cam per player. The prop is networked so others see it; only you can view through it.
Prop: one static piece, origin between the suction feet, +Y = pole direction, no collision.
Not tested with every inventory - report issues.
