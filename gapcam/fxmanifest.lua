fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JB Development'
description 'Suction mounted gap camera prop with 360 live view'
version '1.2.0'

dependency 'ox_lib'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_script 'client.lua'
server_script 'server.lua'

files { 'stream/gapcam.ytyp' }
data_file 'DLC_ITYP_REQUEST' 'stream/gapcam.ytyp'
