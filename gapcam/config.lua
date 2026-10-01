Config = {}

Config.Inventory = 'auto' -- 'auto' | 'ox' (ox_inventory) | 'qs' (qs-inventory) | 'qbx' (Qbox core inventory) | 'qb' (qb-core: qb/ps/lj-inventory) | 'esx' | 'none' (no item, /gapcam is free to use)

Config.Item = 'gapcam'

Config.Commands = {
    place = 'gapcam',
    view = 'gapcamview',
    edit = 'gapcamedit',
    remove = 'gapcamremove',
}

Config.lensOffset = vec3(0.0, 1.0, 0.62)
Config.fov = { default = 80.0, min = 25.0, max = 120.0, step = 4.0 }
Config.lookSpeed = 6.0
Config.maxDistance = 150.0
Config.exitKey = 177
Config.placeDistance = 6.0
