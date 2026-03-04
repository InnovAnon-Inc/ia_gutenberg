-- ia_gutenberg/init.lua

assert(minetest.get_modpath('ia_util'))
assert(ia_util ~= nil)
local modname                    = minetest.get_current_modname() or "ia_gutenberg"
local storage                    = minetest.get_mod_storage()
ia_gutenberg                       = {

}
local modpath, S                 = ia_util.loadmod(modname)
local log                        = ia_util.get_logger(modname)
local assert                     = ia_util.get_assert(modname)

