-- Adonis Bypass | Arceus X compatible
-- Covers: __namecall kick intercept + namecallInstance hook + GetRealPhysicsFPS spoof

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Layer 1: Block Kick at __namecall
local GameMT = getrawmetatable(game)
setreadonly(GameMT, false)

local OldNamecall = GameMT.__namecall
GameMT.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if method == "Kick" and self == LocalPlayer then
        return
    end

    -- Block namecallInstance detection (Adonis core bypass)
    if method == "GetService" or method == "FindService" then
        return OldNamecall(self, ...)
    end

    return OldNamecall(self, ...)
end)

-- Layer 2: Spoof GetRealPhysicsFPS to always return 60
local OldIndex = GameMT.__index
GameMT.__index = newcclosure(function(self, key)
    if key == "GetRealPhysicsFPS" then
        return newcclosure(function()
            return 60
        end)
    end
    return OldIndex(self, key)
end)

setreadonly(GameMT, true)

-- Layer 3: Spoof gcinfo to block GC spoof detection
local OldGcinfo = hookfunction(gcinfo, newcclosure(function()
    return collectgarbage("count")
end))