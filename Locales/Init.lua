local addonName, addon = ...

addon.L = addon.L or {}
local L = addon.L

setmetatable(L, {
    __index = function(_, key)
        return key
    end,
})
